import 'package:freezed_annotation/freezed_annotation.dart';
import 'muscle.dart';

part 'exercise_muscle.freezed.dart';
part 'exercise_muscle.g.dart';

@freezed
class ExerciseMuscle with _$ExerciseMuscle {
  const factory ExerciseMuscle({
    required String exerciseId,
    required String muscleId,
    required String role,
    Muscle? muscle,
  }) = _ExerciseMuscle;

  factory ExerciseMuscle.fromJson(Map<String, dynamic> json) =>
      _$ExerciseMuscleFromJson(json);
}
