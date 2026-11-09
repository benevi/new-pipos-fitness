/// Capa de datos de la API v1.
///
/// Las pantallas y el `SyncService` dependen de estas interfaces, nunca de
/// Dio: los tests (y el integration test «completar una sesión») las
/// sustituyen por un backend en memoria (`test/helpers/fake_backend.dart`).
///
/// Todas las operaciones lanzan [ApiFailure] (nunca `DioException`).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_failure.dart';
import '../models/enums.dart';
import '../models/json.dart';
import '../models/plan.dart';
import '../models/profile.dart';
import '../models/progress.dart';
import '../models/workout.dart';

/// Resultado de una escritura idempotente (201 = creado, 200 = ya existía).
class Upserted<T> {
  const Upserted(this.value, {required this.created});

  final T value;
  final bool created;
}

abstract class ProfileApi {
  /// `null` si el usuario aún no tiene perfil (404 PROFILE_REQUIRED).
  Future<ProfileResponse?> getProfile();
  Future<ProfileUpdateResponse> putProfile(ProfileUpsertRequest request);
  Future<HealthConsentStatus> getHealthConsent();
  Future<HealthConsentStatus> grantHealthConsent({
    required String version,
    required AppLocale locale,
  });
  Future<WithdrawHealthConsentResponse> withdrawHealthConsent();
  Future<NutritionTargets> getNutritionTargets();
}

abstract class PlanApi {
  Future<PlanVersion> generatePlan();

  /// `null` si no hay plan (404 PLAN_REQUIRED).
  Future<PlanVersion?> getCurrentPlan();
  Future<Paginated<PlanVersionSummary>> listVersions({int page = 1});
  Future<PlanVersion> getVersion(String id);
}

abstract class WorkoutApi {
  Future<TodaySession> getToday();
  Future<Upserted<Workout>> startWorkout(StartWorkoutRequest request);
  Future<Upserted<SetLog>> upsertSet(
    String workoutId,
    UpsertSetRequest request,
  );
  Future<Workout> finishWorkout(String workoutId, DateTime completedAt);
  Future<SubstitutesResponse> getSubstitutes(String exerciseId);
  Future<Substitution> substitute({
    required String workoutId,
    required String planExerciseId,
    required String exerciseId,
  });
}

abstract class ProgressApi {
  Future<E1rmResponse> getE1rm();
  Future<VolumeResponse> getVolume({int weeks = 8});
  Future<AdherenceResponse> getAdherence({int weeks = 8});
}

abstract class AccountApi {
  Future<AccountExport> exportData();

  /// Lanza [ApiFailure] 403 si la contraseña no es correcta.
  Future<void> deleteAccount(String password);
}

abstract class CatalogApi {
  Future<Paginated<ExerciseSummary>> searchExercises({
    String? query,
    int page = 1,
  });
}

