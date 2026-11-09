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
///       `completedAt`, `setIndex`; idempotente por `clientId`). Una serie
///       ya confirmada y editada va por `PATCH` (gana la última escritura
///       por `clientUpdatedAt`) y una borrada por `DELETE` (#21, #22).
///       Intercalados por orden de registro, los cambios de ejercicio en
///       cola (`POST .../substitute`, #23): cada uno sale antes que las
///       series registradas después, que la API rechazaría sin él.
///    c. `POST /workouts/:id/finish` de los terminados sin series por
///       confirmar (ni pendientes ni `failed`), con el mismo backoff.
///    - 2xx → `synced`.
///    - Error transitorio (sin red, timeout, 5xx, 401, 408, 429) → sigue
///      `pending`, `attempts++`, `nextAttemptAt` con backoff exponencial; se
///      detiene la pasada (para no desordenar) y se programa un reintento.
///    - Error permanente (4xx) o reintentos agotados → `failed` (no bloquea
///      al resto). [retryFailed] los vuelve a poner en cola.
///    d. Otras escrituras offline ([PendingMutations], ADR-0013): nota fija
///       por ejercicio y medidas corporales, por orden de edición, con el
///       mismo backoff. Una fila por clave lógica: la última edición local
///       sustituye a la anterior (la API resuelve «gana la última escritura»
///       por `clientUpdatedAt` en las notas; las medidas son idempotentes).
/// 3. Al volver la conectividad se lanza otra pasada.
/// 4. Al arrancar, las series `syncing` huérfanas (la app murió a mitad de
///    envío) vuelven a `pending`: como el envío es idempotente, reenviarlas
///    es seguro (la API responde 200 con la fila existente).
library;

import 'dart:async';
import 'dart:convert';
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
  const SyncSummary({
    this.pending = 0,
    this.failed = 0,
    this.pendingChanges = 0,
    this.failedChanges = 0,
  });

  /// Series.
  final int pending;
  final int failed;

  /// Otras escrituras (notas, medidas).
  final int pendingChanges;
  final int failedChanges;

  int get unsent => pending + failed + pendingChanges + failedChanges;

  bool get isClean => unsent == 0;
}

/// Envía a la API una escritura de [PendingMutations] (lanza [ApiFailure]).
abstract class MutationSender {
  Future<void> send(PendingMutation mutation);
}

/// Cambio de ejercicio guardado en la cola (#23).
class PendingSwap {
  const PendingSwap({
    required this.workoutClientId,
    required this.planExerciseId,
    required this.exercise,
    required this.substitutedFrom,
    this.updatedAt,
    this.failed = false,
    this.lastError,
    this.key,
  });

  static const keyPrefix = 'swap:';

  /// Clave de la fila en la cola (para descartarla).
  final String? key;

  final String workoutClientId;
  final String planExerciseId;

  /// Ejercicio elegido para el hueco.
  final ExerciseRef exercise;

  /// Ejercicio original del hueco.
  final ExerciseRef substitutedFrom;
  final DateTime? updatedAt;
  final bool failed;
  final String? lastError;

  factory PendingSwap.fromMutation(PendingMutation m) {
    final p = (jsonDecode(m.payload) as Map).cast<String, dynamic>();
    return PendingSwap(
      workoutClientId: p['workoutClientId'] as String,
      planExerciseId: p['planExerciseId'] as String,
      exercise: ExerciseRef.fromJson(
        (p['exercise'] as Map).cast<String, dynamic>(),
      ),
      substitutedFrom: ExerciseRef.fromJson(
        (p['substitutedFrom'] as Map).cast<String, dynamic>(),
      ),
      updatedAt: m.updatedAt,
      failed: m.status == SetSyncStatus.failed,
      lastError: m.lastError,
      key: m.mutationKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'workoutClientId': workoutClientId,
    'planExerciseId': planExerciseId,
    'exercise': exercise.toJson(),
    'substitutedFrom': substitutedFrom.toJson(),
  };
}

enum _SwapOutcome { sent, failed, waiting, deferred }

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
    this.mutations,
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

