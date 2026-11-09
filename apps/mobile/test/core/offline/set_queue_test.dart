// Cola de series: descartar una rechazada (#21), editar y borrar (#22).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';

import '../../helpers/fake_backend.dart';

const planSession = '00000000-0000-4000-8000-000000000020';
const planExercise = '00000000-0000-4000-8000-000000000030';
const exercise = '00000000-0000-4000-8000-000000000040';

const _rejected = ApiFailure(
  type: ApiFailureType.badRequest,
  message: 'bad',
  statusCode: 400,
  code: ApiErrorCode.validationFailed,
);

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
      backoff: const BackoffPolicy(maxAttempts: 2),
      idGenerator: () =>
          '00000000-0000-4000-9000-${(++ids).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() async {
    await service.dispose();
    await connectivity.dispose();
    await db.close();
  });

  Future<LocalSetLog> logOne({int index = 0, int reps = 8}) async {
    final w = await service.startWorkout(planSessionId: planSession);
    return service.logSet(
      workoutClientId: w.clientId,
      planExerciseId: planExercise,
      exerciseId: exercise,
      setIndex: index,
      reps: reps,
      loadKg: 60,
      rir: 2,
    );
  }

  Future<List<LocalSetLog>> rows(String workoutClientId) =>
      service.setsOf(workoutClientId);

  group('#21 descartar una serie rechazada', () {
    test('rechazo 400: queda failed con el motivo y bloquea el finish; '
        'descartarla la quita sin DELETE y el finish sale', () async {
      connectivity.online = true;
      backend.setFailure = (r) => r.setIndex == 0 ? _rejected : null;
      final bad = await logOne();
      await logOne(index: 1);
      await service.syncNow();

      final failed = (await rows(bad.workoutClientId)).first;
      expect(failed.status, SetSyncStatus.failed);
      expect(failed.lastError, ApiErrorCode.validationFailed);
      expect(SyncService.mayBeOnServer(failed), isFalse);

      // Terminar la vuelve a poner en cola, la API la rechaza otra vez y el
      // finish no se envía.
      await service.finishWorkout(bad.workoutClientId);
      await service.syncNow();
      expect(backend.finishCalls, 0);

      await service.deleteSet(bad.clientId);
      await service.syncNow();

      expect(
        (await rows(bad.workoutClientId)).map((s) => s.clientId),
        isNot(contains(bad.clientId)),
      );
      expect(backend.deletedSets, isEmpty);
      expect(
        backend.calls.where((c) => c.startsWith('DELETE')),
        isEmpty,
        reason: 'la API nunca la guardó',
      );
      expect(backend.finishes, 1);
      expect(await service.unsyncedCount(bad.workoutClientId), 0);
    });

    test(
      'serie que pudo llegar al servidor (reintentos agotados): '
      'descartarla deja una lápida y envía DELETE (404 también vale)',
      () async {
        connectivity.online = true;
        backend.setFailure = (_) => const ApiFailure(
          type: ApiFailureType.server,
          message: '503',
          statusCode: 503,
        );
        final set = await logOne();
        await service.syncNow();
        now = now.add(const Duration(minutes: 1));
        await service.syncNow();
        final failed = (await rows(set.workoutClientId)).single;
        expect(failed.status, SetSyncStatus.failed);
        expect(SyncService.mayBeOnServer(failed), isTrue);

        connectivity.online = false;
        await service.deleteSet(set.clientId);
        final tomb = (await rows(set.workoutClientId)).single;
        expect(tomb.deleted, isTrue);
        expect(tomb.status, SetSyncStatus.pending);

        connectivity.online = true;
        await service.syncNow();
        expect(
          backend.calls,
          contains(
            'DELETE /workouts/srv-${set.workoutClientId}/sets/${set.clientId}',
          ),
        );
        expect(await rows(set.workoutClientId), isEmpty);
      },
    );

    test('una serie confirmada se borra en la API con DELETE', () async {
      connectivity.online = true;
      final set = await logOne();
      await service.syncNow();
      expect((await rows(set.workoutClientId)).single.confirmed, isTrue);

      await service.deleteSet(set.clientId);
      await service.syncNow();
      expect(backend.deletedSets, [set.clientId]);
      expect(backend.sets[set.clientId]!.deletedAt, isNotNull);
      expect(await rows(set.workoutClientId), isEmpty);
    });

    test(
      'sin entrenamiento en el servidor la serie se borra sin más',
      () async {
        final set = await logOne();
        await service.deleteSet(set.clientId);
        expect(await rows(set.workoutClientId), isEmpty);
        connectivity.online = true;
        await service.syncNow();
        expect(backend.sets, isEmpty);
      },
    );
  });
}
