/// Sync Service (ADR-0007, offline-first)
///
/// Flujo de una serie registrada:
/// 1. La UI llama a [SyncService.enqueue]: se escribe en `pending_set_logs`
///    (drift) y se actualiza la UI de forma optimista.
/// 2. [SyncService.syncNow] envía, si hay red, las series `pending` del
///    usuario EN ORDEN (`completedAt`, `setIndex`).
///    - 2xx o 409 (duplicado por `clientId`) → sincronizada: se borra de la
///      cola y se emite en [SyncService.synced].
///    - Error transitorio → sigue `pending`, `attempts++` y `nextAttemptAt`
///      con backoff exponencial; se detiene la pasada (para no desordenar) y
///      se programa un reintento.
///    - Error permanente o reintentos agotados → `failed` (no bloquea al
///      resto de la cola).
/// 3. Al volver la conectividad se lanza otra pasada.
/// 4. Al arrancar, los `syncing` huérfanos (la app murió a mitad de envío)
///    vuelven a `pending`: como el envío es idempotente por `clientId`,
///    reenviarlos es seguro.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'connectivity.dart';
import 'set_log_uploader.dart';

class BackoffPolicy {
  const BackoffPolicy({
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    this.maxAttempts = 8,
  });

  final Duration baseDelay;
  final Duration maxDelay;

  /// Tras este número de intentos fallidos la serie pasa a `failed`.
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

/// Serie confirmada por la API.
class SyncedSetLog {
  const SyncedSetLog({
    required this.clientId,
    required this.workoutSessionId,
    required this.workoutExerciseId,
    this.responseData,
  });

  final String clientId;
  final String workoutSessionId;
  final String workoutExerciseId;

  /// Cuerpo de la respuesta (la sesión actualizada), si lo hubo.
  final Object? responseData;
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

  /// Series que quedan pendientes para un reintento posterior.
  final int deferred;
  final bool offline;
}

class SyncService {
  SyncService({
    required AppDatabase database,
    required SetLogUploader uploader,
    required ConnectivitySource connectivity,
    required String? userId,
    DateTime Function()? clock,
    this.backoff = const BackoffPolicy(),
  }) : _db = database,
       _uploader = uploader,
       _connectivity = connectivity,
       _userId = userId,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final SetLogUploader _uploader;
  final ConnectivitySource _connectivity;
  final String? _userId;
  final DateTime Function() _clock;
  final BackoffPolicy backoff;

  final _synced = StreamController<SyncedSetLog>.broadcast();
  StreamSubscription<bool>? _connectivitySub;
  Timer? _retryTimer;
  Future<SyncReport>? _running;
  bool _runAgain = false;
  bool _disposed = false;

  Stream<SyncedSetLog> get synced => _synced.stream;

  $PendingSetLogsTable get _table => _db.pendingSetLogs;

  /// Recupera envíos interrumpidos, escucha la conectividad y lanza una
  /// primera pasada.
  Future<void> start() async {
    if (_userId == null || _disposed) return;
    await recoverInterrupted();
    _connectivitySub ??= _connectivity.onlineChanges.listen((online) {
      if (online) unawaited(syncNow());
    });
    unawaited(syncNow());
  }

  /// Encola una serie y dispara la sincronización. Devuelve la fila creada.
  Future<PendingSetLog> enqueue({
    required String clientId,
    required String workoutSessionId,
    required String workoutExerciseId,
    String? exerciseId,
    required int setIndex,
    int? reps,
    double? loadKg,
    int? rir,
    DateTime? completedAt,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('No se puede encolar una serie sin usuario.');
    }
    final now = _clock();
    final row = PendingSetLogsCompanion.insert(
      clientId: clientId,
      userId: userId,
      workoutSessionId: workoutSessionId,
      workoutExerciseId: workoutExerciseId,
      exerciseId: Value(exerciseId),
      setIndex: setIndex,
      reps: Value(reps),
      loadKg: Value(loadKg),
      rir: Value(rir),
      completedAt: completedAt ?? now,
      updatedAt: now,
    );
    final inserted = await _db.into(_table).insertReturning(row);
    unawaited(syncNow());
    return inserted;
  }

