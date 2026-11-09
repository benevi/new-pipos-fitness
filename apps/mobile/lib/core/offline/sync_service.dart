/// Sync Service (ADR-0007, offline-first)
///
/// Todo lo que el usuario registra en la sesión pasa por aquí:
///
/// 1. La UI llama a [SyncService.startWorkout], [SyncService.logSet] y
///    [SyncService.finishWorkout]. Cada llamada escribe primero en drift (con
///    un `clientId` UUID v4) y la UI se pinta desde drift ([watchSets]): sin
///    red no se pierde nada y sobrevive al cierre de la app.
/// 2. [SyncService.syncNow] hace, si hay red, una pasada EN ORDEN:
///    a. `POST /workouts` de los entrenamientos sin `serverId` (idempotente
///       por `clientId`: 201 la primera vez, 200 al reenviar).
///    b. `POST /workouts/:id/sets` de las series `pending` (orden
///       `completedAt`, `setIndex`; idempotente por `clientId`).
///    c. `POST /workouts/:id/finish` de los terminados sin series por
///       confirmar (ni pendientes ni `failed`), con el mismo backoff.
///    - 2xx → `synced`.
///    - Error transitorio (sin red, timeout, 5xx, 401, 408, 429) → sigue
///      `pending`, `attempts++`, `nextAttemptAt` con backoff exponencial; se
///      detiene la pasada (para no desordenar) y se programa un reintento.
///    - Error permanente (4xx) o reintentos agotados → `failed` (no bloquea
///      al resto). [retryFailed] los vuelve a poner en cola.
/// 3. Al volver la conectividad se lanza otra pasada.
/// 4. Al arrancar, las series `syncing` huérfanas (la app murió a mitad de
///    envío) vuelven a `pending`: como el envío es idempotente, reenviarlas
///    es seguro (la API responde 200 con la fila existente).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../../data/pipos_api.dart';
import '../../models/enums.dart';
import '../../models/workout.dart';
import '../api/api_failure.dart';
import 'app_database.dart';
import 'connectivity.dart';

class BackoffPolicy {
  const BackoffPolicy({
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    this.maxAttempts = 8,
  });

  final Duration baseDelay;
  final Duration maxDelay;

  /// Tras este número de intentos fallidos el elemento pasa a `failed`.
  final int maxAttempts;

  /// Espera tras el intento fallido número [attempts] (1, 2, 3...):
  /// `base * 2^(attempts-1)`, acotado a [maxDelay].
  Duration delayFor(int attempts) {
    final exponent = math.max(0, attempts - 1);
    final micros = baseDelay.inMicroseconds * math.pow(2, exponent);
    return Duration(
      microseconds: math
          .min(micros, maxDelay.inMicroseconds.toDouble())
          .round(),
    );
  }
}

class SyncReport {
  const SyncReport({
    this.sent = 0,
    this.failed = 0,
    this.deferred = 0,
    this.offline = false,
  });

  final int sent;
  final int failed;

  /// Elementos que quedan pendientes para un reintento posterior.
  final int deferred;
  final bool offline;
}

/// Resumen del estado de la cola para la UI.
class SyncSummary {
  const SyncSummary({this.pending = 0, this.failed = 0});

  final int pending;
  final int failed;

  bool get isClean => pending == 0 && failed == 0;
}

class SyncService {
  SyncService({
    required AppDatabase database,
    required WorkoutApi api,
    required ConnectivitySource connectivity,
    required String? userId,
    DateTime Function()? clock,
    String Function()? idGenerator,
    this.backoff = const BackoffPolicy(),
    this.retention = const Duration(days: 14),
    void Function(Object error, StackTrace stack)? onError,
  }) : _onError = onError ?? _logError,
       _db = database,
       _api = api,
       _connectivity = connectivity,
       _userId = userId,
       _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? const Uuid().v4;

