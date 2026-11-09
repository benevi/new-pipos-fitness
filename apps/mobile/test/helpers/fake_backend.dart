import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/data/pipos_api.dart';
import 'package:pipos_fitness/models/body.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/json.dart';
import 'package:pipos_fitness/models/notes_breaks.dart';
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
        CatalogApi,
        NotesApi,
        ScheduleApi,
        BodyApi {
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

  /// Ajustes pedidos en vista previa (`GET /sessions/today?minutes=…`).
  final List<WorkoutAdjustment> todayQueries = [];
  final List<StartWorkoutRequest> startRequests = [];

  /// Sesiones de versiones del plan que ya no son la vigente.
  final Set<String> outdatedPlanSessions = {};

  /// Cambios fijados: planExerciseId → exerciseId.
  final Map<String, String> pins = {};

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

  /// Como la API desde la Fase 5: rechaza (400) una serie nueva de un
  /// ejercicio que no sea el original del hueco ni su sustitución
  /// registrada (la última) en ese entrenamiento.
  bool enforceSlotExercise = false;

  /// Fallos que lanzarán los próximos `substitute` (uno por llamada).
  final List<ApiFailure> substituteFailures = [];

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
    // Como la API: solo hay versión nueva del plan si el perfil cambió.
    final changed =
        !hasProfile ||
        request.toJson().entries.any(
          (e) => jsonEncode(profileJson[e.key]) != jsonEncode(e.value),
        );
    profileJson = {
      ...profileJson,
      ...request.toJson(),
      if (consentGrants.isEmpty && consent['granted'] != true)
        'healthConsent': consent,
    };
    hasProfile = true;
    PlanVersionSummary? newVersion;
    if (hasPlan && changed) {
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
      'scopes': [
        'weight',
        'height',
        'limitations',
        'body_measurements',
        'derived_estimates',
      ],
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
      'scopes': <String>[],
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
  /// `Idempotency-Key` de cada `POST /plans/generate` (null = sin clave).
  final List<String?> generateKeys = [];

  /// Versiones creadas por `generatePlan` (una repetición con la misma clave
  /// devuelve la misma, como la API).
  int plansGenerated = 0;
  final Map<String, ({String profile, Json plan})> _generatedByKey = {};

  /// Simula que la API crea la versión pero la respuesta se pierde.
  bool loseNextGenerateResponse = false;

  @override
  Future<PlanVersion> generatePlan({String? idempotencyKey}) async {
    _guard('POST /plans/generate');
    generateKeys.add(idempotencyKey);
    if (!hasProfile) throw _error(409, ApiErrorCode.profileRequired);
    final profile = profileJson.toString();
    final previous = idempotencyKey == null
        ? null
        : _generatedByKey[idempotencyKey];
    if (previous != null) {
      if (previous.profile != profile) {
        throw _error(422, ApiErrorCode.idempotencyKeyReused);
      }
      return PlanVersion.fromJson(previous.plan);
    }
    hasPlan = true;
    plansGenerated++;
    if (idempotencyKey != null) {
      _generatedByKey[idempotencyKey] = (profile: profile, plan: planJson);
    }
    if (loseNextGenerateResponse) {
      loseNextGenerateResponse = false;
      throw const ApiFailure(
        type: ApiFailureType.timeout,
        message: 'response lost (fake)',
      );
    }
    return PlanVersion.fromJson(planJson);
  }

  /// La próxima clave usada se da por gastada con otro perfil (422).
  void reserveKeyWithOtherProfile(String key) =>
      _generatedByKey[key] = (profile: 'otro perfil', plan: planJson);

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

  @override
  Future<PlanExerciseOverride> pinExercise({
    required String planExerciseId,
    required String exerciseId,
  }) async {
    _guard('PUT /plans/current/exercises/$planExerciseId/override');
    final options = SubstitutesResponse.fromJson(fixture('substitutes'));
    final chosen = options.substitutes.firstWhere(
      (o) => o.exerciseId == exerciseId,
      orElse: () => throw _error(409, ApiErrorCode.validationFailed),
    );
    final ref = {
      'id': chosen.exerciseId,
      'slug': chosen.slug,
      'nameEs': chosen.nameEs,
    };
    pins[planExerciseId] = exerciseId;
    final original = _setPlanPin(planExerciseId, ref);
    for (final e in (todayJson['exercises'] as List).cast<Json>()) {
      if (e['planExerciseId'] != planExerciseId) continue;
      e['substitutedFrom'] ??= e['exercise'];
      e['exercise'] = ref;
      e['pinned'] = true;
    }
    return PlanExerciseOverride.fromJson({
      'planVersionId': planJson['id'],
      'planExerciseIds': [planExerciseId],
      'original': original,
      'pinned': ref,
    });
  }

  @override
  Future<PlanExerciseOverride> unpinExercise(String planExerciseId) async {
    _guard('DELETE /plans/current/exercises/$planExerciseId/override');
    pins.remove(planExerciseId);
    final original = _setPlanPin(planExerciseId, null);
    return PlanExerciseOverride.fromJson({
      'planVersionId': planJson['id'],
      'planExerciseIds': [planExerciseId],
      'original': original,
      'pinned': null,
    });
  }

  /// Cambia `pinned` del hueco en el plan y devuelve la referencia original.
  Json _setPlanPin(String planExerciseId, Json? pinned) {
    for (final s in (planJson['sessions'] as List).cast<Json>()) {
      for (final e in (s['exercises'] as List).cast<Json>()) {
        if (e['id'] != planExerciseId) continue;
        e['pinned'] = pinned;
        return {
          'id': e['exerciseId'],
          'slug': e['slug'],
          'nameEs': e['nameEs'],
        };
      }
    }
    throw _error(404, ApiErrorCode.notFound);
  }

  // ── WorkoutApi ──
  @override
  Future<TodaySession> getToday({WorkoutAdjustment? adjustment}) async {
    _guard('GET /sessions/today');
    if (!hasPlan) throw _error(404, ApiErrorCode.planRequired);
    if (adjustment != null && !adjustment.isNone) {
      todayQueries.add(adjustment);
      final adjusted = fixture('today_session_adjusted');
      (adjusted['adjustment'] as Json)
        ..['availableMinutes'] = adjustment.availableMinutes
        ..['reducedVolume'] = adjustment.reducedVolume;
      return TodaySession.fromJson(adjusted);
    }
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
    startRequests.add(request);
    final existing = workouts[request.clientId];
    if (existing != null) return Upserted(existing, created: false);
    // Como la API (issue #10): sesión de una versión del plan no vigente.
    if (outdatedPlanSessions.contains(request.planSessionId)) {
      throw _error(409, ApiErrorCode.planSessionOutdated);
    }
    // Como la API: uno en curso sin actividad desde hace más de 12 h se
    // abandona solo; si no, 409 WORKOUT_IN_PROGRESS.
    final cutoff = request.startedAt.subtract(const Duration(hours: 12));
    for (final w in workouts.values.toList()) {
      if (w.status != WorkoutStatus.inProgress) continue;
      var last = w.startedAt;
      for (final set in sets.values) {
        if (set.workoutId == w.id && set.completedAt.isAfter(last)) {
          last = set.completedAt;
        }
      }
      if (last.isBefore(cutoff)) autoAbandon(w.id);
    }
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
    if (enforceSlotExercise && request.planExerciseId != null) {
      final slot = (todayJson['exercises'] as List).cast<Json>().firstWhere(
        (e) => e['planExerciseId'] == request.planExerciseId,
      );
      final original =
          ((slot['substitutedFrom'] ?? slot['exercise']) as Json)['id'];
      String? substituted;
      for (final sub in substitutions) {
        if (sub.workoutId == workoutId &&
            sub.planExerciseId == request.planExerciseId) {
          substituted = sub.exerciseId;
        }
      }
      if (request.exerciseId != original && request.exerciseId != substituted) {
        throw _error(400, ApiErrorCode.validationFailed);
      }
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

  int abandons = 0;

  Workout _withStatus(Workout w, WorkoutStatus status) => Workout(
    id: w.id,
    clientId: w.clientId,
    planSessionId: w.planSessionId,
    status: status,
    startedAt: w.startedAt,
    completedAt: w.completedAt,
    sets: w.sets,
    substitutions: w.substitutions,
  );

  @override
  Future<Workout> abandonWorkout(String workoutId) async {
    _guard('POST /workouts/$workoutId/abandon');
    final w = _byServerId(workoutId);
    if (w == null) throw _error(404, ApiErrorCode.notFound);
    if (w.status == WorkoutStatus.abandoned) return w;
    if (w.status != WorkoutStatus.inProgress) {
      throw _error(409, ApiErrorCode.workoutFinished);
    }
    abandons++;
    return workouts[w.clientId] = _withStatus(w, WorkoutStatus.abandoned);
  }

  /// Simula el abandono automático del servidor (> 12 h sin actividad al
  /// empezar otro entrenamiento).
  void autoAbandon(String workoutId) {
    final w = _byServerId(workoutId)!;
    workouts[w.clientId] = _withStatus(w, WorkoutStatus.abandoned);
  }

  /// Series borradas con `DELETE` (clientId).
  final List<String> deletedSets = [];

  @override
  Future<SetLog> deleteSet(String workoutId, String clientId) async {
    _guard('DELETE /workouts/$workoutId/sets/$clientId');
    final existing = sets[clientId];
    if (_byServerId(workoutId) == null ||
        existing == null ||
        existing.workoutId != workoutId) {
      throw _error(404, ApiErrorCode.notFound);
    }
    if (existing.deletedAt != null) return existing;
    deletedSets.add(clientId);
    final deleted = SetLog.fromJson({
      ...existing.toJson(),
      'deletedAt': '2026-11-09T09:00:00.000Z',
    });
    sets[clientId] = deleted;
    return deleted;
  }

  /// `PATCH` recibidos (clientId, cuerpo).
  final List<({String clientId, PatchSetRequest request})> patches = [];

  @override
  Future<SetLog> patchSet(
    String workoutId,
    String clientId,
    PatchSetRequest request,
  ) async {
    _guard('PATCH /workouts/$workoutId/sets/$clientId');
    final existing = sets[clientId];
    if (_byServerId(workoutId) == null ||
        existing == null ||
        existing.workoutId != workoutId) {
      throw _error(404, ApiErrorCode.notFound);
    }
    patches.add((clientId: clientId, request: request));
    // Gana la última escritura por clientUpdatedAt (como la API).
    if (existing.deletedAt != null ||
        !request.clientUpdatedAt.isAfter(existing.clientUpdatedAt)) {
      return existing;
    }
    final updated = SetLog.fromJson({
      ...existing.toJson(),
      ...request.toJson(),
    });
    sets[clientId] = updated;
    return updated;
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
    if (substituteFailures.isNotEmpty) throw substituteFailures.removeAt(0);
    final w = _byServerId(workoutId);
    if (w == null) {
      throw _error(404, ApiErrorCode.notFound);
    }
    if (w.status != WorkoutStatus.inProgress) {
      throw _error(409, ApiErrorCode.workoutFinished);
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
    final original = (slot['substitutedFrom'] ?? slot['exercise']) as Json;
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

  // ── NotesApi ──
  final Map<String, ExerciseNote> notes = {};
  int notePuts = 0;

  @override
  Future<ExerciseNote> putNote(
    String exerciseId,
    ExerciseNoteRequest request,
  ) async {
    _guard('PUT /exercises/$exerciseId/note');
    notePuts++;
    final existing = notes[exerciseId];
    // Gana la última escritura por clientUpdatedAt (como la API).
    if (existing != null &&
        existing.clientUpdatedAt.isAfter(request.clientUpdatedAt)) {
      return existing;
    }
    final note = ExerciseNote(
      exerciseId: exerciseId,
      slug: 'slug-$exerciseId',
      text: request.text.trim(),
      clientUpdatedAt: request.clientUpdatedAt,
      updatedAt: request.clientUpdatedAt,
    );
    notes[exerciseId] = note;
    _setTodayNote(exerciseId, note.text);
    return note;
  }

  @override
  Future<void> deleteNote(String exerciseId) async {
    _guard('DELETE /exercises/$exerciseId/note');
    notes.remove(exerciseId);
    _setTodayNote(exerciseId, null);
  }

  void _setTodayNote(String exerciseId, String? text) {
    for (final e in (todayJson['exercises'] as List).cast<Json>()) {
      if ((e['exercise'] as Json)['id'] == exerciseId) e['note'] = text;
    }
  }

  @override
  Future<ExerciseNoteList> listNotes() async {
    _guard('GET /me/exercise-notes');
    return ExerciseNoteList(notes.values.toList());
  }

  // ── ScheduleApi ──
  final Map<String, TrainingBreak> breaks = {};
  final List<List<int>> scheduleRequests = [];

  @override
  Future<ProfileResponse> updateSchedule(List<int> trainingWeekdays) async {
    _guard('PATCH /me/profile/schedule');
    scheduleRequests.add(trainingWeekdays);
    if (trainingWeekdays.length > (profileJson['daysPerWeek'] as int)) {
      throw _error(422, ApiErrorCode.validationFailed);
    }
    profileJson = {...profileJson, 'trainingWeekdays': trainingWeekdays};
    return ProfileResponse.fromJson(profileJson);
  }

  @override
  Future<TrainingBreakList> listBreaks({String? from}) async {
    _guard('GET /me/breaks');
    return TrainingBreakList(
      breaks.values
          .where((b) => from == null || b.endsOn.compareTo(from) >= 0)
          .toList(),
    );
  }

  @override
  Future<Upserted<TrainingBreak>> createBreak(
    CreateTrainingBreakRequest request,
  ) async {
    _guard('POST /me/breaks');
    for (final b in breaks.values) {
      if (b.clientId == request.clientId) return Upserted(b, created: false);
    }
    final b = TrainingBreak(
      id: 'brk-${breaks.length + 1}',
      clientId: request.clientId,
      startsOn: request.startsOn,
      endsOn: request.endsOn,
      createdAt: DateTime.utc(2026, 11, 9, 8),
    );
    breaks[b.id] = b;
    return Upserted(b, created: true);
  }

  @override
  Future<void> deleteBreak(String id) async {
    _guard('DELETE /me/breaks/$id');
    breaks.remove(id);
  }

  // ── BodyApi ──
  final Map<String, BodyMeasurement> measurements = {};
  Json bodyProgressJson = fixture('body_progress');

  @override
  Future<BodyMeasurementRecord> putMeasurement(
    BodyMeasurement measurement,
  ) async {
    _guard('PUT /me/measurements');
    final consent = HealthConsentStatus.fromJson(
      profileJson['healthConsent'] as Json,
    );
    final needed = {for (final f in measurement.values.keys) f.scope};
    if (!needed.every(consent.covers)) {
      throw _error(409, ApiErrorCode.healthConsentRequired);
    }
    measurements[measurement.measuredOn] = measurement;
    return BodyMeasurementRecord(
      measurement: measurement,
      updatedAt: DateTime.utc(2026, 11, 9, 8),
    );
  }

  @override
  Future<BodyMeasurementList> listMeasurements({
    String? from,
    String? to,
  }) async {
    _guard('GET /me/measurements');
    final items = measurements.values.toList()
      ..sort((a, b) => b.measuredOn.compareTo(a.measuredOn));
    return BodyMeasurementList([
      for (final m in items)
        BodyMeasurementRecord(
          measurement: m,
          updatedAt: DateTime.utc(2026, 11, 9, 8),
        ),
    ]);
  }

  @override
  Future<void> deleteMeasurement(String date) async {
    _guard('DELETE /me/measurements/$date');
    measurements.remove(date);
  }

  @override
  Future<BodyProgress> getBodyProgress() async {
    _guard('GET /progress/body');
    return BodyProgress.fromJson(bodyProgressJson);
  }

  /// Overrides de Riverpod que conectan todas las interfaces a este fake.
  List<Override> get overrides => [
    profileApiProvider.overrideWithValue(this),
    planApiProvider.overrideWithValue(this),
    if (!useHttpWorkoutApi) workoutApiProvider.overrideWithValue(this),
    progressApiProvider.overrideWithValue(this),
    accountApiProvider.overrideWithValue(this),
    catalogApiProvider.overrideWithValue(this),
    notesApiProvider.overrideWithValue(this),
    scheduleApiProvider.overrideWithValue(this),
    bodyApiProvider.overrideWithValue(this),
  ];
}
