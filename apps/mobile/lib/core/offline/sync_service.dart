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
///    c. `POST /workouts/:id/finish` de los terminados sin series pendientes.
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
import 'package:uuid/uuid.dart';

import '../../data/pipos_api.dart';
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
  }) : _db = database,
       _api = api,
       _connectivity = connectivity,
       _userId = userId,
       _clock = clock ?? DateTime.now,
       _newId = idGenerator ?? const Uuid().v4;

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
      if (online) unawaited(syncNow());
    });
    unawaited(syncNow());
  }

  // ── Escrituras locales (la UI) ──

  /// Entrenamiento local para [planSessionId]. Si ya hay uno abierto para esa
  /// sesión se reutiliza; si la API ya tiene uno en curso ([adopt]), se
  /// registra con su `clientId` y su id.
  Future<LocalWorkout> startWorkout({
    required String planSessionId,
    TodayWorkoutRef? adopt,
  }) async {
    final userId = _uid;
    if (adopt != null) {
      final existing = await workoutByClientId(adopt.clientId);
      if (existing != null) {
        if (existing.serverId == null) {
          await (_db.update(_workouts)
                ..where((t) => t.clientId.equals(adopt.clientId)))
              .write(LocalWorkoutsCompanion(serverId: Value(adopt.id)));
        }
        return (await workoutByClientId(adopt.clientId))!;
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
    final open = await openWorkoutFor(planSessionId);
    if (open != null) return open;
    final row = await _db
        .into(_workouts)
        .insertReturning(
          LocalWorkoutsCompanion.insert(
            clientId: _newId(),
            userId: userId,
            planSessionId: planSessionId,
            startedAt: _clock(),
          ),
        );
    unawaited(syncNow());
    return row;
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
      (_db.select(_workouts)
            ..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.planSessionId.equals(planSessionId) &
                  t.finishedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(1))
          .watchSingleOrNull();

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
    unawaited(syncNow());
    return row;
  }

  /// Marca el entrenamiento como terminado; el `finish` se envía cuando
  /// todas sus series estén sincronizadas.
  Future<void> finishWorkout(String workoutClientId) async {
    await (_db.update(_workouts)..where(
          (t) => t.clientId.equals(workoutClientId) & t.userId.equals(_uid),
        ))
        .write(LocalWorkoutsCompanion(finishedAt: Value(_clock())));
    unawaited(syncNow());
  }

  /// Series del entrenamiento (cualquier estado), en orden de registro.
  Stream<List<LocalSetLog>> watchSets(String workoutClientId) =>
      (_db.select(_sets)
            ..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.workoutClientId.equals(workoutClientId),
            )
            ..orderBy(_order))
          .watch();

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
    return (_db.select(_sets)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.synced).not(),
        ))
        .watch()
        .map(
          (rows) => SyncSummary(
            pending: rows.where((r) => r.status != SetSyncStatus.failed).length,
            failed: rows.where((r) => r.status == SetSyncStatus.failed).length,
          ),
        );
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
    await (_db.update(_sets)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.failed),
        ))
        .write(
          const LocalSetLogsCompanion(
            status: Value(SetSyncStatus.pending),
            attempts: Value(0),
            nextAttemptAt: Value(null),
          ),
        );
    await (_db.update(_workouts)..where((t) => t.userId.equals(userId))).write(
      const LocalWorkoutsCompanion(
        attempts: Value(0),
        nextAttemptAt: Value(null),
        lastError: Value(null),
      ),
    );
    unawaited(syncNow());
  }

  /// Garantiza que el entrenamiento existe en la API (lo necesita la
  /// sustitución de ejercicio, que es online). Devuelve su id o lanza
  /// [ApiFailure].
  Future<String> ensureStartedOnServer(String workoutClientId) async {
    final w = await workoutByClientId(workoutClientId);
    if (w == null) throw StateError('Entrenamiento local desconocido');
    if (w.serverId != null) return w.serverId!;
    final result = await _api.startWorkout(
      StartWorkoutRequest(
        clientId: w.clientId,
        planSessionId: w.planSessionId,
        startedAt: w.startedAt,
      ),
    );
    await _saveServerId(w.clientId, result.value.id);
    return result.value.id;
  }

  // ── Sincronización ──

  /// Ejecuta una pasada. Si ya hay una en curso, se encadena otra al
  /// terminar y se devuelve la misma `Future`.
  Future<SyncReport> syncNow() {
    if (_disposed || _userId == null) return Future.value(const SyncReport());
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
        final result = await _api.startWorkout(
          StartWorkoutRequest(
            clientId: w.clientId,
            planSessionId: w.planSessionId,
            startedAt: w.startedAt,
          ),
        );
        await _saveServerId(w.clientId, result.value.id);
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
      if (serverId == null) continue; // espera a que el inicio sincronice
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

    // c. Finales de entrenamiento.
    final finished =
        await (_db.select(_workouts)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.finishedAt.isNotNull() &
                  t.finishSynced.equals(false) &
                  t.serverId.isNotNull(),
            ))
            .get();
    for (final w in finished) {
      if (_disposed) break;
      final open =
          await (_db.select(_sets)..where(
                (t) =>
                    t.workoutClientId.equals(w.clientId) &
                    t.status.isInValues([
                      SetSyncStatus.pending,
                      SetSyncStatus.syncing,
                    ]),
              ))
              .get();
      if (open.isNotEmpty) continue;
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
        if (_isTransient(f)) {
          _scheduleRetry(backoff.delayFor(1));
          return SyncReport(sent: sent, failed: failed, deferred: 1);
        }
        await (_db.update(_workouts)
              ..where((t) => t.clientId.equals(w.clientId)))
            .write(LocalWorkoutsCompanion(lastError: Value(_reason(f))));
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

  Future<void> _setStatus(String clientId, SetSyncStatus status) {
    return (_db.update(_sets)..where((t) => t.clientId.equals(clientId))).write(
      LocalSetLogsCompanion(status: Value(status)),
    );
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
    _retryTimer = Timer(delay, () => unawaited(syncNow()));
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _connectivitySub?.cancel();
  }
}
