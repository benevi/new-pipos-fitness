import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/dio_error_mapper.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

enum WorkoutStatus { idle, starting, active, finishing, completed, error }

class WorkoutSessionState {
  final WorkoutStatus status;
  final WorkoutSession? session;
  final TrainingSession? planSession;
  final int currentExerciseIndex;
  final String? error;
  final bool resumedSession;

  const WorkoutSessionState({
    this.status = WorkoutStatus.idle,
    this.session,
    this.planSession,
    this.currentExerciseIndex = 0,
    this.error,
    this.resumedSession = false,
  });

  bool get isActive => status == WorkoutStatus.active;
  bool get isStarting => status == WorkoutStatus.starting;
  bool get isCompleted => status == WorkoutStatus.completed;

  String? get sessionId => session?.id;
  String? get startedAt => session?.startedAt;

  int get totalExercises =>
      planSession?.exercises.length ?? session?.exercises.length ?? 0;

  List<WorkoutSet> setsForExercise(String workoutExerciseId) {
    final ex = session?.exercises
        .where((e) => e.id == workoutExerciseId)
        .firstOrNull;
    return ex?.sets ?? [];
  }

  WorkoutSessionState copyWith({
    WorkoutStatus? status,
    WorkoutSession? session,
    TrainingSession? planSession,
    int? currentExerciseIndex,
    String? error,
    bool? resumedSession,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      planSession: planSession ?? this.planSession,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      error: error,
      resumedSession: resumedSession ?? this.resumedSession,
    );
  }
}

final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>(
  (ref) => WorkoutSessionNotifier(ref),
);

class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final Ref _ref;

  WorkoutSessionNotifier(this._ref) : super(const WorkoutSessionState());

  ApiClient get _api => _ref.read(apiClientProvider);

  /// Atomic start: creates session + adds all exercises.
  /// State becomes active only after both steps succeed.
  Future<bool> startWorkout(TrainingSession planSession) async {
    if (state.isActive || state.isStarting) return false;

    state = WorkoutSessionState(
      status: WorkoutStatus.starting,
      planSession: planSession,
    );

    WorkoutSession session;
    try {
      final response = await _api.post(
        '/workouts/start',
        data: {'planSessionId': planSession.id},
      );
      session = WorkoutSession.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        error: failure.message,
      );
      return false;
    }

    // Add all exercises; each call returns the full updated session
    try {
      for (final planExercise in planSession.exercises) {
        final resp = await _api.post(
          '/workouts/${session.id}/exercises',
          data: {'exerciseId': planExercise.exerciseId},
        );
        session = WorkoutSession.fromJson(
          resp.data as Map<String, dynamic>,
        );
      }
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        session: session,
        error: 'Failed to add exercises: ${failure.message}',
      );
      return false;
    }

    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: session,
      planSession: planSession,
    );
    return true;
  }

  /// Retry adding remaining exercises after a partial start failure.
  /// Fetches current session state, determines missing exercises, adds them.
  Future<bool> retryAddExercises() async {
    if (state.session == null || state.planSession == null) return false;
    if (state.status != WorkoutStatus.error) return false;

    final sessionId = state.session!.id;
    final planSession = state.planSession!;

    state = state.copyWith(status: WorkoutStatus.starting, error: null);

    WorkoutSession current;
    try {
      final resp = await _api.get('/workouts/$sessionId');
      current = WorkoutSession.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(
        status: WorkoutStatus.error,
        error: 'Failed to load session: ${failure.message}',
      );
      return false;
    }

    final existingExerciseIds =
        current.exercises.map((e) => e.exerciseId).toSet();
    final missing = planSession.exercises
        .where((pe) => !existingExerciseIds.contains(pe.exerciseId))
        .toList();

    try {
      for (final planExercise in missing) {
        final resp = await _api.post(
          '/workouts/$sessionId/exercises',
          data: {'exerciseId': planExercise.exerciseId},
        );
        current = WorkoutSession.fromJson(
          resp.data as Map<String, dynamic>,
        );
      }
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = WorkoutSessionState(
        status: WorkoutStatus.error,
        planSession: planSession,
        session: current,
        error: 'Failed to add exercises: ${failure.message}',
      );
      return false;
    }

    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: current,
      planSession: planSession,
    );
    return true;
  }

  /// Resume an incomplete workout by fetching its full state from the server.
  Future<bool> resumeWorkout(String sessionId) async {
    try {
      final resp = await _api.get('/workouts/$sessionId');
      final session = WorkoutSession.fromJson(
        resp.data as Map<String, dynamic>,
      );

      // Restore currentExerciseIndex: first exercise with fewer completed sets
      // than expected, or the last exercise
      final exerciseIndex = _computeResumeIndex(session);

      state = WorkoutSessionState(
        status: WorkoutStatus.active,
        session: session,
        resumedSession: true,
        currentExerciseIndex: exerciseIndex,
      );
      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(error: 'Failed to resume: ${failure.message}');
      return false;
    }
  }

  /// Find the first exercise that has no sets, or the last one if all have sets.
  int _computeResumeIndex(WorkoutSession session) {
    if (session.exercises.isEmpty) return 0;
    for (int i = 0; i < session.exercises.length; i++) {
      if (session.exercises[i].sets.isEmpty) return i;
    }
    return session.exercises.length - 1;
  }

  /// Check for incomplete workouts via GET /workouts/history.
  /// Returns the most recent incomplete session, warns in debug if multiple.
  Future<WorkoutSession?> checkForActiveWorkout() async {
    try {
      final response = await _api.get('/workouts/history');
      final list = (response.data as List<dynamic>)
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();

      final incomplete = list.where((w) => w.completedAt == null).toList();
      if (incomplete.isEmpty) return null;

      if (incomplete.length > 1) {
        debugPrint(
          'WARNING: ${incomplete.length} incomplete workout sessions found. '
          'Resuming most recent.',
        );
      }

      // History is ordered by startedAt desc, so first is most recent
      return incomplete.first;
    } catch (_) {
      return null;
    }
  }

  Future<bool> logSet({
    required String workoutExerciseId,
    double? weightKg,
    int? reps,
    int? rir,
  }) async {
    if (state.session == null) return false;

    try {
      final response = await _api.post(
        '/workouts/${state.session!.id}/exercises/$workoutExerciseId/sets',
        data: {
          if (weightKg != null) 'weightKg': weightKg,
          if (reps != null) 'reps': reps,
          if (rir != null) 'rir': rir,
          'completed': true,
        },
      );
      // Backend returns the full updated session
      final updated = WorkoutSession.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(session: updated);
      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(error: failure.message);
      return false;
    }
  }

  void nextExercise() {
    if (state.currentExerciseIndex < state.totalExercises - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
      );
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
      );
    }
  }

  Future<bool> finishWorkout({int? durationMinutes, String? notes}) async {
    if (state.session == null) return false;

    state = state.copyWith(status: WorkoutStatus.finishing);

    try {
      await _api.post(
        '/workouts/${state.session!.id}/finish',
        data: {
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (notes != null) 'notes': notes,
        },
      );

      state = state.copyWith(status: WorkoutStatus.completed);
      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(
        status: WorkoutStatus.active,
        error: failure.message,
      );
      return false;
    }
  }

  void reset() {
    state = const WorkoutSessionState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
