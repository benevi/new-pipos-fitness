import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_plan.freezed.dart';
part 'training_plan.g.dart';

@freezed
class TrainingPlan with _$TrainingPlan {
  const factory TrainingPlan({
    required String id,
    required String userId,
    required String? currentVersionId,
    required TrainingPlanVersion version,
  }) = _TrainingPlan;

  factory TrainingPlan.fromJson(Map<String, dynamic> json) =>
      _$TrainingPlanFromJson(json);
}

@freezed
class TrainingPlanVersion with _$TrainingPlanVersion {
  const factory TrainingPlanVersion({
    required String id,
    required String planId,
    required int version,
    required String createdAt,
    required String engineVersion,
    required double objectiveScore,
    required List<TrainingSession> sessions,
  }) = _TrainingPlanVersion;

  factory TrainingPlanVersion.fromJson(Map<String, dynamic> json) =>
      _$TrainingPlanVersionFromJson(json);
}

@freezed
class TrainingSession with _$TrainingSession {
  const factory TrainingSession({
    required String id,
    required String planVersionId,
    required int sessionIndex,
    required String name,
    required int targetDurationMinutes,
    required List<TrainingSessionExercise> exercises,
  }) = _TrainingSession;

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionFromJson(json);
}

@freezed
class TrainingSessionExercise with _$TrainingSessionExercise {
  const factory TrainingSessionExercise({
    required String id,
    required String sessionId,
    required String exerciseId,
    required int sets,
    required int repRangeMin,
    required int repRangeMax,
    required int restSeconds,
    required int rirTarget,
  }) = _TrainingSessionExercise;

  factory TrainingSessionExercise.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionExerciseFromJson(json);
}