  /// Series del usuario aún no confirmadas por la API (cualquier estado).
  Stream<List<PendingSetLog>> watchQueue() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_table)
          ..where((t) => t.userId.equals(userId))
          ..orderBy(_order))
        .watch();
  }

  Future<List<PendingSetLog>> queue() {
    final userId = _userId;
    if (userId == null) return Future.value(const []);
    return (_db.select(_table)
          ..where((t) => t.userId.equals(userId))
          ..orderBy(_order))
        .get();
  }

  static final _order = <OrderClauseGenerator<$PendingSetLogsTable>>[
    (t) => OrderingTerm.asc(t.completedAt),
    (t) => OrderingTerm.asc(t.setIndex),
  ];

  /// `syncing` → `pending` (la app murió durante un envío).
  Future<void> recoverInterrupted() async {
    final userId = _userId;
    if (userId == null) return;
    await (_db.update(_table)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(PendingSetLogStatus.syncing),
        ))
        .write(
          PendingSetLogsCompanion(
            status: const Value(PendingSetLogStatus.pending),
            updatedAt: Value(_clock()),
          ),
        );
  }

  /// Vuelve a poner en cola las series `failed` (acción manual de la UI).
  Future<void> retryFailed() async {
    final userId = _userId;
    if (userId == null) return;
    await (_db.update(_table)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(PendingSetLogStatus.failed),
        ))
        .write(
          PendingSetLogsCompanion(
            status: const Value(PendingSetLogStatus.pending),
            attempts: const Value(0),
            nextAttemptAt: const Value(null),
            updatedAt: Value(_clock()),
          ),
        );
    unawaited(syncNow());
  }

  /// Ejecuta una pasada de sincronización. Si ya hay una en curso, se
  /// encadena otra al terminar y se devuelve la misma `Future`.
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

    final items =
        await (_db.select(_table)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.status.equalsValue(PendingSetLogStatus.pending),
              )
              ..orderBy(_order))
            .get();

    var sent = 0;
    var failed = 0;
    for (var i = 0; i < items.length; i++) {
      if (_disposed) break;
      final item = items[i];
      final now = _clock();
      final due = item.nextAttemptAt;
      if (due != null && due.isAfter(now)) {
        _scheduleRetry(due.difference(now));
        return SyncReport(
          sent: sent,
          failed: failed,
          deferred: items.length - i,
        );
      }

      await _setStatus(item.clientId, PendingSetLogStatus.syncing);
      final outcome = await _uploader.upload(item);

      switch (outcome) {
        case UploadSucceeded(:final responseData):
        case UploadDuplicate(:final responseData):
          await (_db.delete(
            _table,
          )..where((t) => t.clientId.equals(item.clientId))).go();
          sent++;
          if (!_synced.isClosed) {
            _synced.add(
              SyncedSetLog(
                clientId: item.clientId,
                workoutSessionId: item.workoutSessionId,
                workoutExerciseId: item.workoutExerciseId,
                responseData: responseData,
              ),
            );
          }
        case UploadPermanentFailure(:final reason):
          await _markFailed(item, reason);
          failed++;
        case UploadTransientFailure(:final reason):
          final attempts = item.attempts + 1;
          if (attempts >= backoff.maxAttempts) {
            await _markFailed(item, reason, attempts: attempts);
            failed++;
            continue;
          }
          final delay = backoff.delayFor(attempts);
          await (_db.update(
            _table,
          )..where((t) => t.clientId.equals(item.clientId))).write(
            PendingSetLogsCompanion(
              status: const Value(PendingSetLogStatus.pending),
              attempts: Value(attempts),
              lastError: Value(reason),
              nextAttemptAt: Value(_clock().add(delay)),
              updatedAt: Value(_clock()),
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
    return SyncReport(sent: sent, failed: failed);
  }

  Future<void> _setStatus(String clientId, PendingSetLogStatus status) {
    return (_db.update(
      _table,
    )..where((t) => t.clientId.equals(clientId))).write(
      PendingSetLogsCompanion(
        status: Value(status),
        updatedAt: Value(_clock()),
      ),
    );
  }

  Future<void> _markFailed(PendingSetLog item, String reason, {int? attempts}) {
    return (_db.update(
      _table,
    )..where((t) => t.clientId.equals(item.clientId))).write(
      PendingSetLogsCompanion(
        status: const Value(PendingSetLogStatus.failed),
        attempts: Value(attempts ?? item.attempts + 1),
        lastError: Value(reason),
        updatedAt: Value(_clock()),
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
    await _synced.close();
  }
}
