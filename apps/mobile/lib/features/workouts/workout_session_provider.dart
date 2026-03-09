import 'package:dio/dio.dart';
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
  /// State transitions to active only after both succeed.
  /// On exercise-add failure, state goes to error with retry info.
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

    // Add all exercises — if any fails, abort to error
    final exercises = <WorkoutExercise>[];
    try {
      for (final planExercise in planSession.exercises) {
        final resp = await _api.post(
          '/workouts/${session.id}/exercises',
          data: {'exerciseId': planExercise.exerciseId},
        );
        exercises.add(
          WorkoutExercise.fromJson(resp.data as Map<String, dynamic>),
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

    final fullSession = WorkoutSession(
      id: session.id,
      userId: session.userId,
      planSessionId: session.planSessionId,
      planVersionId: session.planVersionId,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      durationMinutes: session.durationMinutes,
      notes: session.notes,
      exercises: exercises,
    );

    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: fullSession,
      planSession: planSession,
    );
    return true;
  }

  /// Resume an incomplete workout detected from history.
  void resumeWorkout(WorkoutSession session) {
    state = WorkoutSessionState(
      status: WorkoutStatus.active,
      session: session,
      resumedSession: true,
    );
  }

  /// Check for an incomplete workout via GET /workouts/history.
  Future<WorkoutSession?> checkForActiveWorkout() async {
    try {
      final response = await _api.get('/workouts/history');
      final list = (response.data as List<dynamic>)
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.where((w) => w.completedAt == null).firstOrNull;
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
      final newSet = WorkoutSet.fromJson(
        response.data as Map<String, dynamic>,
      );

      _updateExerciseWithSet(workoutExerciseId, newSet);
      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(error: failure.message);
      return false;
    }
  }

  void _updateExerciseWithSet(String workoutExerciseId, WorkoutSet newSet) {
    if (state.session == null) return;

    final updatedExercises = state.session!.exercises.map((ex) {
      if (ex.id != workoutExerciseId) return ex;
      return WorkoutExercise(
        id: ex.id,
        workoutSessionId: ex.workoutSessionId,
        exerciseId: ex.exerciseId,
        order: ex.order,
        sets: [...ex.sets, newSet],
      );
    }).toList();

    state = state.copyWith(
      session: WorkoutSession(
        id: state.session!.id,
        userId: state.session!.userId,
        planSessionId: state.session!.planSessionId,
        planVersionId: state.session!.planVersionId,
        startedAt: state.session!.startedAt,
        completedAt: state.session!.completedAt,
        durationMinutes: state.session!.durationMinutes,
        notes: state.session!.notes,
        exercises: updatedExercises,
      ),
    );
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