  /// Envío de las otras escrituras offline; sin él no se procesan.
  final MutationSender? mutations;

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
  $PendingMutationsTable get _mutations => _db.pendingMutations;

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
    await _closeStaleWorkouts();
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
    WorkoutAdjustment? adjustment,
  }) async {
    final userId = _uid;
    final row = await _serialized(
      () => _db.transaction(
        () => adopt != null
            ? _adoptTx(userId, planSessionId, adopt)
            : _startTx(userId, planSessionId, adjustment),
      ),
    );
    _notify();
    _kick();
    return row;
  }

  Future<LocalWorkout> _startTx(
    String userId,
    String planSessionId,
    WorkoutAdjustment? adjustment,
  ) async {
    await _closeStaleWorkouts();
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
            adjustmentJson: Value(
              adjustment == null || adjustment.isNone
                  ? null
                  : jsonEncode(adjustment.toJson()),
            ),
          ),
        );
  }

  /// Ajuste guardado en el entrenamiento local (null = sesión completa).
  static WorkoutAdjustment? adjustmentOf(LocalWorkout w) {
    final raw = w.adjustmentJson;
    if (raw == null) return null;
    try {
      return WorkoutAdjustment.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Otras escrituras offline (notas, medidas) ──

  /// Guarda (o sustituye) la escritura pendiente de [key] y dispara la
  /// sincronización.
  Future<void> enqueueMutation({
    required String key,
    required MutationKind kind,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
  }) async {
    await _db
        .into(_mutations)
        .insertOnConflictUpdate(
          PendingMutationsCompanion.insert(
            userId: _uid,
            mutationKey: key,
            kind: kind,
            payload: jsonEncode(payload),
            updatedAt: updatedAt ?? _clock(),
            status: const Value(SetSyncStatus.pending),
            attempts: const Value(0),
            lastError: const Value(null),
            nextAttemptAt: const Value(null),
          ),
        );
    _notify();
    _kick();
  }

  /// Descarta la escritura pendiente de [key] (p. ej. se borra en local algo
  /// que aún no se había enviado).
  Future<void> discardMutation(String key) async {
    await (_db.delete(
      _mutations,
    )..where((t) => t.userId.equals(_uid) & t.mutationKey.equals(key))).go();
    _notify();
  }

  /// Cambio de ejercicio de un hueco en este entrenamiento (#23). Va a la
  /// cola (funciona sin red) y se envía EN ORDEN con las series: antes que
  /// las registradas después, que la API rechazaría sin la sustitución.
  /// Cada cambio es una fila propia (cambiar dos veces envía los dos).
  Future<void> enqueueSubstitution({
    required String workoutClientId,
    required String planExerciseId,
    required ExerciseRef exercise,
    required ExerciseRef substitutedFrom,
  }) async {
    final swap = PendingSwap(
      workoutClientId: workoutClientId,
      planExerciseId: planExerciseId,
      exercise: exercise,
      substitutedFrom: substitutedFrom,
    );
    await _db
        .into(_mutations)
        .insert(
          PendingMutationsCompanion.insert(
            userId: _uid,
            mutationKey:
                '${PendingSwap.keyPrefix}$workoutClientId:$planExerciseId:'
                '${_newId()}',
            kind: MutationKind.substitute,
            payload: jsonEncode(swap.toJson()),
            updatedAt: _clock(),
          ),
        );
    _notify();
    _kick();
  }

  /// Cambios de ejercicio en cola (pendientes o fallidos), en orden.
  Future<List<PendingSwap>> pendingSwaps() async {
    final rows =
        await (_db.select(_mutations)
              ..where(
                (t) =>
                    t.userId.equals(_uid) &
                    t.kind.equalsValue(MutationKind.substitute),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
            .get();
    return rows.map(PendingSwap.fromMutation).toList();
  }

  /// Igual que [pendingSwaps], como flujo que se actualiza con la cola.
  Stream<List<PendingSwap>> watchSwaps() => watchMutations(
    PendingSwap.keyPrefix,
  ).map((rows) => rows.map(PendingSwap.fromMutation).toList());

  /// Escrituras pendientes o fallidas cuya clave empieza por [prefix].
  Stream<List<PendingMutation>> watchMutations(String prefix) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return _watch(
      () =>
          (_db.select(_mutations)
                ..where(
                  (t) =>
                      t.userId.equals(userId) & t.mutationKey.like('$prefix%'),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
              .get(),
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
        final kept = await _linkToServer(adopt.clientId, adopt.id);
        return (await workoutByClientId(kept))!;
      }
      return existing;
    }
    // Un entrenamiento local abierto para la misma sesión sin id de la API
    // (o con ese mismo id) es el mismo: se enlaza en vez de duplicarlo.
    final open = await openWorkoutFor(planSessionId);
    if (open != null && (open.serverId == null || open.serverId == adopt.id)) {
      final kept = open.serverId == adopt.id
          ? open.clientId
          : await _linkToServer(open.clientId, adopt.id);
      return (await workoutByClientId(kept))!;
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

  /// Borra una serie en local: «Descartar» una rechazada por la API (#21)
  /// o «Borrar» una registrada (#22). Si pudo llegar al servidor queda como
  /// lápida `pending` hasta que la API confirme el `DELETE`; si no (nunca se
  /// envió o la API la rechazó al crearla), se borra la fila sin más.
  Future<void> deleteSet(String clientId) async {
    await _db.transaction(() async {
      final row = await _setByClientId(clientId);
      if (row == null || row.deleted) return;
      final workout = await workoutByClientId(row.workoutClientId);
      if (workout?.serverId == null || !mayBeOnServer(row)) {
        await (_db.delete(
          _sets,
        )..where((t) => t.clientId.equals(clientId))).go();
        return;
      }
      await (_db.update(
        _sets,
      )..where((t) => t.clientId.equals(clientId))).write(
        LocalSetLogsCompanion(
          deleted: const Value(true),
          status: const Value(SetSyncStatus.pending),
          attempts: const Value(0),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
          updatedAt: Value(_editTime(row.updatedAt)),
        ),
      );
    });
    _notify();
    _kick();
  }

  /// Corrige una serie registrada (#22): reps, carga y RIR. Si aún no se
  /// había enviado, la edición se funde con la creación pendiente (un solo
  /// `POST`); si ya existía en el servidor, se envía `PATCH` con
  /// `clientUpdatedAt` (gana la última escritura). La UI se pinta al
  /// instante desde drift.
  Future<void> updateSet(
    String clientId, {
    required int reps,
    required double loadKg,
    required int? rir,
  }) async {
    await _db.transaction(() async {
      final row = await _setByClientId(clientId);
      if (row == null || row.deleted) return;
      await (_db.update(
        _sets,
      )..where((t) => t.clientId.equals(clientId))).write(
        LocalSetLogsCompanion(
          reps: Value(reps),
          loadKg: Value(loadKg),
          rir: Value(rir),
          updatedAt: Value(_editTime(row.updatedAt)),
          status: const Value(SetSyncStatus.pending),
          attempts: const Value(0),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
        ),
      );
    });
    _notify();
    _kick();
  }

  /// Copia local (confirmada) de una serie que solo está en la API (p. ej.
  /// registrada en otro dispositivo), para poder editarla o borrarla por la
  /// cola. No hace nada si ya existe.
  Future<void> adoptServerSet(String workoutClientId, SetLog set) async {
    await _db
        .into(_sets)
        .insert(
          LocalSetLogsCompanion.insert(
            clientId: set.clientId,
            userId: _uid,
            workoutClientId: workoutClientId,
            planExerciseId: Value(set.planExerciseId),
            exerciseId: set.exerciseId,
            setIndex: set.setIndex,
            reps: set.reps,
            loadKg: set.loadKg,
            rir: Value(set.rir),
            isWarmup: Value(set.isWarmup),
            completedAt: set.completedAt,
            updatedAt: set.clientUpdatedAt,
            status: const Value(SetSyncStatus.synced),
            confirmed: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// `true` si la serie puede existir en el servidor: confirmada, en envío o
  /// con algún intento cuyo resultado no se conoce (timeout, 5xx...). Un
  /// rechazo de validación al crearla garantiza que la API no la guardó (el
  /// reenvío de una serie existente responde 200 antes de validar).
  static bool mayBeOnServer(LocalSetLog s) {
    if (s.confirmed || s.status == SetSyncStatus.syncing) return true;
    if (s.attempts == 0) return false;
    return !rejectionCodes.contains(s.lastError);
  }

  /// Motivos (`lastError`) de una serie que la API rechazó al crearla.
  static const rejectionCodes = {
    ApiErrorCode.validationFailed,
    ApiErrorCode.unknownExercise,
    ApiErrorCode.workoutFinished,
    ApiErrorCode.notFound,
    'HTTP 400',
    'HTTP 422',
  };

  /// Momento de una edición local, siempre posterior a la anterior (drift
  /// guarda las fechas con precisión de segundos y la API resuelve «gana la
  /// última escritura» por `clientUpdatedAt`).
  DateTime _editTime(DateTime previous) {
    final now = _clock();
    return now.difference(previous) >= const Duration(seconds: 1)
        ? now
        : previous.add(const Duration(seconds: 1));
  }

  Future<LocalSetLog?> _setByClientId(String clientId) =>
      (_db.select(_sets)
            ..where((t) => t.clientId.equals(clientId) & t.userId.equals(_uid)))
          .getSingleOrNull();

  /// Sin actividad durante este tiempo, la API abandona sola un
  /// entrenamiento en curso al empezar otro.
  static const staleAfter = Duration(hours: 12);

  /// «Abandonar entrenamiento» (issue #13): funciona sin red. Si nunca llegó
  /// al servidor se borra sin más; si no, se cierra en local (deja de estar
  /// abierto) y la cola envía `POST /workouts/:id/abandon` (idempotente).
  /// Las series que la API no había confirmado se descartan: un entrenamiento
  /// abandonado no admite series nuevas y lo hecho deja de contar.
  Future<void> abandonWorkout(String workoutClientId) async {
    final w = await workoutByClientId(workoutClientId);
    if (w == null) return;
    if (w.serverId == null) return discardWorkout(workoutClientId);
    await _db.transaction(() async {
      await (_db.delete(_sets)..where(
            (t) =>
                t.workoutClientId.equals(workoutClientId) &
                t.confirmed.equals(false),
          ))
          .go();
      for (final m in await _swapRowsOf(workoutClientId)) {
        await (_db.delete(_mutations)..where(
              (t) =>
                  t.userId.equals(m.userId) &
                  t.mutationKey.equals(m.mutationKey),
            ))
            .go();
      }
      await (_db.update(
        _workouts,
      )..where((t) => t.clientId.equals(workoutClientId))).write(
        LocalWorkoutsCompanion(
          finishedAt: Value(_clock()),
          abandoned: const Value(true),
          finishSynced: const Value(false),
          attempts: const Value(0),
          nextAttemptAt: const Value(null),
          lastError: const Value(null),
        ),
      );
    });
    _notify();
    _kick();
  }

  /// Entrenamientos abiertos ya enlazados con la API, sin nada pendiente y
  /// sin actividad desde hace más de [staleAfter]: el servidor los
  /// abandonará (o ya lo hizo) al empezar otro. Se cierran también en local,
  /// como abandonados, para que una sesión nueva no se registre en ellos.
  Future<void> _closeStaleWorkouts() async {
    final userId = _userId;
    if (userId == null) return;
    final cutoff = _clock().subtract(staleAfter);
    final open =
        await (_db.select(_workouts)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.finishedAt.isNull() &
                  t.serverId.isNotNull() &
                  t.startedAt.isSmallerThanValue(cutoff),
            ))
            .get();
    for (final w in open) {
      final sets = await (_db.select(
        _sets,
      )..where((t) => t.workoutClientId.equals(w.clientId))).get();
      if (sets.any((s) => s.status != SetSyncStatus.synced)) continue;
      var last = w.startedAt;
      for (final s in sets) {
        if (s.updatedAt.isAfter(last)) last = s.updatedAt;
      }
      if (!last.isBefore(cutoff)) continue;
      await (_db.update(
        _workouts,
      )..where((t) => t.clientId.equals(w.clientId))).write(
        LocalWorkoutsCompanion(
          finishedAt: Value(last),
          abandoned: const Value(true),
          attempts: const Value(0),
        ),
      );
    }
  }

  /// La API rechazó una escritura con `409 WORKOUT_FINISHED`: el
  /// entrenamiento ya está cerrado en el servidor (terminado en otro
  /// dispositivo o abandonado solo tras 12 h sin actividad). Se trata como
  /// cerrado: no se reintenta nada de él; sus series sin confirmar quedan
  /// fuera (sin bloquear la cola) y, si la persona no lo había terminado,
  /// Hoy lo explica ([watchClosedRemotely]).
  Future<void> _closedRemotely(String workoutClientId) async {
    final w = await workoutByClientId(workoutClientId);
    if (w == null) return;
    await (_db.update(_sets)..where(
          (t) =>
              t.workoutClientId.equals(workoutClientId) &
              t.confirmed.equals(false) &
              t.status.equalsValue(SetSyncStatus.synced).not(),
        ))
        .write(
          const LocalSetLogsCompanion(
            status: Value(SetSyncStatus.synced),
            lastError: Value(ApiErrorCode.workoutFinished),
            nextAttemptAt: Value(null),
          ),
        );
    for (final m in await _swapRowsOf(workoutClientId)) {
      await (_db.delete(_mutations)..where(
            (t) =>
                t.userId.equals(m.userId) & t.mutationKey.equals(m.mutationKey),
          ))
          .go();
    }
    await (_db.update(
      _workouts,
    )..where((t) => t.clientId.equals(workoutClientId))).write(
      LocalWorkoutsCompanion(
        finishedAt: Value(w.finishedAt ?? _clock()),
        finishSynced: const Value(true),
        abandoned: Value(w.abandoned || w.finishedAt == null),
        lastError: Value(w.finishedAt == null ? closedRemotelyCode : null),
        nextAttemptAt: const Value(null),
      ),
    );
    _notify();
  }

  /// `lastError` de un entrenamiento que el servidor cerró por su cuenta.
  static const closedRemotelyCode = 'WORKOUT_CLOSED_REMOTELY';

  /// Entrenamientos cerrados por el servidor sin que la persona los
  /// terminara (aviso en Hoy hasta que lo cierre con [dismissClosedNotice]).
  Stream<List<LocalWorkout>> watchClosedRemotely() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return _watch(
      () =>
          (_db.select(_workouts)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.lastError.equals(closedRemotelyCode),
              ))
              .get(),
    );
  }

  Future<void> dismissClosedNotice(String workoutClientId) async {
    await (_db.update(_workouts)
          ..where((t) => t.clientId.equals(workoutClientId)))
        .write(const LocalWorkoutsCompanion(lastError: Value(null)));
    _notify();
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
      final changes = await (_db.select(
        _mutations,
      )..where((t) => t.userId.equals(userId))).get();
      return SyncSummary(
        pending: rows.where((r) => r.status != SetSyncStatus.failed).length,
        failed: rows.where((r) => r.status == SetSyncStatus.failed).length,
        pendingChanges: changes
            .where((r) => r.status != SetSyncStatus.failed)
            .length,
        failedChanges: changes
            .where((r) => r.status == SetSyncStatus.failed)
            .length,
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
    await (_db.update(_mutations)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.syncing),
        ))
        .write(
          const PendingMutationsCompanion(status: Value(SetSyncStatus.pending)),
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
    await (_db.update(_mutations)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SetSyncStatus.failed),
        ))
        .write(
          const PendingMutationsCompanion(
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

  /// `POST /workouts`. Si la API responde `409 WORKOUT_IN_PROGRESS` (ya hay
  /// otro entrenamiento en curso en la cuenta, p. ej. empezado en otro
  /// dispositivo), se consulta `GET /sessions/today` —que devuelve la
  /// sesión del entrenamiento en curso y su referencia— y, si es de la
  /// MISMA sesión del plan, se adopta: el entrenamiento local queda
  /// enlazado al id remoto y sus series se envían allí. Si es de otra
  /// sesión se propaga el 409 (la UI ofrece reintentar o descartar).
  ///
  /// `409 PLAN_SESSION_OUTDATED` (el plan cambió, p. ej. desde otro
  /// dispositivo, mientras el inicio esperaba en la cola) no es un fallo
  /// permanente: se relee `GET /sessions/today` y, si el entrenamiento local
  /// aún no tiene series ni cambios de ejercicio (que serían de huecos de la
  /// versión antigua), se reapunta a la sesión vigente y se reintenta con el
  /// MISMO `clientId`. Si ya los tiene, se propaga: queda en conflicto (sin
  /// bloquear la cola) y la UI ofrece descartarlo o conservarlo en el móvil.
  Future<String> _startOnServer(LocalWorkout w, {bool retried = false}) async {
    try {
      final result = await _api.startWorkout(
        StartWorkoutRequest(
          clientId: w.clientId,
          planSessionId: w.planSessionId,
          startedAt: w.startedAt,
          adjustment: adjustmentOf(w),
        ),
      );
      await _db.transaction(() => _linkToServer(w.clientId, result.value.id));
      return result.value.id;
    } catch (e) {
      final f = ApiFailure.from(e);
      if (f.code == ApiErrorCode.planSessionOutdated) {
        _planOutdated();
        if (retried) rethrow;
        final today = await _api.getToday();
        final hasWork =
            (await setsOf(w.clientId)).any((s) => !s.deleted) ||
            (await _swapRowsOf(w.clientId)).isNotEmpty;
        if (hasWork || today.planSessionId == w.planSessionId) rethrow;
        await (_db.update(
          _workouts,
        )..where((t) => t.clientId.equals(w.clientId))).write(
          LocalWorkoutsCompanion(planSessionId: Value(today.planSessionId)),
        );
        _notify();
        return _startOnServer(
          w.copyWith(planSessionId: today.planSessionId),
          retried: true,
        );
      }
      if (f.code != ApiErrorCode.workoutInProgress) rethrow;
      final today = await _api.getToday();
      final remote = today.workout;
      if (remote != null &&
          remote.status == WorkoutStatus.inProgress &&
          today.planSessionId == w.planSessionId) {
        await _db.transaction(() => _linkToServer(w.clientId, remote.id));
        return remote.id;
      }
      throw f;
    }
  }

  /// La API avisó de que el plan cambió (`PLAN_SESSION_OUTDATED`): la UI
  /// relee la sesión de hoy y el plan.
  Stream<void> get planOutdated => _planOutdatedController.stream;
  final _planOutdatedController = StreamController<void>.broadcast();

  void _planOutdated() {
    if (!_planOutdatedController.isClosed) _planOutdatedController.add(null);
  }

  /// Entrenamientos locales cuyo inicio rechazó la API porque hay otro en
  /// curso (de otra sesión) en la cuenta, o porque su sesión es de una
  /// versión del plan que ya no es la vigente y ya tiene series
  /// (`lastError` lo distingue). La UI ofrece reintentar (solo en el primer
  /// caso) o descartar el local.
  Stream<List<LocalWorkout>> watchConflictingWorkouts() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return _watch(
      () =>
          (_db.select(_workouts)..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.serverId.isNull() &
                    t.lastError.isIn(const [
                      ApiErrorCode.workoutInProgress,
                      ApiErrorCode.planSessionOutdated,
                    ]),
              ))
              .get(),
    );
  }

  /// Cambios de ejercicio en cola de un entrenamiento local.
  Future<List<PendingMutation>> _swapRowsOf(String workoutClientId) async {
    final rows =
        await (_db.select(_mutations)..where(
              (t) =>
                  t.userId.equals(_uid) &
                  t.kind.equalsValue(MutationKind.substitute),
            ))
            .get();
    return rows
        .where(
          (m) => PendingSwap.fromMutation(m).workoutClientId == workoutClientId,
        )
        .toList();
  }

  /// Borra un entrenamiento local, sus series y sus cambios de ejercicio en
  /// cola (acción «Descartar»).
  Future<void> discardWorkout(String workoutClientId) async {
    final userId = _uid;
    await _db.transaction(() async {
      for (final m in await _swapRowsOf(workoutClientId)) {
        await (_db.delete(_mutations)..where(
              (t) =>
                  t.userId.equals(userId) & t.mutationKey.equals(m.mutationKey),
            ))
            .go();
      }
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
    // Cambios de ejercicio (#23), intercalados por orden de registro: cada
    // uno sale antes que las series registradas después (a igual segundo,
    // primero el cambio). Uno aplazado detiene la pasada, como una serie.
    final swaps =
        await (_db.select(_mutations)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.kind.equalsValue(MutationKind.substitute) &
                    t.status.equalsValue(SetSyncStatus.pending),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
            .get();
    var nextSwap = 0;
    Future<bool> sendSwapsUntil(DateTime? until) async {
      while (nextSwap < swaps.length && !_disposed) {
        final m = swaps[nextSwap];
        if (until != null && m.updatedAt.isAfter(until)) return true;
        nextSwap++;
        switch (await _sendSwap(m)) {
          case _SwapOutcome.sent:
            sent++;
          case _SwapOutcome.failed:
            failed++;
          case _SwapOutcome.waiting:
            break;
          case _SwapOutcome.deferred:
            return false;
        }
      }
      return true;
    }

    for (var i = 0; i < items.length; i++) {
      if (_disposed) break;
      final item = items[i];
      if (!await sendSwapsUntil(item.completedAt)) {
        return SyncReport(
          sent: sent,
          failed: failed,
          deferred: items.length - i + swaps.length - nextSwap + 1,
        );
      }
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
      // Solo si nadie la ha cambiado (editado, borrado) desde la lectura.
      if (!await _claim(item)) continue;
      try {
        if (item.deleted) {
          await _sendDelete(serverId, item);
        } else {
          final remote = await _sendSet(serverId, item);
          await _confirm(item, remote: remote);
        }
        sent++;
      } catch (e) {
        final f = ApiFailure.from(e);
        final attempts = item.attempts + 1;
        if (item.deleted && !_isTransient(f)) {
          // Borrado rechazado de forma permanente: no hay nada más que
          // hacer con la lápida (la UI ya no la pinta).
          await _removeSet(item.clientId);
          failed++;
          continue;
        }
        if (f.code == ApiErrorCode.workoutFinished && !item.confirmed) {
          await _closedRemotely(item.workoutClientId);
          failed++;
          continue;
        }
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

    if (!await sendSwapsUntil(null)) {
      return SyncReport(
        sent: sent,
        failed: failed,
        deferred: swaps.length - nextSwap + 1,
      );
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
      // Un abandono no espera a las series (las no confirmadas ya se
      // descartaron; editar o borrar las confirmadas sigue permitido).
      final open = w.abandoned
          ? const <LocalSetLog>[]
          : await (_db.select(_sets)..where(
                  (t) =>
                      t.workoutClientId.equals(w.clientId) &
                      t.status.equalsValue(SetSyncStatus.synced).not(),
                ))
                .get();
      if (open.isNotEmpty) continue;
      if (_deferIfNotDue(w.nextAttemptAt)) continue;
      try {
        if (w.abandoned) {
          await _api.abandonWorkout(w.serverId!);
        } else {
          await _api.finishWorkout(w.serverId!, w.finishedAt!);
        }
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

    // d. Otras escrituras (notas, medidas).
    final sender = mutations;
    if (sender != null) {
      final pending =
          await (_db.select(_mutations)
                ..where(
                  (t) =>
                      t.userId.equals(userId) &
                      t.status.equalsValue(SetSyncStatus.pending) &
                      t.kind.equalsValue(MutationKind.substitute).not(),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
              .get();
      for (var i = 0; i < pending.length; i++) {
        if (_disposed) break;
        final m = pending[i];
        if (_deferIfNotDue(m.nextAttemptAt)) {
          return SyncReport(
            sent: sent,
            failed: failed,
            deferred: pending.length - i,
          );
        }
        await _setMutationStatus(m, SetSyncStatus.syncing);
        try {
          await sender.send(m);
          await _mutationSent(m);
          sent++;
        } catch (e) {
          if (await _mutationFailed(m, ApiFailure.from(e))) {
            failed++;
            continue;
          }
          return SyncReport(
            sent: sent,
            failed: failed,
            deferred: pending.length - i,
          );
        }
      }
    }
    return SyncReport(sent: sent, failed: failed);
  }

  /// Envía un cambio de ejercicio de la cola (#23).
  Future<_SwapOutcome> _sendSwap(PendingMutation m) async {
    final swap = PendingSwap.fromMutation(m);
    final workout = await workoutByClientId(swap.workoutClientId);
    if (workout == null) {
      // Entrenamiento descartado: el cambio ya no tiene a qué aplicarse.
      await (_db.delete(_mutations)..where(
            (t) =>
                t.userId.equals(m.userId) & t.mutationKey.equals(m.mutationKey),
          ))
          .go();
      _notify();
      return _SwapOutcome.waiting;
    }
    final serverId = workout.serverId;
    if (serverId == null) {
      if (workout.attempts < backoff.maxAttempts) return _SwapOutcome.waiting;
      final reason = workout.lastError ?? 'WORKOUT_NOT_STARTED';
      await _mutationFailed(
        m,
        ApiFailure(
          type: ApiFailureType.badRequest,
          message: reason,
          code: reason,
        ),
      );
      return _SwapOutcome.failed;
    }
    if (_deferIfNotDue(m.nextAttemptAt)) return _SwapOutcome.deferred;
    await _setMutationStatus(m, SetSyncStatus.syncing);
    try {
      await _api.substitute(
        workoutId: serverId,
        planExerciseId: swap.planExerciseId,
        exerciseId: swap.exercise.id,
      );
      await _mutationSent(m);
      return _SwapOutcome.sent;
    } catch (e) {
      final f = ApiFailure.from(e);
      if (f.code == ApiErrorCode.workoutFinished) {
        await _closedRemotely(swap.workoutClientId);
        return _SwapOutcome.failed;
      }
      return await _mutationFailed(m, f)
          ? _SwapOutcome.failed
          : _SwapOutcome.deferred;
    }
  }

  /// La API confirmó la escritura: se borra si nadie la ha sustituido
  /// mientras se enviaba.
  Future<void> _mutationSent(PendingMutation m) async {
    await (_db.delete(_mutations)..where(
          (t) =>
              t.userId.equals(m.userId) &
              t.mutationKey.equals(m.mutationKey) &
              t.updatedAt.equals(m.updatedAt) &
              t.payload.equals(m.payload),
        ))
        .go();
    await _setMutationStatus(m, SetSyncStatus.pending);
  }

  /// Registra un fallo de envío. Devuelve true si es permanente (`failed`);
  /// si no, queda `pending` con backoff y un reintento programado.
  Future<bool> _mutationFailed(PendingMutation m, ApiFailure f) async {
    final attempts = m.attempts + 1;
    final permanent = !_isTransient(f) || attempts >= backoff.maxAttempts;
    final delay = backoff.delayFor(attempts);
    await (_db.update(_mutations)..where(
          (t) =>
              t.userId.equals(m.userId) & t.mutationKey.equals(m.mutationKey),
        ))
        .write(
          PendingMutationsCompanion(
            status: Value(
              permanent ? SetSyncStatus.failed : SetSyncStatus.pending,
            ),
            attempts: Value(attempts),
            lastError: Value(_reason(f)),
            nextAttemptAt: Value(permanent ? null : _clock().add(delay)),
          ),
        );
    _notify();
    if (!permanent) _scheduleRetry(delay);
    return permanent;
  }

  /// Cambia el estado si la fila sigue existiendo (si se envió, ya no está).
  Future<void> _setMutationStatus(
    PendingMutation m,
    SetSyncStatus status,
  ) async {
    await (_db.update(_mutations)..where(
          (t) =>
              t.userId.equals(m.userId) &
              t.mutationKey.equals(m.mutationKey) &
              t.status.equalsValue(SetSyncStatus.failed).not(),
        ))
        .write(PendingMutationsCompanion(status: Value(status)));
    _notify();
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

  /// Enlaza el entrenamiento local [clientId] con el id de la API. Si otro
  /// entrenamiento local ya apunta a ese id (p. ej. dos inicios encolados de
  /// la misma sesión y el segundo adopta el primero tras un `409
  /// WORKOUT_IN_PROGRESS`), se fusionan: las series del duplicado pasan al
  /// ya enlazado y el duplicado se borra. El resultado queda terminado solo
  /// si los dos lo estaban (si no, la persona sigue entrenando en él).
  /// Devuelve el `clientId` que sobrevive. Llamar dentro de una transacción.
  Future<String> _linkToServer(String clientId, String serverId) async {
    final linked =
        await (_db.select(_workouts)
              ..where(
                (t) =>
                    t.userId.equals(_uid) &
                    t.serverId.equals(serverId) &
                    t.clientId.equals(clientId).not(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    final dup = await workoutByClientId(clientId);
    if (linked == null || dup == null) {
      await _saveServerId(clientId, serverId);
      return clientId;
    }
    await _mergeInto(dup, linked);
    return linked.clientId;
  }

  /// Pasa a [target] todo lo que cuelga de [dup] y borra [dup].
  Future<void> _mergeInto(LocalWorkout dup, LocalWorkout target) async {
    await (_db.update(_sets)
          ..where((t) => t.workoutClientId.equals(dup.clientId)))
        .write(LocalSetLogsCompanion(workoutClientId: Value(target.clientId)));
    for (final m in await _swapRowsOf(dup.clientId)) {
      final swap = PendingSwap.fromMutation(m);
      final moved = PendingSwap(
        workoutClientId: target.clientId,
        planExerciseId: swap.planExerciseId,
        exercise: swap.exercise,
        substitutedFrom: swap.substitutedFrom,
      );
      await (_db.update(_mutations)..where(
            (t) =>
                t.userId.equals(m.userId) & t.mutationKey.equals(m.mutationKey),
          ))
          .write(
            PendingMutationsCompanion(
              payload: Value(jsonEncode(moved.toJson())),
            ),
          );
    }
    final bothFinished = dup.finishedAt != null && target.finishedAt != null;
    final finishedAt = !bothFinished
        ? null
        : (dup.finishedAt!.isAfter(target.finishedAt!)
              ? dup.finishedAt
              : target.finishedAt);
    if (finishedAt != target.finishedAt) {
      await (_db.update(
        _workouts,
      )..where((t) => t.clientId.equals(target.clientId))).write(
        LocalWorkoutsCompanion(
          finishedAt: Value(finishedAt),
          finishSynced: const Value(false),
          attempts: const Value(0),
          nextAttemptAt: const Value(null),
        ),
      );
    }
    await (_db.delete(
      _workouts,
    )..where((t) => t.clientId.equals(dup.clientId))).go();
    _notify();
  }

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

  /// `pending` → `syncing` solo si la fila sigue como se leyó (mismo
  /// `updatedAt`, misma marca de borrado). Devuelve false si cambió.
  Future<bool> _claim(LocalSetLog item) async {
    final n =
        await (_db.update(_sets)..where(
              (t) =>
                  t.clientId.equals(item.clientId) &
                  t.status.equalsValue(SetSyncStatus.pending) &
                  t.updatedAt.equals(item.updatedAt) &
                  t.deleted.equals(item.deleted),
            ))
            .write(
              const LocalSetLogsCompanion(status: Value(SetSyncStatus.syncing)),
            );
    _notify();
    return n > 0;
  }

  /// La API confirmó la serie. Si se editó o borró mientras se enviaba, la
  /// fila queda `pending` (con `confirmed`) y se envía otra vez: el reenvío
  /// responde 200 con la versión del servidor y se corrige con `PATCH`.
  ///
  /// Si la versión del servidor ([remote]) es más reciente (otra edición
  /// ganó por `clientUpdatedAt`, o se borró desde otro dispositivo), la fila
  /// local la adopta para no mostrar algo distinto de lo guardado.
  Future<void> _confirm(LocalSetLog item, {SetLog? remote}) async {
    final newer =
        remote != null && remote.clientUpdatedAt.isAfter(item.updatedAt);
    final n =
        await (_db.update(_sets)..where(
              (t) =>
                  t.clientId.equals(item.clientId) &
                  t.updatedAt.equals(item.updatedAt) &
                  t.deleted.equals(false),
            ))
            .write(
              LocalSetLogsCompanion(
                status: const Value(SetSyncStatus.synced),
                confirmed: const Value(true),
                lastError: const Value(null),
                nextAttemptAt: const Value(null),
                deleted: Value(remote?.deletedAt != null),
                reps: newer ? Value(remote.reps) : const Value.absent(),
                loadKg: newer ? Value(remote.loadKg) : const Value.absent(),
                rir: newer ? Value(remote.rir) : const Value.absent(),
                updatedAt: newer
                    ? Value(remote.clientUpdatedAt)
                    : const Value.absent(),
              ),
            );
    if (n == 0) {
      await (_db.update(_sets)..where(
            (t) =>
                t.clientId.equals(item.clientId) &
                t.status.equalsValue(SetSyncStatus.syncing),
          ))
          .write(
            const LocalSetLogsCompanion(
              status: Value(SetSyncStatus.pending),
              confirmed: Value(true),
            ),
          );
      await (_db.update(_sets)..where((t) => t.clientId.equals(item.clientId)))
          .write(const LocalSetLogsCompanion(confirmed: Value(true)));
      _runAgain = true;
    }
    _notify();
  }

  /// Crea la serie (`POST`, idempotente) o, si ya existía en el servidor,
  /// le aplica la edición local con `PATCH` (gana la última escritura por
  /// `clientUpdatedAt`). Una edición de una serie aún no enviada viaja en el
  /// propio `POST`: no hace falta `PATCH`.
  ///
  /// Devuelve la versión del servidor tras el envío.
  Future<SetLog> _sendSet(String serverId, LocalSetLog item) async {
    if (item.confirmed) {
      return _api.patchSet(serverId, item.clientId, _patchFor(item));
    }
    final result = await _api.upsertSet(serverId, _requestFor(item));
    final remote = result.value;
    if (!result.created &&
        remote.deletedAt == null &&
        remote.clientUpdatedAt.isBefore(item.updatedAt) &&
        (remote.reps != item.reps ||
            remote.loadKg != item.loadKg ||
            remote.rir != item.rir)) {
      // Ya estaba (respuesta perdida, o editada mientras se enviaba).
      return _api.patchSet(serverId, item.clientId, _patchFor(item));
    }
    return remote;
  }

  PatchSetRequest _patchFor(LocalSetLog item) => PatchSetRequest(
    reps: item.reps,
    loadKg: item.loadKg,
    rir: item.rir,
    clientUpdatedAt: item.updatedAt,
  );

  /// `DELETE` de una lápida; 404 = nunca llegó al servidor (también vale).
  /// La lápida se conserva `synced` (hasta la purga) para seguir ocultando
  /// la copia de la API que tenga en memoria la sesión de hoy.
  Future<void> _sendDelete(String serverId, LocalSetLog item) async {
    try {
      await _api.deleteSet(serverId, item.clientId);
    } catch (e) {
      if (ApiFailure.from(e).statusCode != 404) rethrow;
    }
    await (_db.update(_sets)..where(
          (t) => t.clientId.equals(item.clientId) & t.deleted.equals(true),
        ))
        .write(
          const LocalSetLogsCompanion(
            status: Value(SetSyncStatus.synced),
            nextAttemptAt: Value(null),
            lastError: Value(null),
          ),
        );
    _notify();
  }

  Future<void> _removeSet(String clientId) async {
    await (_db.delete(_sets)..where((t) => t.clientId.equals(clientId))).go();
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
    await _planOutdatedController.close();
    _retryTimer?.cancel();
    await _connectivitySub?.cancel();
  }
}
