import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/data/pipos_api.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/workout.dart';

import '../../helpers/fake_backend.dart';

const planSession = '00000000-0000-4000-8000-000000000020';
const planExercise = '00000000-0000-4000-8000-000000000030';
const exercise = '00000000-0000-4000-8000-000000000040';

/// Backend que falla las series con un error permanente.
class _RejectingBackend extends FakeBackend {
  @override
  Future<Upserted<SetLog>> upsertSet(
    String workoutId,
    UpsertSetRequest request,
  ) async => throw const ApiFailure(
    type: ApiFailureType.badRequest,
    message: 'bad',
    statusCode: 400,
    code: ApiErrorCode.validationFailed,
  );
}

void main() {
  late AppDatabase db;
  late ManualConnectivitySource connectivity;
  late FakeBackend backend;
  late DateTime now;
  late SyncService service;
  var ids = 0;

  SyncService build({FakeBackend? api}) => SyncService(
    database: db,
    api: api ?? backend,
    connectivity: connectivity,
    userId: 'user-1',
    clock: () => now,
    idGenerator: () =>
        '00000000-0000-4000-9000-${(++ids).toString().padLeft(12, '0')}',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = ManualConnectivitySource(online: false);
    backend = FakeBackend();
    now = DateTime.utc(2026, 11, 9, 8);
    service = build();
  });

  tearDown(() async {
    await service.dispose();
    await connectivity.dispose();
    await db.close();
  });

  Future<LocalSetLog> logOne({int index = 0}) async {
    final w = await service.startWorkout(planSessionId: planSession);
    return service.logSet(
      workoutClientId: w.clientId,
      planExerciseId: planExercise,
      exerciseId: exercise,
      setIndex: index,
      reps: 8,
      loadKg: 60,
      rir: 2,
    );
  }

  test(
    'sin red la serie queda en drift como pending; con red se envía una vez',
    () async {
      final set = await logOne();
      expect((await service.syncNow()).offline, isTrue);
      expect(
        (await service.setsOf(set.workoutClientId)).single.status,
        SetSyncStatus.pending,
      );
      expect(backend.sets, isEmpty);

      connectivity.online = true;
      final report = await service.syncNow();

      expect(report.sent, 2, reason: 'inicio del entrenamiento + serie');
      expect(backend.workouts, hasLength(1));
      expect(backend.sets.keys, [set.clientId]);
      expect(
        (await service.setsOf(set.workoutClientId)).single.status,
        SetSyncStatus.synced,
      );
      final w = await service.workoutByClientId(set.workoutClientId);
      expect(w!.serverId, 'srv-${set.workoutClientId}');
    },
  );

  test(
    'respuesta perdida → reintento con el mismo clientId → 200, sin duplicado',
    () async {
      connectivity.online = true;
      backend.loseNextSetResponse = true;
      final set = await logOne();
      await service.syncNow();

      final row = (await service.setsOf(set.workoutClientId)).single;
      expect(row.status, SetSyncStatus.pending);
      expect(row.attempts, 1);
      expect(row.nextAttemptAt, isNotNull);
      expect(backend.setsCreated, 1);

      now = now.add(const Duration(minutes: 1));
      await service.syncNow();

      expect(backend.sets, hasLength(1));
      expect(backend.setsReplayed, 1);
      expect(
        (await service.setsOf(set.workoutClientId)).single.status,
        SetSyncStatus.synced,
      );
    },
  );

  test(
    'una serie syncing huérfana (app muerta) vuelve a pending y se reenvía',
    () async {
      final set = await logOne();
      await (db.update(db.localSetLogs)).write(
        const LocalSetLogsCompanion(status: Value(SetSyncStatus.syncing)),
      );
      await service.recoverInterrupted();
      expect(
        (await service.setsOf(set.workoutClientId)).single.status,
        SetSyncStatus.pending,
      );
      connectivity.online = true;
      await service.syncNow();
      expect(backend.sets, hasLength(1));
    },
  );

  test(
    'error permanente → failed; retryFailed la vuelve a poner en cola',
    () async {
      await service.dispose();
      final rejecting = _RejectingBackend();
      service = build(api: rejecting);
      connectivity.online = true;
      final set = await logOne();
      await service.syncNow();
      final row = (await service.setsOf(set.workoutClientId)).single;
      expect(row.status, SetSyncStatus.failed);
      expect(row.lastError, ApiErrorCode.validationFailed);

      final summary = await service.watchSummary().first;
      expect(summary.failed, 1);

      await service.retryFailed();
      expect(
        (await service.setsOf(set.workoutClientId)).single.attempts,
        anyOf(0, 1),
      );
    },
  );

  test('el finish se envía después de todas las series', () async {
    final set = await logOne();
    await logOne(index: 1);
    await service.finishWorkout(set.workoutClientId);
    connectivity.online = true;
    await service.syncNow();
    expect(backend.sets, hasLength(2));
    expect(backend.finishes, 1);
    final w = await service.workoutByClientId(set.workoutClientId);
    expect(w!.finishSynced, isTrue);
    // Reenviar no vuelve a terminarlo.
    await service.syncNow();
    expect(backend.finishes, 1);
  });

  test(
    'una serie failed bloquea el finish (no se pierde) y se reintenta antes',
    () async {
      connectivity.online = true;
      var reject = true;
      backend.setFailure = (r) => reject
          ? const ApiFailure(
              type: ApiFailureType.badRequest,
              message: 'bad',
              statusCode: 422,
              code: ApiErrorCode.validationFailed,
            )
          : null;
      final first = await logOne();
      await service.syncNow();
      expect(
        (await service.setsOf(first.workoutClientId)).single.status,
        SetSyncStatus.failed,
      );
      reject = false;
      await logOne(index: 1);
      await service.syncNow();
      expect(await service.unsyncedCount(first.workoutClientId), 1);

      // Mientras la serie siga fallando, el finish NO se envía.
      reject = true;
      await service.finishWorkout(first.workoutClientId);
      await service.syncNow();
      expect(backend.finishCalls, 0);
      expect(
        (await service.workoutByClientId(first.workoutClientId))!.finishSynced,
        isFalse,
      );

      // Al terminar de nuevo se reintenta la fallida ANTES del finish.
      reject = false;
      await service.finishWorkout(first.workoutClientId);
      await service.syncNow();
      expect(backend.sets.keys, contains(first.clientId));
      expect(backend.sets, hasLength(2));
      expect(backend.finishes, 1);
      expect(await service.unsyncedCount(first.workoutClientId), 0);
    },
  );

  test('finish con error transitorio: backoff con attempts, no cada 2 s '
      'sin límite', () async {
    connectivity.online = true;
    final set = await logOne();
    await service.syncNow();
    backend.finishFailures.addAll([
      const ApiFailure(
        type: ApiFailureType.server,
        message: '503',
        statusCode: 503,
      ),
      const ApiFailure(
        type: ApiFailureType.server,
        message: '503',
        statusCode: 503,
      ),
    ]);
    await service.finishWorkout(set.workoutClientId);
    await service.syncNow();
    expect(backend.finishCalls, 1);
    var w = (await service.workoutByClientId(set.workoutClientId))!;
    expect(w.attempts, 1);
    expect(w.nextAttemptAt!.toUtc(), now.add(service.backoff.delayFor(1)));

    // Antes de su hora no se reintenta.
    await service.syncNow();
    expect(backend.finishCalls, 1);

    now = now.add(const Duration(seconds: 3));
    await service.syncNow();
    expect(backend.finishCalls, 2);
    w = (await service.workoutByClientId(set.workoutClientId))!;
    expect(w.attempts, 2);
    expect(w.nextAttemptAt!.toUtc(), now.add(service.backoff.delayFor(2)));

    now = now.add(const Duration(minutes: 1));
    await service.syncNow();
    expect(backend.finishes, 1);
    expect(
      (await service.workoutByClientId(set.workoutClientId))!.finishSynced,
      isTrue,
    );
  });

  test('finish agotando reintentos queda parado hasta retryFailed', () async {
    await service.dispose();
    service = SyncService(
      database: db,
      api: backend,
      connectivity: connectivity,
      userId: 'user-1',
      clock: () => now,
      backoff: const BackoffPolicy(maxAttempts: 2),
    );
    connectivity.online = true;
    final set = await logOne();
    await service.syncNow();
    for (var i = 0; i < 3; i++) {
      backend.finishFailures.add(
        const ApiFailure(type: ApiFailureType.network, message: 'off'),
      );
    }
    await service.finishWorkout(set.workoutClientId);
    await service.syncNow();
    now = now.add(const Duration(minutes: 10));
    await service.syncNow();
    expect(backend.finishCalls, 2);
    now = now.add(const Duration(minutes: 10));
    await service.syncNow();
    expect(backend.finishCalls, 2, reason: 'agotado: no se reintenta solo');
    backend.finishFailures.clear();
    await service.retryFailed();
    await service.syncNow();
    expect(backend.finishes, 1);
  });

  test(
    'adoptar el entrenamiento en curso de la API reutiliza su clientId',
    () async {
      final adopted = await service.startWorkout(
        planSessionId: planSession,
        adopt: TodayWorkoutRef(
          id: 'srv-x',
          clientId: 'client-x',
          status: WorkoutStatus.inProgress,
          startedAt: now,
        ),
      );
      expect(adopted.clientId, 'client-x');
      expect(adopted.serverId, 'srv-x');
      final again = await service.startWorkout(planSessionId: planSession);
      expect(again.clientId, 'client-x');
    },
  );

  test('dos confirmaciones casi simultáneas crean UN solo entrenamiento '
      'local', () async {
    final results = await Future.wait([
      service.startWorkout(planSessionId: planSession),
      service.startWorkout(planSessionId: planSession),
      service.startWorkout(planSessionId: planSession),
    ]);
    expect(results.map((w) => w.clientId).toSet(), hasLength(1));
    expect(await db.select(db.localWorkouts).get(), hasLength(1));
  });

  test('BackoffPolicy: exponencial y acotado', () {
    const p = BackoffPolicy(
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 10),
    );
    expect(p.delayFor(1), const Duration(seconds: 2));
    expect(p.delayFor(2), const Duration(seconds: 4));
    expect(p.delayFor(3), const Duration(seconds: 8));
    expect(p.delayFor(4), const Duration(seconds: 10));
  });
}
