import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_client.dart';
import 'package:pipos_fitness/core/auth/session_providers.dart';
import 'package:pipos_fitness/core/auth/token_storage.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/core/offline/set_log_uploader.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/features/workouts/workout_session_provider.dart';

import '../../helpers/fake_http_adapter.dart';

Map<String, dynamic> sessionJson({
  List<Map<String, dynamic>> sets = const [],
}) => {
  'id': 'ws1',
  'userId': 'u1',
  'startedAt': '2026-01-01T10:00:00.000Z',
  'exercises': [
    {
      'id': 'we1',
      'workoutSessionId': 'ws1',
      'exerciseId': 'ex1',
      'order': 0,
      'sets': sets,
    },
  ],
};

Map<String, dynamic> setJson(String id, int index) => {
  'id': id,
  'workoutExerciseId': 'we1',
  'setIndex': index,
  'reps': 10,
  'weightKg': 60.0,
  'completed': true,
};

class _ServerUploader implements SetLogUploader {
  final sent = <String>[];

  @override
  Future<UploadOutcome> upload(PendingSetLog item) async {
    sent.add(item.clientId);
    return UploadSucceeded(
      sessionJson(sets: [setJson('server-${sent.length}', 0)]),
    );
  }
}

void main() {
  late AppDatabase db;
  late ManualConnectivitySource connectivity;
  late _ServerUploader uploader;
  late SyncService sync;
  late ProviderContainer container;
  late FakeHttpAdapter adapter;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = ManualConnectivitySource(online: false);
    uploader = _ServerUploader();
    sync = SyncService(
      database: db,
      uploader: uploader,
      connectivity: connectivity,
      userId: 'u1',
    );
    adapter = FakeHttpAdapter()
      ..reply('GET', '/workouts/ws1', 200, sessionJson());
    container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('http://api.test'),
        httpClientAdapterProvider.overrideWithValue(adapter),
        tokenStorageProvider.overrideWithValue(
          InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r'),
        ),
        syncServiceProvider.overrideWithValue(sync),
      ],
    );
    await container.read(workoutSessionProvider.notifier).resumeWorkout('ws1');
  });

  tearDown(() async {
    container.dispose();
    await sync.dispose();
    await connectivity.dispose();
    await db.close();
  });

  test(
    'logSet offline: escribe en la cola y actualiza la UI al instante',
    () async {
      final notifier = container.read(workoutSessionProvider.notifier);

      final ok = await notifier.logSet(
        workoutExerciseId: 'we1',
        weightKg: 60,
        reps: 10,
      );

      expect(ok, isTrue);
      final sets = container
          .read(workoutSessionProvider)
          .setsForExercise('we1');
      expect(sets, hasLength(1));
      expect(sets.single.reps, 10);
      final queue = await sync.queue();
      expect(
        queue.single.clientId,
        sets.single.id,
        reason: 'id optimista = clientId',
      );
      expect(queue.single.status, PendingSetLogStatus.pending);
      expect(uploader.sent, isEmpty);
      expect(notifier.pendingSetIds, {sets.single.id});
    },
  );

  test(
    'al volver la red se envía y la sesión del servidor reemplaza la local',
    () async {
      final notifier = container.read(workoutSessionProvider.notifier);
      await notifier.logSet(workoutExerciseId: 'we1', weightKg: 60, reps: 10);

      connectivity.online = true;
      await sync.syncNow();
      await Future<void>.delayed(Duration.zero);

      final sets = container
          .read(workoutSessionProvider)
          .setsForExercise('we1');
      expect(sets.single.id, 'server-1');
      expect(await sync.queue(), isEmpty);
      expect(notifier.pendingSetIds, isEmpty);
    },
  );

  test(
    'al reanudar tras reiniciar, las series pendientes siguen visibles',
    () async {
      await container
          .read(workoutSessionProvider.notifier)
          .logSet(workoutExerciseId: 'we1', reps: 5);

      // "Reinicio": nuevo contenedor/notifier, misma BD y SyncService.
      final fresh = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://api.test'),
          httpClientAdapterProvider.overrideWithValue(adapter),
          tokenStorageProvider.overrideWithValue(
            InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r'),
          ),
          syncServiceProvider.overrideWithValue(sync),
        ],
      );
      addTearDown(fresh.dispose);
      await fresh.read(workoutSessionProvider.notifier).resumeWorkout('ws1');

      final sets = fresh.read(workoutSessionProvider).setsForExercise('we1');
      expect(sets.single.reps, 5);
    },
  );
}
