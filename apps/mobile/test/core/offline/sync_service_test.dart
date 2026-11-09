import 'dart:async';

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

class _BrokenConnectivity extends ManualConnectivitySource {
  _BrokenConnectivity() : super(online: true);

  @override
  Future<bool> isOnline() async => throw StateError('plugin roto');
}

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

  test('409 WORKOUT_IN_PROGRESS de la MISMA sesión: adopta el remoto y '
      'envía allí las series', () async {
    final remote = backend.seedInProgress(
      clientId: 'other-device',
      planSessionId: planSession,
      startedAt: now,
    );
    final set = await logOne();
    connectivity.online = true;
    await service.syncNow();

    final w = (await service.workoutByClientId(set.workoutClientId))!;
    expect(w.serverId, remote.id);
    expect(w.lastError, isNull);
    expect(backend.sets[set.clientId]!.workoutId, remote.id);
    expect(
      (await service.setsOf(set.workoutClientId)).single.status,
      SetSyncStatus.synced,
    );
  });

  test('409 WORKOUT_IN_PROGRESS de OTRA sesión: conflicto visible, series '
      'failed (no pending para siempre) y se puede descartar', () async {
    final remote = backend.seedInProgress(
      clientId: 'other-device',
      planSessionId: '00000000-0000-4000-8000-000000000099',
      startedAt: now,
    );
    final set = await logOne();
    connectivity.online = true;
    await service.syncNow();

    final conflicts = await service.watchConflictingWorkouts().first;
    expect(conflicts.single.clientId, set.workoutClientId);
    expect(
      (await service.setsOf(set.workoutClientId)).single.status,
      SetSyncStatus.failed,
    );
    // Una serie registrada después tampoco queda pendiente para siempre.
    final later = await logOne(index: 1);
    await service.syncNow();
    expect(
      (await service.setsOf(later.workoutClientId)).last.status,
      SetSyncStatus.failed,
    );

    // Tras terminar el otro, «Reintentar» lo arranca y envía las series.
    backend.workouts[remote.clientId] = (await backend.finishWorkout(
      remote.id,
      now,
    ));
    await service.retryFailed();
    await service.syncNow();
    expect(await service.watchConflictingWorkouts().first, isEmpty);
    expect(backend.sets, hasLength(2));

    // Descartar borra el entrenamiento local y sus series.
    await service.discardWorkout(set.workoutClientId);
    expect(await service.workoutByClientId(set.workoutClientId), isNull);
    expect(await service.setsOf(set.workoutClientId), isEmpty);
  });

  test('#25 dos inicios encolados de la misma sesión: el segundo adopta '
      'el primero (409) y se fusiona en él, sin dos locales con el mismo id '
      'remoto', () async {
    // Sin red: se empieza, se termina en local y se vuelve a empezar la
    // misma sesión (dos entrenamientos locales sin id de la API).
    final a = await service.startWorkout(planSessionId: planSession);
    final a1 = await service.logSet(
      workoutClientId: a.clientId,
      planExerciseId: planExercise,
      exerciseId: exercise,
      setIndex: 0,
      reps: 8,
      loadKg: 60,
    );
    await service.finishWorkout(a.clientId);
    now = now.add(const Duration(minutes: 1));
    final b = await service.startWorkout(planSessionId: planSession);
    expect(b.clientId, isNot(a.clientId));
    final b1 = await service.logSet(
      workoutClientId: b.clientId,
      planExerciseId: planExercise,
      exerciseId: exercise,
      setIndex: 1,
      reps: 7,
      loadKg: 60,
    );

    connectivity.online = true;
    await service.syncNow();

    // El primero crea el entrenamiento; el segundo recibe 409, adopta el
    // remoto (misma sesión) y se fusiona en el primero.
    expect(backend.workouts, hasLength(1));
    final remoteId = 'srv-${a.clientId}';
    final locals = await db.select(db.localWorkouts).get();
    expect(locals, hasLength(1));
    expect(locals.single.clientId, a.clientId);
    expect(locals.single.serverId, remoteId);
    expect(
      locals.single.finishedAt,
      isNull,
      reason: 'la persona seguía entrenando en el segundo',
    );
    final sets = await service.setsOf(a.clientId);
    expect(sets.map((s) => s.clientId), [a1.clientId, b1.clientId]);
    expect(sets.every((s) => s.status == SetSyncStatus.synced), isTrue);
    expect(backend.sets.values.map((s) => s.workoutId).toSet(), {remoteId});
    expect(backend.finishCalls, 0);

    // Al terminar se cierra el único entrenamiento remoto.
    await service.finishWorkout(a.clientId);
    await service.syncNow();
    expect(backend.finishes, 1);
  });

  test('#25 adoptar desde Hoy un remoto ya enlazado a otro local fusiona '
      'el duplicado', () async {
    connectivity.online = true;
    final a = await service.startWorkout(planSessionId: planSession);
    await service.syncNow();
    final remote = (await service.workoutByClientId(a.clientId))!.serverId!;

    // Un segundo local de la misma sesión sin id de la API (p. ej. creado
    // antes de que llegara la adopción) se enlaza al mismo remoto.
    await db
        .into(db.localWorkouts)
        .insert(
          LocalWorkoutsCompanion.insert(
            clientId: 'dup-local',
            userId: 'user-1',
            planSessionId: planSession,
            startedAt: now.add(const Duration(minutes: 1)),
          ),
        );
    await service.logSet(
      workoutClientId: 'dup-local',
      planExerciseId: planExercise,
      exerciseId: exercise,
      setIndex: 0,
      reps: 5,
      loadKg: 50,
    );
    final kept = await service.startWorkout(
      planSessionId: planSession,
      adopt: TodayWorkoutRef(
        id: remote,
        clientId: 'dup-local',
        status: WorkoutStatus.inProgress,
        startedAt: now,
      ),
    );
    expect(kept.clientId, a.clientId);
    expect(await db.select(db.localWorkouts).get(), hasLength(1));
    expect(await service.setsOf(a.clientId), hasLength(1));
  });

  group('409 PLAN_SESSION_OUTDATED (el plan cambió con el inicio en cola)', () {
    const oldSession = '00000000-0000-4000-8000-000000000098';

    test('sin series: relee /sessions/today y reintenta con la sesión '
        'vigente y el MISMO clientId', () async {
      backend.outdatedPlanSessions.add(oldSession);
      final w = await service.startWorkout(planSessionId: oldSession);
      var outdated = 0;
      final sub = service.planOutdated.listen((_) => outdated++);
      connectivity.online = true;
      await service.syncNow();
      await sub.cancel();

      expect(backend.startRequests.map((r) => r.clientId).toSet(), {
        w.clientId,
      });
      expect(backend.startRequests.map((r) => r.planSessionId), [
        oldSession,
        planSession,
      ]);
      final local = (await service.workoutByClientId(w.clientId))!;
      expect(local.planSessionId, planSession);
      expect(local.serverId, 'srv-${w.clientId}');
      expect(local.lastError, isNull);
      expect(outdated, greaterThan(0), reason: 'la UI relee la sesión');
    });

    test('con series: no se reintenta ni bloquea la cola; queda en conflicto '
        'con su motivo para descartarlo o conservarlo', () async {
      backend.outdatedPlanSessions.add(oldSession);
      final w = await service.startWorkout(planSessionId: oldSession);
      final set = await service.logSet(
        workoutClientId: w.clientId,
        planExerciseId: planExercise,
        exerciseId: exercise,
        setIndex: 0,
        reps: 8,
        loadKg: 60,
      );
      connectivity.online = true;
      await service.syncNow();

      expect(backend.startRequests, hasLength(1));
      final conflict = (await service.watchConflictingWorkouts().first).single;
      expect(conflict.clientId, w.clientId);
      expect(conflict.lastError, ApiErrorCode.planSessionOutdated);
      final row = (await service.setsOf(w.clientId)).single;
      expect(row.clientId, set.clientId);
      expect(row.status, SetSyncStatus.failed);
      expect(row.lastError, ApiErrorCode.planSessionOutdated);

      // Se conserva hasta que la persona decide; descartarlo lo quita.
      await service.syncNow();
      expect(await service.workoutByClientId(w.clientId), isNotNull);
      await service.discardWorkout(w.clientId);
      expect(await service.watchConflictingWorkouts().first, isEmpty);
    });
  });

  test('los syncNow lanzados sin esperar capturan y reportan el error '
      '(no hay error no manejado)', () async {
    final broken = _BrokenConnectivity();
    final reported = <Object>[];
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      final s = SyncService(
        database: db,
        api: backend,
        connectivity: broken,
        userId: 'user-1',
        clock: () => now,
        onError: (e, _) => reported.add(e),
      );
      await s.start();
      await s.startWorkout(planSessionId: planSession);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await s.dispose();
    }, (e, _) => uncaught.add(e));
    await broken.dispose();
    expect(uncaught, isEmpty);
    expect(reported, isNotEmpty);
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
