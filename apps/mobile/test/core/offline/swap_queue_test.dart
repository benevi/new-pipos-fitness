// #23: cambiar de ejercicio sin conexión. La sustitución va a la cola y se
// envía EN ORDEN con las series: antes que las del sustituto (la API las
// rechazaría sin ella) y después de las registradas antes del cambio.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/models/workout.dart';

import '../../helpers/fake_backend.dart';

const planSession = '00000000-0000-4000-8000-000000000020';
const slot = '00000000-0000-4000-8000-000000000030';
const squat = ExerciseRef(
  id: '00000000-0000-4000-8000-000000000040',
  slug: 'squat',
  nameEs: 'Sentadilla trasera',
);
const legPress = ExerciseRef(
  id: '00000000-0000-4000-8000-000000000044',
  slug: 'leg-press',
  nameEs: 'Prensa de piernas',
);
const goblet = ExerciseRef(
  id: '00000000-0000-4000-8000-000000000041',
  slug: 'goblet-squat',
  nameEs: 'Sentadilla goblet',
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
    backend = FakeBackend()..enforceSlotExercise = true;
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

  Future<LocalSetLog> log(String workout, ExerciseRef e, int index) async {
    final set = await service.logSet(
      workoutClientId: workout,
      planExerciseId: slot,
      exerciseId: e.id,
      setIndex: index,
      reps: 8,
      loadKg: 60,
    );
    now = now.add(const Duration(minutes: 2));
    return set;
  }

  Future<void> swap(String workout, ExerciseRef to) async {
    await service.enqueueSubstitution(
      workoutClientId: workout,
      planExerciseId: slot,
      exercise: to,
      substitutedFrom: squat,
    );
    now = now.add(const Duration(minutes: 2));
  }

  /// Llamadas de escritura a la API, en orden y sin ids.
  List<String> writes() => [
    for (final c in backend.calls)
      if (c.startsWith('POST /workouts/') && c.endsWith('/sets'))
        'set'
      else if (c.endsWith('/substitute'))
        'swap'
      else if (c == 'POST /workouts')
        'start',
  ];

  String exerciseOf(LocalSetLog s) => backend.sets[s.clientId]!.exerciseId;

  test('sin red: serie del original, cambio y serie del sustituto → al '
      'volver la red salen en ese orden y la API acepta todo', () async {
    final w = await service.startWorkout(planSessionId: planSession);
    final a = await log(w.clientId, squat, 0);
    await swap(w.clientId, legPress);
    final b = await log(w.clientId, legPress, 1);

    expect((await service.watchSwaps().first).single.exercise.id, legPress.id);

    connectivity.online = true;
    await service.syncNow();

    expect(writes(), ['start', 'set', 'swap', 'set']);
    expect(exerciseOf(a), squat.id);
    expect(exerciseOf(b), legPress.id);
    expect(backend.substitutions.single.exerciseId, legPress.id);
    expect(await service.watchSwaps().first, isEmpty);
    expect(await service.unsyncedCount(w.clientId), 0);
  });

  test('dos cambios seguidos (A→B, serie, B→C, serie): cada serie va '
      'después de su cambio y antes del siguiente', () async {
    final w = await service.startWorkout(planSessionId: planSession);
    await swap(w.clientId, legPress);
    final b = await log(w.clientId, legPress, 0);
    await swap(w.clientId, goblet);
    final c = await log(w.clientId, goblet, 1);

    connectivity.online = true;
    await service.syncNow();

    expect(writes(), ['start', 'swap', 'set', 'swap', 'set']);
    expect(exerciseOf(b), legPress.id);
    expect(exerciseOf(c), goblet.id);
    expect(await service.unsyncedCount(w.clientId), 0);
  });

  test('cambio y serie en el mismo segundo: primero el cambio', () async {
    final w = await service.startWorkout(planSessionId: planSession);
    await service.enqueueSubstitution(
      workoutClientId: w.clientId,
      planExerciseId: slot,
      exercise: legPress,
      substitutedFrom: squat,
    );
    final b = await service.logSet(
      workoutClientId: w.clientId,
      planExerciseId: slot,
      exerciseId: legPress.id,
      setIndex: 0,
      reps: 8,
      loadKg: 60,
    );
    connectivity.online = true;
    await service.syncNow();
    expect(writes(), ['start', 'swap', 'set']);
    expect(exerciseOf(b), legPress.id);
  });

  test('si el cambio falla de forma transitoria, las series posteriores '
      'esperan (no se envían antes) y salen tras el reintento', () async {
    final w = await service.startWorkout(planSessionId: planSession);
    await swap(w.clientId, legPress);
    final b = await log(w.clientId, legPress, 0);
    backend.substituteFailures.add(
      const ApiFailure(
        type: ApiFailureType.server,
        message: '503',
        statusCode: 503,
      ),
    );

    connectivity.online = true;
    await service.syncNow();
    expect(writes(), ['start', 'swap']);
    expect(backend.sets, isEmpty, reason: 'la serie espera al cambio');
    expect(
      (await service.setsOf(w.clientId)).single.status,
      SetSyncStatus.pending,
    );

    now = now.add(const Duration(minutes: 1));
    await service.syncNow();
    expect(writes(), ['start', 'swap', 'swap', 'set']);
    expect(exerciseOf(b), legPress.id);
  });

  test(
    'sin el orden garantizado la API rechazaría la serie (control)',
    () async {
      connectivity.online = true;
      final w = await service.startWorkout(planSessionId: planSession);
      await service.syncNow();
      final set = await log(w.clientId, legPress, 0);
      await service.syncNow();
      final row = (await service.setsOf(w.clientId)).single;
      expect(row.clientId, set.clientId);
      expect(row.status, SetSyncStatus.failed);
      expect(row.lastError, ApiErrorCode.validationFailed);
    },
  );

  test('descartar el entrenamiento borra sus cambios en cola', () async {
    final w = await service.startWorkout(planSessionId: planSession);
    await swap(w.clientId, legPress);
    await service.discardWorkout(w.clientId);
    expect(await service.watchSwaps().first, isEmpty);
  });
}