  final void Function(Object error, StackTrace stack) _onError;
  final AppDatabase _db;
  final WorkoutApi _api;
  final ConnectivitySource _connectivity;
  final String? _userId;
  final DateTime Function() _clock;
  final String Function() _newId;
  final BackoffPolicy backoff;

  /// Series ya sincronizadas y entrenamientos cerrados se purgan pasado
  /// este tiempo.
  final Duration retention;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _retryTimer;
  Future<SyncReport>? _running;
  bool _runAgain = false;
  bool _disposed = false;

  $LocalSetLogsTable get _sets => _db.localSetLogs;
  $LocalWorkoutsTable get _workouts => _db.localWorkouts;

  String get _uid {
    final id = _userId;
    if (id == null) throw StateError('Sin usuario no hay cola offline.');
    return id;
  }

  /// Recupera envíos interrumpidos, purga lo antiguo, escucha la
  /// conectividad y lanza una primera pasada.
  Future<void> start() async {
    if (_userId == null || _disposed) return;
    await recoverInterrupted();
    await _purgeOld();
    _connectivitySub ??= _connectivity.onlineChanges.listen((online) {
      if (online) _kick();
    });
    _kick();
  }

  /// Lanza una pasada sin esperarla, capturando cualquier error (BD
  /// cerrada, plugin de conectividad...) para que no acabe como error no
  /// manejado de la zona.
  void _kick() {
    unawaited(
      syncNow().then<void>(
        (_) {},
        onError: (Object e, StackTrace st) {
          if (!_disposed) _onError(e, st);
        },
      ),
    );
  }

  static void _logError(Object error, StackTrace stack) {
    debugPrint('SyncService: pasada fallida: $error\n$stack');
  }

  // ── Escrituras locales (la UI) ──

  /// Entrenamiento local para [planSessionId]. Si ya hay uno abierto para esa
  /// sesión se reutiliza; si la API ya tiene uno en curso ([adopt]), se
  /// registra con su `clientId` y su id (o se enlaza el local abierto que
  /// aún no tenía id de la API).
  ///
  /// Las llamadas se serializan (mutex) y la comprobación + inserción va en
  /// una transacción: dos confirmaciones casi simultáneas en ejercicios
  /// distintos no crean dos entrenamientos.
  Future<LocalWorkout> startWorkout({
    required String planSessionId,
    TodayWorkoutRef? adopt,
  }) async {
    final userId = _uid;
    final row = await _serialized(
      () => _db.transaction(
        () => adopt != null
            ? _adoptTx(userId, planSessionId, adopt)
            : _startTx(userId, planSessionId),
      ),
    );
    _notify();
    _kick();
    return row;
  }

  Future<LocalWorkout> _startTx(String userId, String planSessionId) async {
    final open = await openWorkoutFor(planSessionId);
    if (open != null) return open;
    return _db
        .into(_workouts)
        .insertReturning(
          LocalWorkoutsCompanion.insert(
            clientId: _newId(),
            userId: userId,
            planSessionId: planSessionId,
            startedAt: _clock(),
          ),
        );
  }

  Future<LocalWorkout> _adoptTx(
    String userId,
    String planSessionId,
    TodayWorkoutRef adopt,
  ) async {
    final existing = await workoutByClientId(adopt.clientId);
    if (existing != null) {
      if (existing.serverId == null) {
        await (_db.update(_workouts)
              ..where((t) => t.clientId.equals(adopt.clientId)))
            .write(LocalWorkoutsCompanion(serverId: Value(adopt.id)));
      }
      return (await workoutByClientId(adopt.clientId))!;
    }
    // Un entrenamiento local abierto para la misma sesión sin id de la API
    // (o con ese mismo id) es el mismo: se enlaza en vez de duplicarlo.
    final open = await openWorkoutFor(planSessionId);
    if (open != null && (open.serverId == null || open.serverId == adopt.id)) {
      await _saveServerId(open.clientId, adopt.id);
      return (await workoutByClientId(open.clientId))!;
    }
    return _db
        .into(_workouts)
        .insertReturning(
          LocalWorkoutsCompanion.insert(
            clientId: adopt.clientId,
            userId: userId,
            planSessionId: planSessionId,
            serverId: Value(adopt.id),
            startedAt: adopt.startedAt,
          ),
        );
  }

