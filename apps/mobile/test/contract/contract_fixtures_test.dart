// Test de contrato: los DTOs Dart parsean los fixtures de la API v1 (JSON
// validado contra Zod con tool/validate_fixtures.mjs) y `toJson()` reproduce
// exactamente el original. Si la API añade, quita o renombra un campo, o
// cambia un enum, este test falla.
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/core/api/dio_error_mapper.dart';
import 'package:pipos_fitness/models/json.dart';
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

  test('export: valida cabecera y conserva el JSON completo', () {
    final e = AccountExport.fromJson(fixture('export'));
    expect(e.formatVersion, 1);
    expect(e.raw, equals(fixture('export')));
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
