import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_failure.dart';
import '../../core/api/dio_error_mapper.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

enum WorkoutStatus { idle, active, finishing, completed, error }

class WorkoutSessionState {
  final WorkoutStatus status;
  final WorkoutSession? session;
  final TrainingSession? planSession;
  final int currentExerciseIndex;
  final String? error;

  const WorkoutSessionState({
    this.status = WorkoutStatus.idle,
    this.session,
    this.planSession,
    this.currentExerciseIndex = 0,
    this.error,
  });

  bool get isActive => status == WorkoutStatus.active;
  bool get isCompleted => status == WorkoutStatus.completed;

  int get totalExercises => planSession?.exercises.length ?? 0;

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
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      session: session ?? this.session,
      planSession: planSession ?? this.planSession,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      error: error,
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

  Future<bool> startWorkout(TrainingSession planSession) async {
    if (state.isActive) return false;

    try {
      final response = await _api.post(
        '/workouts/start',
        data: {'planSessionId': planSession.id},
      );
      final session = WorkoutSession.fromJson(
        response.data as Map<String, dynamic>,
      );

      state = WorkoutSessionState(
        status: WorkoutStatus.active,
        session: session,
        planSession: planSession,
        currentExerciseIndex: 0,
      );

      // Add all exercises from the plan to the workout session
      for (final exercise in planSession.exercises) {
        await _addExercise(session.id, exercise.exerciseId);
      }

      return true;
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(status: WorkoutStatus.error, error: failure.message);
      return false;
    }
  }

  Future<void> _addExercise(String sessionId, String exerciseId) async {
    try {
      final response = await _api.post(
        '/workouts/$sessionId/exercises',
        data: {'exerciseId': exerciseId},
      );
      final exercise = WorkoutExercise.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (state.session == null) return;
      final updatedExercises = [...state.session!.exercises, exercise];
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
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(error: failure.message);
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
