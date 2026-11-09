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
import '../models/body.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/json.dart';
import '../models/notes_breaks.dart';
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
  /// `POST /plans/generate`. Con [idempotencyKey] (un UUID v4 por intento,
  /// igual en cada reintento) repetir devuelve la misma versión (200) en vez
  /// de crear otra; misma clave con otro perfil → `422
  /// IDEMPOTENCY_KEY_REUSED`.
  Future<PlanVersion> generatePlan({String? idempotencyKey});

  /// `null` si no hay plan (404 PLAN_REQUIRED).
  Future<PlanVersion?> getCurrentPlan();
  Future<Paginated<PlanVersionSummary>> listVersions({int page = 1});
  Future<PlanVersion> getVersion(String id);

  /// «Usar siempre este cambio en este plan» (idea 3).
  Future<PlanExerciseOverride> pinExercise({
    required String planExerciseId,
    required String exerciseId,
  });

  /// Vuelve al ejercicio original del plan.
  Future<PlanExerciseOverride> unpinExercise(String planExerciseId);
}

abstract class WorkoutApi {
  /// Sesión de hoy. Con [adjustment] es una vista previa ajustada (solo
  /// lectura, idea 4); sin él y con un entrenamiento en curso, la API aplica
  /// el ajuste guardado al empezarlo.
  Future<TodaySession> getToday({WorkoutAdjustment? adjustment});
  Future<Upserted<Workout>> startWorkout(StartWorkoutRequest request);
  Future<Upserted<SetLog>> upsertSet(
    String workoutId,
    UpsertSetRequest request,
  );
  Future<Workout> finishWorkout(String workoutId, DateTime completedAt);

  /// `POST /workouts/:id/abandon` (idempotente; 409 WORKOUT_FINISHED si ya
  /// estaba terminado).
  Future<Workout> abandonWorkout(String workoutId);

  /// `DELETE /workouts/:id/sets/:clientId` (borrado lógico, idempotente;
  /// 404 si la serie nunca llegó al servidor).
  Future<SetLog> deleteSet(String workoutId, String clientId);

  /// `PATCH /workouts/:id/sets/:clientId` (gana la última escritura).
  Future<SetLog> patchSet(
    String workoutId,
    String clientId,
    PatchSetRequest request,
  );
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

/// Nota fija por ejercicio (idea 2).
abstract class NotesApi {
  Future<ExerciseNote> putNote(String exerciseId, ExerciseNoteRequest request);
  Future<void> deleteNote(String exerciseId);
  Future<ExerciseNoteList> listNotes();
}

/// Días de entreno y pausas planificadas (idea 6).
abstract class ScheduleApi {
  /// Lanza [ApiFailure] 422 si hay más días que `daysPerWeek`.
  Future<ProfileResponse> updateSchedule(List<int> trainingWeekdays);
  Future<TrainingBreakList> listBreaks({String? from});
  Future<Upserted<TrainingBreak>> createBreak(
    CreateTrainingBreakRequest request,
  );
  Future<void> deleteBreak(String id);
}

/// Medidas corporales (idea 7; datos de salud).
abstract class BodyApi {
  /// Lanza [ApiFailure] 409 HEALTH_CONSENT_REQUIRED sin el ámbito necesario.
  Future<BodyMeasurementRecord> putMeasurement(BodyMeasurement measurement);
  Future<BodyMeasurementList> listMeasurements({String? from, String? to});
  Future<void> deleteMeasurement(String date);
  Future<BodyProgress> getBodyProgress();
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

