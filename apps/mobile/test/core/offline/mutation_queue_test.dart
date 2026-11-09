// Cola offline de otras escrituras (ADR-0013): nota fija y medidas. La
// última edición local sustituye a la anterior; con red se envía una vez;
// error transitorio → backoff; permanente → failed hasta reintentar. Y el
// ajuste de hoy viaja en `POST /workouts`.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/mutation_sender.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';
import 'package:pipos_fitness/models/body.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/notes_breaks.dart';
import 'package:pipos_fitness/models/workout.dart';

import '../../helpers/fake_backend.dart';

const exercise = '00000000-0000-4000-8000-000000000040';

class _FlakyBackend extends FakeBackend {
  final failures = <ApiFailure>[];

  @override
  Future<ExerciseNote> putNote(
    String exerciseId,
    ExerciseNoteRequest request,
  ) async {
    if (failures.isNotEmpty) throw failures.removeAt(0);
    return super.putNote(exerciseId, request);
  }
}

void main() {
  late AppDatabase db;
  late ManualConnectivitySource connectivity;
  late _FlakyBackend backend;
  late DateTime now;
  late SyncService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = ManualConnectivitySource(online: false);
    backend = _FlakyBackend();
    now = DateTime.utc(2026, 11, 9, 8);
    service = SyncService(
      database: db,
      api: backend,
      connectivity: connectivity,
      userId: 'user-1',
      clock: () => now,
      mutations: ApiMutationSender(notes: backend, body: backend),
    );
  });

  tearDown(() async {
    await service.dispose();
    await connectivity.dispose();
    await db.close();
  });

  Future<void> editNote(String text) => service.enqueueMutation(
    key: MutationKeys.note(exercise),
    kind: MutationKind.notePut,
    payload: {'exerciseId': exercise, 'text': text},
  );

  test(
    'dos ediciones sin red → una fila; con red se envía la última',
    () async {
      await editNote('Asiento en el 3');
      now = now.add(const Duration(minutes: 1));
      await editNote('Asiento en el 4');
      var summary = await service.watchSummary().first;
      expect(summary.pendingChanges, 1);
      expect((await service.syncNow()).offline, isTrue);

      connectivity.online = true;
      await service.syncNow();
      expect(backend.notePuts, 1);
      expect(backend.notes[exercise]!.text, 'Asiento en el 4');
      expect(
        backend.notes[exercise]!.clientUpdatedAt.isAtSameMomentAs(
          DateTime.utc(2026, 11, 9, 8, 1),
        ),
        isTrue,
      );
      summary = await service.watchSummary().first;
      expect(summary.isClean, isTrue);
    },
  );

  test('error transitorio: sigue pendiente con backoff', () async {
    connectivity.online = true;
    backend.failures.add(
      const ApiFailure(type: ApiFailureType.network, message: 'x'),
    );
    await editNote('Agarre neutro');
    await service.syncNow();
    final rows = await db.select(db.pendingMutations).get();
    expect(rows.single.status, SetSyncStatus.pending);
    expect(rows.single.attempts, 1);
    expect(rows.single.nextAttemptAt, isNotNull);
  });

  test(
    'medida sin el ámbito del consentimiento → failed; reintentar',
    () async {
      connectivity.online = true;
      // El perfil del fixture consintió la versión anterior: sin perímetros.
      await service.enqueueMutation(
        key: MutationKeys.measurement('2026-11-09'),
        kind: MutationKind.measurementPut,
        payload: const BodyMeasurement(
          measuredOn: '2026-11-09',
          values: {BodyField.waistCm: 86},
        ).toJson(),
      );
      await service.syncNow();
      var summary = await service.watchSummary().first;
      expect(summary.failedChanges, 1);
      expect(backend.measurements, isEmpty);

      // Solo el peso sí lo cubre la versión anterior.
      await service.enqueueMutation(
        key: MutationKeys.measurement('2026-11-09'),
        kind: MutationKind.measurementPut,
        payload: const BodyMeasurement(
          measuredOn: '2026-11-09',
          values: {BodyField.weightKg: 80.4},
        ).toJson(),
      );
      await service.syncNow();
      summary = await service.watchSummary().first;
      expect(summary.isClean, isTrue);
      expect(backend.measurements['2026-11-09']![BodyField.weightKg], 80.4);
    },
  );

  test('el ajuste de hoy se envía al empezar el entrenamiento', () async {
    connectivity.online = true;
    final w = await service.startWorkout(
      planSessionId: '00000000-0000-4000-8000-000000000020',
      adjustment: const WorkoutAdjustment(availableMinutes: 30),
    );
    expect(SyncService.adjustmentOf(w)?.availableMinutes, 30);
    await service.syncNow();
    expect(
      backend.startRequests.single.adjustment,
      const WorkoutAdjustment(availableMinutes: 30),
    );
  });
}