/// Implementación real sobre el Dio autenticado.
class DioPiposApi
    implements
        ProfileApi,
        PlanApi,
        WorkoutApi,
        ProgressApi,
        AccountApi,
        CatalogApi {
  DioPiposApi(this._client);

  final ApiClient _client;

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Json _json(Response<dynamic> r) {
    final data = r.data;
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('La respuesta no es un objeto JSON');
  }

  Future<T?> _nullOn404<T>(Future<T> Function() run) async {
    try {
      return await _call(run);
    } on ApiFailure catch (f) {
      if (f.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Perfil ──
  @override
  Future<ProfileResponse?> getProfile() => _nullOn404(
    () async =>
        ProfileResponse.fromJson(_json(await _client.get('/me/profile'))),
  );

  @override
  Future<ProfileUpdateResponse> putProfile(ProfileUpsertRequest request) =>
      _call(
        () async => ProfileUpdateResponse.fromJson(
          _json(await _client.put('/me/profile', data: request.toJson())),
        ),
      );

  @override
  Future<HealthConsentStatus> getHealthConsent() => _call(
    () async => HealthConsentStatus.fromJson(
      _json(await _client.get('/me/consents/health')),
    ),
  );

  @override
  Future<HealthConsentStatus> grantHealthConsent({
    required String version,
    required AppLocale locale,
  }) => _call(
    () async => HealthConsentStatus.fromJson(
      _json(
        await _client.post(
          '/me/consents/health',
          data: {'version': version, 'locale': locale.wire},
        ),
      ),
    ),
  );

  @override
  Future<WithdrawHealthConsentResponse> withdrawHealthConsent() => _call(
    () async => WithdrawHealthConsentResponse.fromJson(
      _json(await _client.delete('/me/consents/health')),
    ),
  );

  @override
  Future<NutritionTargets> getNutritionTargets() => _call(
    () async => NutritionTargets.fromJson(
      _json(await _client.get('/me/nutrition-targets')),
    ),
  );

  // ── Planes ──
  @override
  Future<PlanVersion> generatePlan() => _call(
    () async =>
        PlanVersion.fromJson(_json(await _client.post('/plans/generate'))),
  );

  @override
  Future<PlanVersion?> getCurrentPlan() => _nullOn404(
    () async =>
        PlanVersion.fromJson(_json(await _client.get('/plans/current'))),
  );

  @override
  Future<Paginated<PlanVersionSummary>> listVersions({int page = 1}) => _call(
    () async => Paginated.fromJson(
      _json(
        await _client.get(
          '/plans/versions',
          queryParameters: {'page': page, 'pageSize': 20},
        ),
      ),
      PlanVersionSummary.fromJson,
    ),
  );

  @override
  Future<PlanVersion> getVersion(String id) => _call(
    () async =>
        PlanVersion.fromJson(_json(await _client.get('/plans/versions/$id'))),
  );

  // ── Entrenamientos ──
  @override
  Future<TodaySession> getToday() => _call(
    () async =>
        TodaySession.fromJson(_json(await _client.get('/sessions/today'))),
  );

  @override
  Future<Upserted<Workout>> startWorkout(StartWorkoutRequest request) => _call(
    () async {
      final r = await _client.post('/workouts', data: request.toJson());
      return Upserted(Workout.fromJson(_json(r)), created: r.statusCode == 201);
    },
  );

  @override
  Future<Upserted<SetLog>> upsertSet(
    String workoutId,
    UpsertSetRequest request,
  ) => _call(() async {
    final r = await _client.post(
      '/workouts/$workoutId/sets',
      data: request.toJson(),
    );
    return Upserted(SetLog.fromJson(_json(r)), created: r.statusCode == 201);
  });

  @override
  Future<Workout> finishWorkout(String workoutId, DateTime completedAt) =>
      _call(
        () async => Workout.fromJson(
          _json(
            await _client.post(
              '/workouts/$workoutId/finish',
              data: {'completedAt': isoUtc(completedAt)},
            ),
          ),
        ),
      );

  @override
  Future<SubstitutesResponse> getSubstitutes(String exerciseId) => _call(
    () async => SubstitutesResponse.fromJson(
      _json(await _client.get('/exercises/$exerciseId/substitutes')),
    ),
  );

  @override
  Future<Substitution> substitute({
    required String workoutId,
    required String planExerciseId,
    required String exerciseId,
  }) => _call(
    () async => Substitution.fromJson(
      _json(
        await _client.post(
          '/workouts/$workoutId/exercises/$planExerciseId/substitute',
          data: {'exerciseId': exerciseId},
        ),
      ),
    ),
  );

  // ── Progreso ──
  @override
  Future<E1rmResponse> getE1rm() => _call(
    () async =>
        E1rmResponse.fromJson(_json(await _client.get('/progress/e1rm'))),
  );

  @override
  Future<VolumeResponse> getVolume({int weeks = 8}) => _call(
    () async => VolumeResponse.fromJson(
      _json(
        await _client.get(
          '/progress/volume',
          queryParameters: {'weeks': weeks},
        ),
      ),
    ),
  );

  @override
  Future<AdherenceResponse> getAdherence({int weeks = 8}) => _call(
    () async => AdherenceResponse.fromJson(
      _json(
        await _client.get(
          '/progress/adherence',
          queryParameters: {'weeks': weeks},
        ),
      ),
    ),
  );

  // ── Cuenta ──
  @override
  Future<AccountExport> exportData() => _call(
    () async => AccountExport.fromJson(_json(await _client.get('/me/export'))),
  );

  @override
  Future<void> deleteAccount(String password) => _call(() async {
    await _client.delete('/me', data: {'password': password});
  });

  // ── Catálogo ──
  @override
  Future<Paginated<ExerciseSummary>> searchExercises({
    String? query,
    int page = 1,
  }) => _call(
    () async => Paginated.fromJson(
      _json(
        await _client.get(
          '/exercises',
          queryParameters: {
            'page': page,
            'pageSize': 20,
            if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          },
        ),
      ),
      ExerciseSummary.fromJson,
    ),
  );
}

final dioPiposApiProvider = Provider<DioPiposApi>(
  (ref) => DioPiposApi(ref.watch(apiClientProvider)),
);

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final planApiProvider = Provider<PlanApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final workoutApiProvider = Provider<WorkoutApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final progressApiProvider = Provider<ProgressApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final accountApiProvider = Provider<AccountApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final catalogApiProvider = Provider<CatalogApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