  Future<void> _startLock = Future.value();

  /// Ejecuta [body] cuando terminen las llamadas anteriores (mutex simple).
  Future<T> _serialized<T>(Future<T> Function() body) {
    final result = _startLock.then((_) => body());
    _startLock = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<LocalWorkout?> workoutByClientId(String clientId) =>
      (_db.select(_workouts)
            ..where((t) => t.clientId.equals(clientId) & t.userId.equals(_uid)))
          .getSingleOrNull();

  /// Entrenamiento sin terminar del usuario para esa sesión del plan.
  Future<LocalWorkout?> openWorkoutFor(String planSessionId) =>
      (_db.select(_workouts)
            ..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.planSessionId.equals(planSessionId) &
                  t.finishedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<LocalWorkout?> watchOpenWorkout(String planSessionId) =>
      _watch(() => openWorkoutFor(planSessionId));

  /// Registra una serie (primero en drift) y dispara la sincronización.
  Future<LocalSetLog> logSet({
    required String workoutClientId,
    required String? planExerciseId,
    required String exerciseId,
    required int setIndex,
    required int reps,
    required double loadKg,
    int? rir,
    bool isWarmup = false,
    String? clientId,
  }) async {
    final now = _clock();
    final row = await _db
        .into(_sets)
        .insertReturning(
          LocalSetLogsCompanion.insert(
            clientId: clientId ?? _newId(),
            userId: _uid,
            workoutClientId: workoutClientId,
            planExerciseId: Value(planExerciseId),
            exerciseId: exerciseId,
            setIndex: setIndex,
            reps: reps,
            loadKg: loadKg,
            rir: Value(rir),
            isWarmup: Value(isWarmup),
            completedAt: now,
            updatedAt: now,
          ),
        );
    _kick();
    return row;
  }

  /// Marca el entrenamiento como terminado; el `finish` se envía cuando
  /// TODAS sus series estén sincronizadas. Las `failed` se vuelven a poner
  /// en cola antes (la API rechaza series nuevas con `409 WORKOUT_FINISHED`
  /// una vez terminado: enviar el finish antes las perdería para siempre).
  Future<void> finishWorkout(String workoutClientId) async {
    final userId = _uid;
    await _db.transaction(() async {
      await (_db.update(_workouts)..where(
            (t) => t.clientId.equals(workoutClientId) & t.userId.equals(userId),
          ))
          .write(
            LocalWorkoutsCompanion(
              finishedAt: Value(_clock()),
              attempts: const Value(0),
              nextAttemptAt: const Value(null),
              lastError: const Value(null),
            ),
          );
      await _requeueFailedSets(userId, workoutClientId: workoutClientId);
    });
    _kick();
  }

  /// Series sin confirmar por la API (pendientes, en envío o fallidas) de
  /// un entrenamiento.
  Future<int> unsyncedCount(String workoutClientId) async {
    final rows =
        await (_db.select(_sets)..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.workoutClientId.equals(workoutClientId) &
                  t.status.equalsValue(SetSyncStatus.synced).not(),
            ))
            .get();
    return rows.length;
  }

  /// Series del entrenamiento (cualquier estado), en orden de registro.
  Stream<List<LocalSetLog>> watchSets(String workoutClientId) =>
      _watch(() => setsOf(workoutClientId));

  Future<List<LocalSetLog>> setsOf(String workoutClientId) =>
      (_db.select(_sets)
            ..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.workoutClientId.equals(workoutClientId),
            )
            ..orderBy(_order))
          .get();

