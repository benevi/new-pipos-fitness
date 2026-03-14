import 'package:freezed_annotation/freezed_annotation.dart';
import 'exercise_media.dart';
import 'exercise_muscle.dart';

part 'exercise_detail.freezed.dart';
part 'exercise_detail.g.dart';

@freezed
class ExerciseDetail with _$ExerciseDetail {
  const factory ExerciseDetail({
    required String id,
    required String slug,
    required String name,
    String? description,
    required int difficulty,
    String? movementPattern,
    required String place,
    @Default([]) List<ExerciseMuscle> muscles,
    @Default([]) List<ExerciseMedia> media,
  }) = _ExerciseDetail;

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDetailFromJson(json);
}
