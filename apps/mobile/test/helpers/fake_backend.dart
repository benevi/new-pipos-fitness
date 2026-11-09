import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/data/pipos_api.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/json.dart';
import 'package:pipos_fitness/models/plan.dart';
import 'package:pipos_fitness/models/profile.dart';
import 'package:pipos_fitness/models/progress.dart';
import 'package:pipos_fitness/models/workout.dart';

import 'fixtures.dart';

/// Backend en memoria que implementa todas las interfaces de la capa de
/// datos con la semántica de la API v1: idempotencia por `clientId` (201 la
/// primera vez, 200 al reenviar), 404 sin plan, 403 con contraseña
/// incorrecta... Lo usan los widget tests y el integration test.
class FakeBackend
    implements
        ProfileApi,
        PlanApi,
        WorkoutApi,
        ProgressApi,
        AccountApi,
        CatalogApi {
  FakeBackend({
    this.hasPlan = true,
    this.hasProfile = true,
    bool progressEmpty = false,
  }) {
    if (progressEmpty) {
      e1rm = E1rmResponse.fromJson({
        'formulaVersion': 'epley-v1',
        'series': [],
      });
      volume = VolumeResponse.fromJson({
        'timezone': 'Europe/Madrid',
        'weeks': [],
      });
      adherence = AdherenceResponse.fromJson({
        'timezone': 'Europe/Madrid',
        'weeks': [],
        'totals': {
          'plannedSessions': 0,
          'completedSessions': 0,
          'sessionRatio': 0,
        },
      });
    }
  }

  bool online = true;

  /// `true`: las rutas de entrenamiento van por Dio real (y el test simula
  /// la API con el `FakeHttpAdapter`, códigos 201/200 incluidos).
  bool useHttpWorkoutApi = false;
  bool hasPlan;
  bool hasProfile;
  String password = 'correcta';

  Json todayJson = fixture('today_session');
  Json planJson = fixture('plan_version');
  Json profileJson = fixture('profile');
  E1rmResponse e1rm = E1rmResponse.fromJson(fixture('e1rm'));
  VolumeResponse volume = VolumeResponse.fromJson(fixture('volume'));
  AdherenceResponse adherence = AdherenceResponse.fromJson(
    fixture('adherence'),
  );

  /// Si no es null, `getNutritionTargets` lanza este fallo.
  ApiFailure? nutritionFailure;

  /// Registro de llamadas (`método ruta`).
  final List<String> calls = [];
  final List<ProfileUpsertRequest> profileRequests = [];
  final List<({String version, AppLocale locale})> consentGrants = [];

  // Entrenamientos y series guardados (por clientId).
  final Map<String, Workout> workouts = {};
  final Map<String, SetLog> sets = {};
  int setsCreated = 0;
  int setsReplayed = 0;
  int finishes = 0;

  /// Simula que la API guarda la siguiente serie pero la respuesta se
  /// pierde (timeout): el cliente reintentará con el mismo `clientId`.
  bool loseNextSetResponse = false;

  /// Si devuelve un fallo, `upsertSet` lo lanza (sin guardar la serie).
  ApiFailure? Function(UpsertSetRequest request)? setFailure;

  /// Fallos que lanzarán los próximos `finishWorkout` (uno por llamada).
  final List<ApiFailure> finishFailures = [];
  int finishCalls = 0;
  bool accountDeleted = false;
  int exports = 0;

  void _guard(String call) {
    calls.add(call);
    if (!online) {
      throw const ApiFailure(
        type: ApiFailureType.network,
        message: 'offline (fake)',
      );
    }
  }

  static ApiFailure _error(int status, String code) => ApiFailure(
    type: status == 401
        ? ApiFailureType.unauthorized
        : ApiFailureType.badRequest,
    message: code,
    statusCode: status,
    code: code,
  );

  // ── ProfileApi ──
  @override
  Future<ProfileResponse?> getProfile() async {
    _guard('GET /me/profile');
    return hasProfile ? ProfileResponse.fromJson(profileJson) : null;
  }

  @override
  Future<ProfileUpdateResponse> putProfile(ProfileUpsertRequest request) async {
    _guard('PUT /me/profile');
    profileRequests.add(request);
    final consent = profileJson['healthConsent'] as Json;
    final hasHealth =
        request.limitations.isNotEmpty ||
        request.weightKg != null ||
        request.heightCm != null;
    if (hasHealth && consent['granted'] != true && consentGrants.isEmpty) {
      throw _error(409, ApiErrorCode.healthConsentRequired);
    }
    profileJson = {
      ...profileJson,
      ...request.toJson(),
      if (consentGrants.isEmpty && consent['granted'] != true)
        'healthConsent': consent,
    };
    hasProfile = true;
    PlanVersionSummary? newVersion;
    if (hasPlan) {
      final v = (planJson['version'] as int) + 1;
      planJson = {...planJson, 'version': v};
      newVersion = PlanVersion.fromJson(planJson).summary;
    }
    return ProfileUpdateResponse(
      profile: ProfileResponse.fromJson(profileJson),
      planVersion: newVersion,
    );
  }

  @override
  Future<HealthConsentStatus> getHealthConsent() async {
    _guard('GET /me/consents/health');
    return HealthConsentStatus.fromJson(profileJson['healthConsent'] as Json);
  }

  @override
  Future<HealthConsentStatus> grantHealthConsent({
    required String version,
    required AppLocale locale,
  }) async {
    _guard('POST /me/consents/health');
    if (version != healthConsentPolicyVersion) {
      throw _error(422, ApiErrorCode.healthConsentVersionMismatch);
    }
    consentGrants.add((version: version, locale: locale));
    final status = {
      'granted': true,
      'version': version,
      'grantedAt': '2026-11-09T08:00:00.000Z',
      'currentVersion': healthConsentPolicyVersion,
    };
    profileJson = {...profileJson, 'healthConsent': status};
    return HealthConsentStatus.fromJson(status);
  }

  @override
  Future<WithdrawHealthConsentResponse> withdrawHealthConsent() async {
    _guard('DELETE /me/consents/health');
    final status = {
      'granted': false,
      'version': null,
      'grantedAt': null,
      'currentVersion': healthConsentPolicyVersion,
    };
    profileJson = {
      ...profileJson,
      'healthConsent': status,
      'limitations': <String>[],
      'weightKg': null,
      'heightCm': null,
    };
    return WithdrawHealthConsentResponse(
      healthConsent: HealthConsentStatus.fromJson(status),
      planVersion: hasPlan ? PlanVersion.fromJson(planJson).summary : null,
    );
  }

  @override
  Future<NutritionTargets> getNutritionTargets() async {
    _guard('GET /me/nutrition-targets');
    final f = nutritionFailure;
    if (f != null) throw f;
    return NutritionTargets.fromJson(fixture('nutrition_targets'));
  }

  // ── PlanApi ──
  @override
  Future<PlanVersion> generatePlan() async {
    _guard('POST /plans/generate');
    if (!hasProfile) throw _error(409, ApiErrorCode.profileRequired);
    hasPlan = true;
    return PlanVersion.fromJson(planJson);
  }

  @override
  Future<PlanVersion?> getCurrentPlan() async {
    _guard('GET /plans/current');
    return hasPlan ? PlanVersion.fromJson(planJson) : null;
  }

  @override
  Future<Paginated<PlanVersionSummary>> listVersions({int page = 1}) async {
    _guard('GET /plans/versions');
    return Paginated.fromJson(
      fixture('plan_versions'),
      PlanVersionSummary.fromJson,
    );
  }

  @override
  Future<PlanVersion> getVersion(String id) async {
    _guard('GET /plans/versions/$id');
    return PlanVersion.fromJson({...planJson, 'id': id});
  }

  // ── WorkoutApi ──
  @override
  Future<TodaySession> getToday() async {
    _guard('GET /sessions/today');
    if (!hasPlan) throw _error(404, ApiErrorCode.planRequired);
    // Como la API: si hay un entrenamiento en curso, la sesión de hoy es la
    // suya y lleva su referencia.
    for (final w in workouts.values) {
      if (w.status != WorkoutStatus.inProgress) continue;
      return TodaySession.fromJson({
        ...todayJson,
        'planSessionId': w.planSessionId,
        'workout': {
          'id': w.id,
          'clientId': w.clientId,
          'status': w.status.wire,
          'startedAt': isoUtc(w.startedAt),
        },
      });
    }
    return TodaySession.fromJson(todayJson);
  }

  /// Simula un entrenamiento empezado en otro dispositivo.
  Workout seedInProgress({
    required String clientId,
    required String planSessionId,
    required DateTime startedAt,
  }) {
    final w = Workout(
      id: 'srv-$clientId',
      clientId: clientId,
      planSessionId: planSessionId,
      status: WorkoutStatus.inProgress,
      startedAt: startedAt,
      completedAt: null,
      sets: const [],
      substitutions: const [],
    );
    workouts[clientId] = w;
    return w;
  }

  @override
  Future<Upserted<Workout>> startWorkout(StartWorkoutRequest request) async {
    _guard('POST /workouts');
    final existing = workouts[request.clientId];
    if (existing != null) return Upserted(existing, created: false);
    if (workouts.values.any((w) => w.status == WorkoutStatus.inProgress)) {
      throw _error(409, ApiErrorCode.workoutInProgress);
    }
    final w = Workout(
      id: 'srv-${request.clientId}',
      clientId: request.clientId,
      planSessionId: request.planSessionId,
      status: WorkoutStatus.inProgress,
      startedAt: request.startedAt,
      completedAt: null,
      sets: const [],
      substitutions: const [],
    );
    workouts[request.clientId] = w;
    return Upserted(w, created: true);
  }

  Workout? _byServerId(String id) {
    for (final w in workouts.values) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  Future<Upserted<SetLog>> upsertSet(
    String workoutId,
    UpsertSetRequest request,
  ) async {
    _guard('POST /workouts/$workoutId/sets');
    final w = _byServerId(workoutId);
    if (w == null) throw _error(404, ApiErrorCode.notFound);
    final injected = setFailure?.call(request);
    if (injected != null) throw injected;
    final existing = sets[request.clientId];
    if (existing == null && w.status != WorkoutStatus.inProgress) {
      throw _error(409, ApiErrorCode.workoutFinished);
    }
    if (existing != null) {
      setsReplayed++;
      return Upserted(existing, created: false);
    }
    final s = SetLog(
      id: 'set-${request.clientId}',
      clientId: request.clientId,
      workoutId: workoutId,
      planExerciseId: request.planExerciseId,
      exerciseId: request.exerciseId,
      setIndex: request.setIndex,
      reps: request.reps,
      loadKg: request.loadKg,
      rir: request.rir,
      isWarmup: request.isWarmup,
      completedAt: request.completedAt,
      clientUpdatedAt: request.clientUpdatedAt ?? request.completedAt,
      deletedAt: null,
    );
    sets[request.clientId] = s;
    setsCreated++;
    if (loseNextSetResponse) {
      loseNextSetResponse = false;
      throw const ApiFailure(
        type: ApiFailureType.timeout,
        message: 'response lost (fake)',
      );
    }
    return Upserted(s, created: true);
  }

  @override
  Future<Workout> finishWorkout(String workoutId, DateTime completedAt) async {
    _guard('POST /workouts/$workoutId/finish');
    finishCalls++;
    if (finishFailures.isNotEmpty) throw finishFailures.removeAt(0);
    final w = _byServerId(workoutId);
    if (w == null) throw _error(404, ApiErrorCode.notFound);
    if (w.status != WorkoutStatus.inProgress) {
      throw _error(409, ApiErrorCode.workoutFinished);
    }
    finishes++;
    final done = Workout(
      id: w.id,
      clientId: w.clientId,
      planSessionId: w.planSessionId,
      status: WorkoutStatus.completed,
      startedAt: w.startedAt,
      completedAt: completedAt,
      sets: [
        for (final s in sets.values)
          if (s.workoutId == w.id) s,
      ],
      substitutions: const [],
    );
    workouts[w.clientId] = done;
    return done;
  }

  @override
  Future<SubstitutesResponse> getSubstitutes(String exerciseId) async {
    _guard('GET /exercises/$exerciseId/substitutes');
    return SubstitutesResponse.fromJson(fixture('substitutes'));
  }

  final List<({String workoutId, String planExerciseId, String exerciseId})>
  substitutions = [];

  @override
  Future<Substitution> substitute({
    required String workoutId,
    required String planExerciseId,
    required String exerciseId,
  }) async {
    _guard('POST /workouts/$workoutId/exercises/$planExerciseId/substitute');
    if (_byServerId(workoutId) == null) {
      throw _error(404, ApiErrorCode.notFound);
    }
    final options = SubstitutesResponse.fromJson(fixture('substitutes'));
    final chosen = options.substitutes.firstWhere(
      (o) => o.exerciseId == exerciseId,
    );
    substitutions.add((
      workoutId: workoutId,
      planExerciseId: planExerciseId,
      exerciseId: exerciseId,
    ));
    final exercises = (todayJson['exercises'] as List).cast<Json>();
    final slot = exercises.firstWhere(
      (e) => e['planExerciseId'] == planExerciseId,
    );
    final original = slot['exercise'] as Json;
    slot['substitutedFrom'] = original;
    slot['exercise'] = {
      'id': chosen.exerciseId,
      'slug': chosen.slug,
      'nameEs': chosen.nameEs,
    };
    return Substitution(
      workoutId: workoutId,
      planExerciseId: planExerciseId,
      exercise: ExerciseRef(
        id: chosen.exerciseId,
        slug: chosen.slug,
        nameEs: chosen.nameEs,
      ),
      substitutedFrom: ExerciseRef.fromJson(original),
    );
  }

  // ── ProgressApi ──
  @override
  Future<E1rmResponse> getE1rm() async {
    _guard('GET /progress/e1rm');
    return e1rm;
  }

  @override
  Future<VolumeResponse> getVolume({int weeks = 8}) async {
    _guard('GET /progress/volume');
    return volume;
  }

  @override
  Future<AdherenceResponse> getAdherence({int weeks = 8}) async {
    _guard('GET /progress/adherence');
    return adherence;
  }

  // ── AccountApi ──
  @override
  Future<AccountExport> exportData() async {
    _guard('GET /me/export');
    exports++;
    return AccountExport.fromJson(fixture('export'));
  }

  @override
  Future<void> deleteAccount(String password) async {
    _guard('DELETE /me');
    if (password != this.password) throw _error(403, ApiErrorCode.forbidden);
    accountDeleted = true;
  }

  // ── CatalogApi ──
  @override
  Future<Paginated<ExerciseSummary>> searchExercises({
    String? query,
    int page = 1,
  }) async {
    _guard('GET /exercises');
    return Paginated.fromJson(
      fixture('exercise_list'),
      ExerciseSummary.fromJson,
    );
  }

  /// Overrides de Riverpod que conectan todas las interfaces a este fake.
  List<Override> get overrides => [
    profileApiProvider.overrideWithValue(this),
    planApiProvider.overrideWithValue(this),
    if (!useHttpWorkoutApi) workoutApiProvider.overrideWithValue(this),
    progressApiProvider.overrideWithValue(this),
    accountApiProvider.overrideWithValue(this),
    catalogApiProvider.overrideWithValue(this),
  ];
}