  /// Pendientes y fallidas del usuario (para la barra de estado).
  Stream<SyncSummary> watchSummary() {
    final userId = _userId;
    if (userId == null) return Stream.value(const SyncSummary());
    return _watch(() async {
      final rows =
          await (_db.select(_sets)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.status.equalsValue(SetSyncStatus.synced).not(),
              ))
              .get();
      return SyncSummary(
        pending: rows.where((r) => r.status != SetSyncStatus.failed).length,
        failed: rows.where((r) => r.status == SetSyncStatus.failed).length,
      );
    });
  }

  /// Avisa a los `watch*` de que algo cambió en la cola. Se usa un
  /// `StreamController` propio en vez de las stream queries de drift: es
  /// explícito (solo este servicio escribe en estas tablas) y funciona igual
  /// en los widget tests con reloj falso.
  final _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(Future<T> Function() query) {
    late final StreamController<T> controller;
    StreamSubscription<void>? sub;
    Future<void> emit() async {
      try {
        final value = await query();
        if (!controller.isClosed) controller.add(value);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        sub = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  static final _order = <OrderClauseGenerator<$LocalSetLogsTable>>[
    (t) => OrderingTerm.asc(t.completedAt),
    (t) => OrderingTerm.asc(t.setIndex),
  ];

  /// `syncing` → `pending` (la app murió durante un envío).
  Future<void> recoverInterrupted() async {
    final userId = _userId;
    if (userId == null) return;
    await (_db.update(_sets)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.syncing),
        ))
        .write(
          const LocalSetLogsCompanion(status: Value(SetSyncStatus.pending)),
        );
  }

  Future<void> _purgeOld() async {
    final cutoff = _clock().subtract(retention);
    await (_db.delete(_sets)..where(
          (t) =>
              t.userId.equals(_uid) &
              t.status.equalsValue(SetSyncStatus.synced) &
              t.completedAt.isSmallerThanValue(cutoff),
        ))
        .go();
    await (_db.delete(_workouts)..where(
          (t) =>
              t.userId.equals(_uid) &
              t.finishSynced.equals(true) &
              t.startedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  /// Vuelve a poner en cola lo `failed` (acción manual de la UI).
  Future<void> retryFailed() async {
    final userId = _userId;
    if (userId == null) return;
    await _requeueFailedSets(userId);
    await (_db.update(_workouts)..where((t) => t.userId.equals(userId))).write(
      const LocalWorkoutsCompanion(
        attempts: Value(0),
        nextAttemptAt: Value(null),
        lastError: Value(null),
      ),
    );
    _kick();
  }

  Future<void> _requeueFailedSets(
    String userId, {
    String? workoutClientId,
  }) async {
    await (_db.update(_sets)..where((t) {
          var cond =
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.failed);
          if (workoutClientId != null) {
            cond = cond & t.workoutClientId.equals(workoutClientId);
          }
          return cond;
        }))
        .write(
          const LocalSetLogsCompanion(
            status: Value(SetSyncStatus.pending),
            attempts: Value(0),
            nextAttemptAt: Value(null),
          ),
        );
  }

  /// Garantiza que el entrenamiento existe en la API (lo necesita la
  /// sustitución de ejercicio, que es online). Devuelve su id o lanza
  /// [ApiFailure].
  Future<String> ensureStartedOnServer(String workoutClientId) async {
    final w = await workoutByClientId(workoutClientId);
    if (w == null) throw StateError('Entrenamiento local desconocido');
    if (w.serverId != null) return w.serverId!;
    return _startOnServer(w);
  }

  /// `POST /workouts`. Si la API responde `409 WORKOUT_IN_PROGRESS` (ya hay
  /// otro entrenamiento en curso en la cuenta, p. ej. empezado en otro
  /// dispositivo), se consulta `GET /sessions/today` —que devuelve la
  /// sesión del entrenamiento en curso y su referencia— y, si es de la
  /// MISMA sesión del plan, se adopta: el entrenamiento local queda
  /// enlazado al id remoto y sus series se envían allí. Si es de otra
  /// sesión se propaga el 409 (la UI ofrece reintentar o descartar).
  Future<String> _startOnServer(LocalWorkout w) async {
    try {
      final result = await _api.startWorkout(
        StartWorkoutRequest(
          clientId: w.clientId,
          planSessionId: w.planSessionId,
          startedAt: w.startedAt,
        ),
      );
      await _saveServerId(w.clientId, result.value.id);
      return result.value.id;
    } catch (e) {
      final f = ApiFailure.from(e);
      if (f.code != ApiErrorCode.workoutInProgress) rethrow;
      final today = await _api.getToday();
      final remote = today.workout;
      if (remote != null &&
          remote.status == WorkoutStatus.inProgress &&
          today.planSessionId == w.planSessionId) {
        await _saveServerId(w.clientId, remote.id);
        return remote.id;
      }
      throw f;
    }
  }

  /// Entrenamientos locales cuyo inicio rechazó la API porque hay otro en
  /// curso (de otra sesión) en la cuenta. La UI ofrece reintentar (tras
  /// terminar el otro) o descartar el local.
  Stream<List<LocalWorkout>> watchConflictingWorkouts() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return _watch(
      () =>
          (_db.select(_workouts)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.serverId.isNull() &
                    t.lastError.equals(ApiErrorCode.workoutInProgress),
              ))
              .get(),
    );
  }

  /// Borra un entrenamiento local y sus series (acción «Descartar»).
  Future<void> discardWorkout(String workoutClientId) async {
    final userId = _uid;
    await _db.transaction(() async {
      await (_db.delete(_sets)..where(
            (t) =>
                t.userId.equals(userId) &
                t.workoutClientId.equals(workoutClientId),
          ))
          .go();
      await (_db.delete(_workouts)..where(
            (t) => t.userId.equals(userId) & t.clientId.equals(workoutClientId),
          ))
          .go();
    });
    _notify();
  }

  // ── Sincronización ──

  /// Ejecuta una pasada. Si ya hay una en curso, se encadena otra al
  /// terminar y se devuelve la misma `Future`.
  Future<SyncReport> syncNow() {
    if (_disposed || _userId == null) return Future.value(const SyncReport());
    _notify();
    final running = _running;
    if (running != null) {
      _runAgain = true;
      return running;
    }
    final future = _runPasses();
    _running = future;
    return future.whenComplete(() => _running = null);
  }

  Future<SyncReport> _runPasses() async {
    SyncReport report;
    do {
      _runAgain = false;
      report = await _pass();
      _notify();
    } while (_runAgain && !_disposed);
    return report;
  }

  Future<SyncReport> _pass() async {
    final userId = _userId!;
    if (!await _connectivity.isOnline()) {
      return const SyncReport(offline: true);
    }
    var sent = 0;
    var failed = 0;

    // a. Inicios de entrenamiento.
    final unstarted =
        await (_db.select(_workouts)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.serverId.isNull() &
                    t.attempts.isSmallerThanValue(backoff.maxAttempts),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    for (final w in unstarted) {
      if (_disposed) return SyncReport(sent: sent, failed: failed);
      if (_deferIfNotDue(w.nextAttemptAt)) {
        return SyncReport(sent: sent, failed: failed, deferred: 1);
      }
      try {
        await _startOnServer(w);
        sent++;
      } catch (e) {
        final f = ApiFailure.from(e);
        if (_isTransient(f) && w.attempts + 1 < backoff.maxAttempts) {
          await _deferWorkout(w, f);
          return SyncReport(sent: sent, failed: failed, deferred: 1);
        }
        await _failWorkout(w, f);
        failed++;
      }
    }

    // b. Series.
    final items =
        await (_db.select(_sets)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.status.equalsValue(SetSyncStatus.pending),
              )
              ..orderBy(_order))
            .get();
    for (var i = 0; i < items.length; i++) {
      if (_disposed) break;
      final item = items[i];
      final workout = await workoutByClientId(item.workoutClientId);
      final serverId = workout?.serverId;
      if (serverId == null) {
        // Inicio rechazado de forma definitiva: la serie no podrá enviarse
        // hasta que el usuario reintente; se marca `failed` (visible) en
        // vez de quedar `pending` para siempre.
        if (workout != null && workout.attempts >= backoff.maxAttempts) {
          await _markSetFailed(
            item,
            workout.lastError ?? 'WORKOUT_NOT_STARTED',
            item.attempts,
          );
          failed++;
        }
        continue; // espera a que el inicio sincronice
      }
      if (_deferIfNotDue(item.nextAttemptAt)) {
        return SyncReport(
          sent: sent,
          failed: failed,
          deferred: items.length - i,
        );
      }
      await _setStatus(item.clientId, SetSyncStatus.syncing);
      try {
        await _api.upsertSet(serverId, _requestFor(item));
        await _setStatus(item.clientId, SetSyncStatus.synced);
        sent++;
      } catch (e) {
        final f = ApiFailure.from(e);
        final attempts = item.attempts + 1;
        if (!_isTransient(f) || attempts >= backoff.maxAttempts) {
          await _markSetFailed(item, _reason(f), attempts);
          failed++;
          continue;
        }
        final delay = backoff.delayFor(attempts);
        await (_db.update(
          _sets,
        )..where((t) => t.clientId.equals(item.clientId))).write(
          LocalSetLogsCompanion(
            status: const Value(SetSyncStatus.pending),
            attempts: Value(attempts),
            lastError: Value(_reason(f)),
            nextAttemptAt: Value(_clock().add(delay)),
          ),
        );
        _scheduleRetry(delay);
        return SyncReport(
          sent: sent,
          failed: failed,
          deferred: items.length - i,
        );
      }
    }

    // c. Finales de entrenamiento. Solo cuando no queda NINGUNA serie sin
    // confirmar (tampoco `failed`): tras el finish la API rechaza series
    // nuevas con 409 WORKOUT_FINISHED.
    final finished =
        await (_db.select(_workouts)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.finishedAt.isNotNull() &
                  t.finishSynced.equals(false) &
                  t.serverId.isNotNull() &
                  t.attempts.isSmallerThanValue(backoff.maxAttempts),
            ))
            .get();
    for (final w in finished) {
      if (_disposed) break;
      final open =
          await (_db.select(_sets)..where(
                (t) =>
                    t.workoutClientId.equals(w.clientId) &
                    t.status.equalsValue(SetSyncStatus.synced).not(),
              ))
              .get();
      if (open.isNotEmpty) continue;
      if (_deferIfNotDue(w.nextAttemptAt)) continue;
      try {
        await _api.finishWorkout(w.serverId!, w.finishedAt!);
        await _markFinishSynced(w.clientId);
        sent++;
      } catch (e) {
        final f = ApiFailure.from(e);
        if (f.code == ApiErrorCode.workoutFinished) {
          await _markFinishSynced(w.clientId);
          continue;
        }
        if (_isTransient(f) && w.attempts + 1 < backoff.maxAttempts) {
          await _deferWorkout(w, f);
          return SyncReport(sent: sent, failed: failed, deferred: 1);
        }
        // Permanente o reintentos agotados: no se reintenta solo
        // (retryFailed lo vuelve a poner en cola).
        await (_db.update(
          _workouts,
        )..where((t) => t.clientId.equals(w.clientId))).write(
          LocalWorkoutsCompanion(
            attempts: Value(backoff.maxAttempts),
            lastError: Value(_reason(f)),
            nextAttemptAt: const Value(null),
          ),
        );
        failed++;
      }
    }
    return SyncReport(sent: sent, failed: failed);
  }

  static bool _isTransient(ApiFailure f) => f.isTransient;

  static String _reason(ApiFailure f) =>
      f.code ?? (f.statusCode != null ? 'HTTP ${f.statusCode}' : f.type.name);

  bool _deferIfNotDue(DateTime? due) {
    if (due == null) return false;
    final now = _clock();
    if (!due.isAfter(now)) return false;
    _scheduleRetry(due.difference(now));
    return true;
  }

  UpsertSetRequest _requestFor(LocalSetLog item) => UpsertSetRequest(
    clientId: item.clientId,
    planExerciseId: item.planExerciseId,
    exerciseId: item.exerciseId,
    setIndex: item.setIndex,
    reps: item.reps,
    loadKg: item.loadKg,
    rir: item.rir,
    isWarmup: item.isWarmup,
    completedAt: item.completedAt,
    clientUpdatedAt: item.updatedAt,
  );

  Future<void> _saveServerId(String clientId, String serverId) =>
      (_db.update(_workouts)..where((t) => t.clientId.equals(clientId))).write(
        LocalWorkoutsCompanion(
          serverId: Value(serverId),
          // `attempts` pasa a contar los intentos del finish.
          attempts: const Value(0),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
        ),
      );

  Future<void> _markFinishSynced(String clientId) =>
      (_db.update(_workouts)..where((t) => t.clientId.equals(clientId))).write(
        const LocalWorkoutsCompanion(
          finishSynced: Value(true),
          lastError: Value(null),
        ),
      );

  Future<void> _deferWorkout(LocalWorkout w, ApiFailure f) async {
    final attempts = w.attempts + 1;
    final delay = backoff.delayFor(attempts);
    await (_db.update(
      _workouts,
    )..where((t) => t.clientId.equals(w.clientId))).write(
      LocalWorkoutsCompanion(
        attempts: Value(attempts),
        lastError: Value(_reason(f)),
        nextAttemptAt: Value(_clock().add(delay)),
      ),
    );
    _scheduleRetry(delay);
  }

  /// Inicio rechazado de forma permanente: sus series no podrán enviarse;
  /// se marcan `failed` para que el usuario lo vea y pueda reintentar.
  Future<void> _failWorkout(LocalWorkout w, ApiFailure f) async {
    await (_db.update(
      _workouts,
    )..where((t) => t.clientId.equals(w.clientId))).write(
      LocalWorkoutsCompanion(
        attempts: Value(backoff.maxAttempts),
        lastError: Value(_reason(f)),
        nextAttemptAt: const Value(null),
      ),
    );
    await (_db.update(_sets)..where(
          (t) =>
              t.workoutClientId.equals(w.clientId) &
              t.status.equalsValue(SetSyncStatus.pending),
        ))
        .write(
          LocalSetLogsCompanion(
            status: const Value(SetSyncStatus.failed),
            lastError: Value(_reason(f)),
          ),
        );
  }

  Future<void> _setStatus(String clientId, SetSyncStatus status) async {
    await (_db.update(_sets)..where((t) => t.clientId.equals(clientId))).write(
      LocalSetLogsCompanion(status: Value(status)),
    );
    _notify();
  }

  Future<void> _markSetFailed(LocalSetLog item, String reason, int attempts) {
    return (_db.update(
      _sets,
    )..where((t) => t.clientId.equals(item.clientId))).write(
      LocalSetLogsCompanion(
        status: const Value(SetSyncStatus.failed),
        attempts: Value(attempts),
        lastError: Value(reason),
      ),
    );
  }

  void _scheduleRetry(Duration delay) {
    if (_disposed) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => _kick());
  }

  Future<void> dispose() async {
    _disposed = true;
    await _changes.close();
    _retryTimer?.cancel();
    await _connectivitySub?.cancel();
  }
}
