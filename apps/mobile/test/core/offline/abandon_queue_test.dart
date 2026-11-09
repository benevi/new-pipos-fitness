// Abandonar entrenamientos (issue #13 de la API): por la cola, sin red, y
// el abandono automático del servidor (> 12 h sin actividad).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/models/enums.dart';

import '../../helpers/fake_backend.dart';

const planSession = '00000000-0000-4000-8000-000000000020';
const planExercise = '00000000-0000-4000-8000-000000000030';
const exercise = '00000000-0000-4000-8000-000000000040';

void main() {
  late AppDatabase db;
  late ManualConnectivitySource connectivity;
  late FakeBackend backend;
  late DateTime now;
  late SyncService service;
  var ids = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = ManualConnectivitySource(online: false);
    backend = FakeBackend();
    now = DateTime.utc(2026, 11, 9, 8);
    service = SyncService(
      database: db,
      api: backend,
      connectivity: connectivity,
      userId: 'user-1',
      clock: () => now,
      idGenerator: () =>
          '00000000-0000-4000-9000-${(++ids).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() async {
    await service.dispose();
    await connectivity.dispose();
    await db.close();
  });

  Future<LocalSetLog> logOne(String workout, {int index = 0}) => service.logSet(
    workoutClientId: workout,
    planExerciseId: planExercise,
    exerciseId: exercise,
    setIndex: index,
    reps: 8,
    loadKg: 60,
  );

  test(
    'abandonar sin red: se cierra en local, las series sin confirmar se '
    'descartan y al volver la red se envía POST /abandon (no finish)',
    () async {
      connectivity.online = true;
      final w = await service.startWorkout(planSessionId: planSession);
      final confirmed = await logOne(w.clientId);
      await service.syncNow();
      connectivity.online = false;
      await logOne(w.clientId, index: 1);

      await service.abandonWorkout(w.clientId);
      expect(await service.openWorkoutFor(planSession), isNull);
      expect((await service.setsOf(w.clientId)).map((s) => s.clientId), [
        confirmed.clientId,
      ]);

      connectivity.online = true;
      await service.syncNow();
      final serverId = 'srv-${w.clientId}';
      expect(backend.calls, contains('POST /workouts/$serverId/abandon'));
      expect(backend.finishCalls, 0);
      expect(backend.workouts[w.clientId]!.status, WorkoutStatus.abandoned);
      final local = (await service.workoutByClientId(w.clientId))!;
      expect(local.abandoned, isTrue);
      expect(local.finishSynced, isTrue);

      // Idempotente: reenviar no rompe nada.
      await service.syncNow();
      expect(backend.abandons, 1);
    },
  );

  test(
    'abandonar uno que nunca llegó al servidor lo borra sin peticiones',
    () async {
      final w = await service.startWorkout(planSessionId: planSession);
      await logOne(w.clientId);
      await service.abandonWorkout(w.clientId);
      expect(await service.workoutByClientId(w.clientId), isNull);
      connectivity.online = true;
      await service.syncNow();
      expect(backend.calls, isEmpty);
    },
  );

  test('si ya estaba terminado en el servidor (409 WORKOUT_FINISHED), el '
      'abandono se da por cerrado', () async {
    connectivity.online = true;
    final w = await service.startWorkout(planSessionId: planSession);
    await service.syncNow();
    await backend.finishWorkout('srv-${w.clientId}', now);
    await service.abandonWorkout(w.clientId);
    await service.syncNow();
    final local = (await service.workoutByClientId(w.clientId))!;
    expect(local.finishSynced, isTrue);
    expect(local.attempts, lessThan(service.backoff.maxAttempts));
  });

  test('abandonado solo por el servidor: la serie nueva recibe 409 '
      'WORKOUT_FINISHED → se cierra en local, sin reintentos ni bloquear la '
      'cola, con aviso; lo siguiente va a un entrenamiento nuevo', () async {
    connectivity.online = true;
    final w = await service.startWorkout(planSessionId: planSession);
    await logOne(w.clientId);
    await service.syncNow();
    backend.autoAbandon('srv-${w.clientId}');

    final late = await logOne(w.clientId, index: 1);
    await service.syncNow();

    final local = (await service.workoutByClientId(w.clientId))!;
    expect(local.finishedAt, isNotNull);
    expect(local.finishSynced, isTrue);
    expect(local.abandoned, isTrue);
    expect(await service.unsyncedCount(w.clientId), 0);
    final row = (await service.setsOf(
      w.clientId,
    )).firstWhere((s) => s.clientId == late.clientId);
    expect(row.lastError, ApiErrorCode.workoutFinished);
    expect(row.confirmed, isFalse);
    expect(
      (await service.watchClosedRemotely().first).single.clientId,
      w.clientId,
    );

    // Sin reintentos.
    final calls = backend.calls.length;
    await service.syncNow();
    expect(backend.calls.length, calls);

    await service.dismissClosedNotice(w.clientId);
    expect(await service.watchClosedRemotely().first, isEmpty);
    final next = await service.startWorkout(planSessionId: planSession);
    expect(next.clientId, isNot(w.clientId));
  });

  test(
    'un entrenamiento abierto y sin actividad desde hace más de 12 h se '
    'cierra como abandonado al empezar otro (como hará el servidor)',
    () async {
      connectivity.online = true;
      final w = await service.startWorkout(planSessionId: planSession);
      await logOne(w.clientId);
      await service.syncNow();

      now = now.add(const Duration(hours: 13));
      final next = await service.startWorkout(planSessionId: planSession);
      expect(next.clientId, isNot(w.clientId));
      await service.syncNow();
      expect(backend.workouts[w.clientId]!.status, WorkoutStatus.abandoned);
      expect(
        (await service.workoutByClientId(w.clientId))!.finishSynced,
        isTrue,
      );
    },
  );
}
