// Cola de series: descartar una rechazada (#21), editar y borrar (#22).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/models/workout.dart';

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

  /// Lápida confirmada: oculta la serie (también la copia de la API).
  void expectSyncedTombstone(List<LocalSetLog> r) {
    expect(r.single.deleted, isTrue);
    expect(r.single.status, SetSyncStatus.synced);
  }

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
        expectSyncedTombstone(await rows(set.workoutClientId));
        expect(await service.unsyncedCount(set.workoutClientId), 0);
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
      expectSyncedTombstone(await rows(set.workoutClientId));
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

  group('#22 editar y borrar una serie registrada', () {
    test('editar una serie aún no enviada se funde con su creación: '
        'un solo POST con los valores nuevos, sin PATCH', () async {
      final set = await logOne();
      now = now.add(const Duration(seconds: 30));
      await service.updateSet(set.clientId, reps: 10, loadKg: 62.5, rir: 1);
      final row = (await rows(set.workoutClientId)).single;
      expect(row.reps, 10);
      expect(row.status, SetSyncStatus.pending);

      connectivity.online = true;
      await service.syncNow();
      final sent = backend.sets[set.clientId]!;
      expect(sent.reps, 10);
      expect(sent.loadKg, 62.5);
      expect(sent.rir, 1);
      expect(sent.clientUpdatedAt.isAtSameMomentAs(now), isTrue);
      expect(backend.setsCreated, 1);
      expect(backend.patches, isEmpty);
    });

    test('editar sin red una serie ya sincronizada: la UI la ve al momento '
        'y al volver la red se envía PATCH con clientUpdatedAt', () async {
      connectivity.online = true;
      final set = await logOne();
      await service.syncNow();
      expect(backend.sets[set.clientId]!.reps, 8);

      connectivity.online = false;
      now = now.add(const Duration(minutes: 3));
      await service.updateSet(set.clientId, reps: 6, loadKg: 57.5, rir: 0);
      var row = (await rows(set.workoutClientId)).single;
      expect((row.reps, row.loadKg, row.rir), (6, 57.5, 0));
      expect(row.status, SetSyncStatus.pending);
      expect(row.confirmed, isTrue);

      connectivity.online = true;
      await service.syncNow();
      final patch = backend.patches.single;
      expect(patch.clientId, set.clientId);
      expect(patch.request.clientUpdatedAt.isAtSameMomentAs(now), isTrue);
      expect(backend.sets[set.clientId]!.reps, 6);
      expect(backend.sets[set.clientId]!.loadKg, 57.5);
      expect(backend.setsCreated, 1, reason: 'sin POST de nuevo');
      row = (await rows(set.workoutClientId)).single;
      expect(row.status, SetSyncStatus.synced);
    });

    test('respuesta perdida y edición antes del reintento: el reenvío da 200 '
        'con los valores viejos y se corrige con PATCH', () async {
      connectivity.online = true;
      backend.loseNextSetResponse = true;
      final set = await logOne();
      await service.syncNow();
      expect(backend.setsCreated, 1);

      now = now.add(const Duration(minutes: 1));
      await service.updateSet(set.clientId, reps: 12, loadKg: 60, rir: 3);
      await service.syncNow();
      expect(backend.setsReplayed, 1);
      expect(backend.patches, hasLength(1));
      expect(backend.sets[set.clientId]!.reps, 12);
      expect(
        (await rows(set.workoutClientId)).single.status,
        SetSyncStatus.synced,
      );
    });

    test('gana la última escritura: si el servidor tiene una edición más '
        'reciente, la fila local la adopta', () async {
      connectivity.online = true;
      final set = await logOne();
      await service.syncNow();
      // Otro dispositivo la corrige más tarde.
      backend.sets[set.clientId] = SetLog.fromJson({
        ...backend.sets[set.clientId]!.toJson(),
        'reps': 9,
        'clientUpdatedAt': '2026-11-09T09:00:00.000Z',
      });
      now = now.add(const Duration(minutes: 5));
      await service.updateSet(set.clientId, reps: 7, loadKg: 60, rir: 2);
      await service.syncNow();
      final row = (await rows(set.workoutClientId)).single;
      expect(row.reps, 9);
      expect(row.status, SetSyncStatus.synced);
      expect(backend.sets[set.clientId]!.reps, 9);
    });

    test('borrar sin red una serie sincronizada: se oculta al momento y al '
        'volver la red se envía DELETE', () async {
      connectivity.online = true;
      final set = await logOne();
      await service.syncNow();
      connectivity.online = false;
      await service.deleteSet(set.clientId);
      expect((await rows(set.workoutClientId)).single.deleted, isTrue);
      expect(await service.unsyncedCount(set.workoutClientId), 1);

      connectivity.online = true;
      await service.syncNow();
      expect(backend.deletedSets, [set.clientId]);
      expectSyncedTombstone(await rows(set.workoutClientId));
    });

    test('una serie que solo está en la API se adopta para editarla', () async {
      connectivity.online = true;
      final w = await service.startWorkout(planSessionId: planSession);
      await service.syncNow();
      final serverId = (await service.workoutByClientId(w.clientId))!.serverId!;
      final remote = (await backend.upsertSet(
        serverId,
        UpsertSetRequest(
          clientId: '00000000-0000-4000-9999-000000000001',
          planExerciseId: planExercise,
          exerciseId: exercise,
          setIndex: 0,
          reps: 5,
          loadKg: 80,
          rir: 2,
          isWarmup: false,
          completedAt: now,
        ),
      )).value;
      await service.adoptServerSet(w.clientId, remote);
      await service.adoptServerSet(w.clientId, remote); // idempotente
      now = now.add(const Duration(minutes: 1));
      await service.updateSet(remote.clientId, reps: 6, loadKg: 80, rir: 1);
      await service.syncNow();
      expect(backend.patches.single.request.reps, 6);
      expect(backend.sets[remote.clientId]!.reps, 6);
    });
  });
}
