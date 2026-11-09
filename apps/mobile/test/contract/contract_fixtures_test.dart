// Test de contrato: los DTOs Dart parsean los fixtures de la API v1 (JSON
// validado contra Zod con tool/validate_fixtures.mjs) y `toJson()` reproduce
// exactamente el original. Si la API añade, quita o renombra un campo, o
// cambia un enum, este test falla.
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/api/dio_error_mapper.dart';
import 'package:pipos_fitness/models/body.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/exercise.dart';
import 'package:pipos_fitness/models/json.dart';
import 'package:pipos_fitness/models/notes_breaks.dart';
import 'package:pipos_fitness/models/plan.dart';
import 'package:pipos_fitness/models/profile.dart';
import 'package:pipos_fitness/models/progress.dart';
import 'package:pipos_fitness/models/user.dart';
import 'package:pipos_fitness/models/workout.dart';
import 'package:dio/dio.dart';

import '../helpers/fixtures.dart';

void roundTrip(String name, Json Function(Json) parseAndWrite) {
  test('$name: fromJson → toJson es idéntico al fixture', () {
    final original = fixture(name);
    expect(parseAndWrite(fixture(name)), equals(original));
  });
}

void main() {
  roundTrip('auth_response', (j) => AuthResponse.fromJson(j).toJson());
  roundTrip('me', (j) => MeResponse.fromJson(j).toJson());
  roundTrip('profile', (j) => ProfileResponse.fromJson(j).toJson());
  roundTrip(
    'profile_update',
    (j) => ProfileUpdateResponse.fromJson(j).toJson(),
  );
  roundTrip('health_consent', (j) => HealthConsentStatus.fromJson(j).toJson());
  roundTrip(
    'withdraw_consent',
    (j) => WithdrawHealthConsentResponse.fromJson(j).toJson(),
  );
  roundTrip('plan_version', (j) => PlanVersion.fromJson(j).toJson());
  roundTrip(
    'plan_versions',
    (j) => Paginated.fromJson(
      j,
      PlanVersionSummary.fromJson,
    ).toJson((s) => s.toJson()),
  );
  roundTrip('set_log', (j) => SetLog.fromJson(j).toJson());
  roundTrip('exercise_detail', (j) => ExerciseDetail.fromJson(j).toJson());
  test(
    'exercise_detail_legacy: sin ficha → descripción null, listas vacías',
    () {
      final d = ExerciseDetail.fromJson(fixture('exercise_detail_legacy'));
      expect(d.descriptionEs, isNull);
      expect(d.mistakesEs, isEmpty);
      expect(d.media, isEmpty);
      expect(d.musclesWith(MuscleRole.primary), [Muscle.quads, Muscle.glutes]);
    },
  );
  roundTrip('workout', (j) => Workout.fromJson(j).toJson());
  roundTrip('substitution', (j) => Substitution.fromJson(j).toJson());
  roundTrip('substitutes', (j) => SubstitutesResponse.fromJson(j).toJson());
  roundTrip('today_session', (j) => TodaySession.fromJson(j).toJson());
  roundTrip('e1rm', (j) => E1rmResponse.fromJson(j).toJson());
  roundTrip('volume', (j) => VolumeResponse.fromJson(j).toJson());
  roundTrip('adherence', (j) => AdherenceResponse.fromJson(j).toJson());
  roundTrip('nutrition_targets', (j) => NutritionTargets.fromJson(j).toJson());
  roundTrip(
    'exercise_list',
    (j) => Paginated.fromJson(
      j,
      ExerciseSummary.fromJson,
    ).toJson((s) => s.toJson()),
  );
  roundTrip(
    'exercise_list_by_muscle',
    (j) => Paginated.fromJson(
      j,
      ExerciseSummary.fromJson,
    ).toJson((s) => s.toJson()),
  );

  // ADR-0013 (ideas recuperadas).
  roundTrip(
    'health_consent_v2',
    (j) => HealthConsentStatus.fromJson(j).toJson(),
  );
  roundTrip('exercise_note', (j) => ExerciseNote.fromJson(j).toJson());
  roundTrip('exercise_notes', (j) => ExerciseNoteList.fromJson(j).toJson());
  roundTrip('plan_override', (j) => PlanExerciseOverride.fromJson(j).toJson());
  roundTrip('today_session_adjusted', (j) => TodaySession.fromJson(j).toJson());
  roundTrip('today_session_break', (j) => TodaySession.fromJson(j).toJson());
  roundTrip('training_break', (j) => TrainingBreak.fromJson(j).toJson());
  roundTrip('training_breaks', (j) => TrainingBreakList.fromJson(j).toJson());
  roundTrip(
    'training_break_request',
    (j) => CreateTrainingBreakRequest.fromJson(j).toJson(),
  );
  roundTrip(
    'body_measurement',
    (j) => BodyMeasurementRecord.fromJson(j).toJson(),
  );
  roundTrip(
    'body_measurements',
    (j) => BodyMeasurementList.fromJson(j).toJson(),
  );
  roundTrip(
    'body_measurement_request',
    (j) => BodyMeasurement.fromJson(j).toJson(),
  );
  roundTrip('body_progress', (j) => BodyProgress.fromJson(j).toJson());
  roundTrip(
    'body_progress_not_applicable',
    (j) => BodyProgress.fromJson(j).toJson(),
  );
  roundTrip(
    'body_progress_consent_required',
    (j) => BodyProgress.fromJson(j).toJson(),
  );

  test('peticiones nuevas: serializan como los fixtures validados con Zod', () {
    final start = fixture('start_workout_adjusted');
    expect(
      StartWorkoutRequest(
        clientId: start['clientId'] as String,
        planSessionId: start['planSessionId'] as String,
        startedAt: DateTime.utc(2026, 11, 9, 8),
        adjustment: const WorkoutAdjustment(availableMinutes: 30),
      ).toJson(),
      start,
    );
    final note = fixture('exercise_note_request');
    expect(
      ExerciseNoteRequest(
        text: note['text'] as String,
        clientUpdatedAt: DateTime.utc(2026, 11, 9, 8),
      ).toJson(),
      note,
    );
    expect(
      const ProfileScheduleRequest([1, 3, 5]).toJson(),
      fixture('profile_schedule_request'),
    );
    // Editar una serie (#22).
    expect(
      PatchSetRequest(
        reps: 9,
        loadKg: 62.5,
        rir: 1,
        clientUpdatedAt: DateTime.utc(2026, 11, 9, 8, 5),
      ).toJson(),
      fixture('patch_set_request'),
    );
    // Sin ajuste no se envía el campo (clientes anteriores).
    expect(
      StartWorkoutRequest(
        clientId: 'c',
        planSessionId: 'p',
        startedAt: DateTime.utc(2026),
      ).toJson().containsKey('adjustment'),
      isFalse,
    );
  });

  test(
    'copias en caché de versiones anteriores: campos nuevos por defecto',
    () {
      final j = fixture('today_session')
        ..remove('scheduledToday')
        ..remove('activeBreak')
        ..remove('adjustment');
      for (final e in (j['exercises'] as List).cast<Json>()) {
        e
          ..remove('loadImplement')
          ..remove('loadStepKg')
          ..remove('plates')
          ..remove('pinned')
          ..remove('note');
      }
      final s = TodaySession.fromJson(j);
      expect(s.scheduledToday, isTrue);
      expect(s.exercises.first.plates, isNull);
      expect(s.exercises.first.pinned, isFalse);
    },
  );

  test('músculos (ADR-0014): respuestas y cachés anteriores sin `muscles` '
      'ni `primaryMuscles` siguen valiendo, con listas vacías', () {
    final today = fixture('today_session');
    for (final e in (today['exercises'] as List).cast<Json>()) {
      e.remove('muscles');
    }
    final first = TodaySession.fromJson(today).exercises.first;
    expect(first.muscles, isEmpty);
    expect(first.toJson()['muscles'], isEmpty);

    final plan = fixture('plan_version');
    final slot =
        (((plan['sessions'] as List).first as Json)['exercises'] as List)
            .cast<Json>()
            .first
          ..remove('muscles');
    expect(PlanExercise.fromJson(slot).muscles, isEmpty);

    final subs = fixture('substitutes');
    for (final o in (subs['substitutes'] as List).cast<Json>()) {
      o.remove('primaryMuscles');
    }
    expect(
      SubstitutesResponse.fromJson(subs).substitutes.first.primaryMuscles,
      isEmpty,
    );
  });

  test('músculos: principales y secundarios en el orden de la API', () {
    final squat = TodaySession.fromJson(
      fixture('today_session'),
    ).exercises.first;
    expect(squat.muscles.primary, [Muscle.glutes, Muscle.quads]);
    expect(squat.muscles.secondary, [Muscle.lowerBack, Muscle.adductors]);
  });

  test('export: valida cabecera y conserva el JSON completo', () {
    final e = AccountExport.fromJson(fixture('export'));
    expect(e.formatVersion, 1);
    expect(e.raw, equals(fixture('export')));
    // Registro de auditoría (issue #17): se conserva tal cual en el fichero.
    expect(e.raw['auditEvents'], hasLength(2));
    // Las exportaciones anteriores, sin `auditEvents`, siguen valiendo.
    final legacy = fixture('export')..remove('auditEvents');
    expect(
      AccountExport.fromJson(legacy).raw.containsKey('auditEvents'),
      isFalse,
    );
  });

  test(
    'un campo obligatorio ausente es error de parseo, no un valor por defecto',
    () {
      final j = fixture('today_session')..remove('planSessionId');
      expect(() => TodaySession.fromJson(j), throwsFormatException);
      expect(
        ApiFailure.from(const FormatException('x')).type,
        ApiFailureType.parse,
      );
    },
  );

  test('un enum desconocido es error de parseo', () {
    final j = fixture('profile')..['goal'] = 'yoga';
    expect(() => ProfileResponse.fromJson(j), throwsFormatException);
  });

  test('las peticiones serializan con los nombres del contrato', () {
    final req = UpsertSetRequest(
      clientId: 'c',
      planExerciseId: null,
      exerciseId: 'e',
      setIndex: 0,
      reps: 8,
      loadKg: 62.5,
      rir: 2,
      isWarmup: false,
      completedAt: DateTime.utc(2026, 11, 9, 8),
    );
    expect(req.toJson(), {
      'clientId': 'c',
      'planExerciseId': null,
      'exerciseId': 'e',
      'setIndex': 0,
      'reps': 8,
      'loadKg': 62.5,
      'rir': 2,
      'isWarmup': false,
      'completedAt': '2026-11-09T08:00:00.000Z',
    });
  });

  test('errores 422: code e issues por campo', () {
    final f = mapDioException(
      DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/me/profile'),
        response: Response(
          requestOptions: RequestOptions(path: '/me/profile'),
          statusCode: 422,
          data: fixture('error_validation'),
        ),
      ),
    );
    expect(f.code, ApiErrorCode.validationFailed);
    expect(f.issues.map((i) => i.field), ['daysPerWeek', 'equipment']);
  });
}