  /// Ficha del ejercicio por id o por slug (`GET /exercises/:id`, ADR-0014).
  Future<ExerciseDetail> getExercise(String idOrSlug);
}

/// Implementación real sobre el Dio autenticado.
class DioPiposApi
    implements
        ProfileApi,
        PlanApi,
        WorkoutApi,
        ProgressApi,
        AccountApi,
        CatalogApi,
        NotesApi,
        ScheduleApi,
        BodyApi {
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
  Future<PlanVersion> generatePlan({String? idempotencyKey}) => _call(
    () async => PlanVersion.fromJson(
      _json(
        await _client.post(
          '/plans/generate',
          headers: idempotencyKey == null
              ? null
              : {'Idempotency-Key': idempotencyKey},
        ),
      ),
    ),
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

  @override
  Future<PlanExerciseOverride> pinExercise({
    required String planExerciseId,
    required String exerciseId,
  }) => _call(
    () async => PlanExerciseOverride.fromJson(
      _json(
        await _client.put(
          '/plans/current/exercises/$planExerciseId/override',
          data: {'exerciseId': exerciseId},
        ),
      ),
    ),
  );

  @override
  Future<PlanExerciseOverride> unpinExercise(String planExerciseId) => _call(
    () async => PlanExerciseOverride.fromJson(
      _json(
        await _client.delete(
          '/plans/current/exercises/$planExerciseId/override',
        ),
      ),
    ),
  );

  // ── Entrenamientos ──
  @override
  Future<TodaySession> getToday({WorkoutAdjustment? adjustment}) => _call(
    () async => TodaySession.fromJson(
      _json(
        await _client.get(
          '/sessions/today',
          queryParameters: adjustment == null || adjustment.isNone
              ? null
              : {
                  if (adjustment.availableMinutes != null)
                    'minutes': adjustment.availableMinutes,
                  if (adjustment.reducedVolume) 'mode': 'reduced',
                },
        ),
      ),
    ),
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
  Future<Workout> abandonWorkout(String workoutId) => _call(
    () async => Workout.fromJson(
      _json(await _client.post('/workouts/$workoutId/abandon')),
    ),
  );

  @override
  Future<SetLog> deleteSet(String workoutId, String clientId) => _call(
    () async => SetLog.fromJson(
      _json(await _client.delete('/workouts/$workoutId/sets/$clientId')),
    ),
  );

  @override
  Future<SetLog> patchSet(
    String workoutId,
    String clientId,
    PatchSetRequest request,
  ) => _call(
    () async => SetLog.fromJson(
      _json(
        await _client.patch(
          '/workouts/$workoutId/sets/$clientId',
          data: request.toJson(),
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

  // ── Notas ──
  @override
  Future<ExerciseNote> putNote(
    String exerciseId,
    ExerciseNoteRequest request,
  ) => _call(
    () async => ExerciseNote.fromJson(
      _json(
        await _client.put(
          '/exercises/$exerciseId/note',
          data: request.toJson(),
        ),
      ),
    ),
  );

  @override
  Future<void> deleteNote(String exerciseId) => _call(() async {
    await _client.delete('/exercises/$exerciseId/note');
  });

  @override
  Future<ExerciseNoteList> listNotes() => _call(
    () async => ExerciseNoteList.fromJson(
      _json(await _client.get('/me/exercise-notes')),
    ),
  );

  // ── Días de entreno y pausas ──
  @override
  Future<ProfileResponse> updateSchedule(List<int> trainingWeekdays) => _call(
    () async => ProfileResponse.fromJson(
      _json(
        await _client.patch(
          '/me/profile/schedule',
          data: ProfileScheduleRequest(trainingWeekdays).toJson(),
        ),
      ),
    ),
  );

  @override
  Future<TrainingBreakList> listBreaks({String? from}) => _call(
    () async => TrainingBreakList.fromJson(
      _json(
        await _client.get(
          '/me/breaks',
          queryParameters: from == null ? null : {'from': from},
        ),
      ),
    ),
  );

  @override
  Future<Upserted<TrainingBreak>> createBreak(
    CreateTrainingBreakRequest request,
  ) => _call(() async {
    final r = await _client.post('/me/breaks', data: request.toJson());
    return Upserted(
      TrainingBreak.fromJson(_json(r)),
      created: r.statusCode == 201,
    );
  });

  @override
  Future<void> deleteBreak(String id) => _call(() async {
    await _client.delete('/me/breaks/$id');
  });

  // ── Medidas corporales ──
  @override
  Future<BodyMeasurementRecord> putMeasurement(BodyMeasurement measurement) =>
      _call(
        () async => BodyMeasurementRecord.fromJson(
          _json(
            await _client.put('/me/measurements', data: measurement.toJson()),
          ),
        ),
      );

  @override
  Future<BodyMeasurementList> listMeasurements({String? from, String? to}) =>
      _call(
        () async => BodyMeasurementList.fromJson(
          _json(
            await _client.get(
              '/me/measurements',
              queryParameters: {'from': ?from, 'to': ?to},
            ),
          ),
        ),
      );

  @override
  Future<void> deleteMeasurement(String date) => _call(() async {
    await _client.delete('/me/measurements/$date');
  });

  @override
  Future<BodyProgress> getBodyProgress() => _call(
    () async =>
        BodyProgress.fromJson(_json(await _client.get('/progress/body'))),
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

  @override
  Future<ExerciseDetail> getExercise(String idOrSlug) => _call(
    () async => ExerciseDetail.fromJson(
      _json(await _client.get('/exercises/${Uri.encodeComponent(idOrSlug)}')),
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
final notesApiProvider = Provider<NotesApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final scheduleApiProvider = Provider<ScheduleApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
final bodyApiProvider = Provider<BodyApi>(
  (ref) => ref.watch(dioPiposApiProvider),
);
