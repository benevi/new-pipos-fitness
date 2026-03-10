import 'package:freezed_annotation/freezed_annotation.dart';

part 'volume_metrics.freezed.dart';
part 'volume_metrics.g.dart';

@freezed
class VolumeMetrics with _$VolumeMetrics {
  const factory VolumeMetrics({
    required List<VolumeByExercise> byExercise,
    required List<VolumeByMuscle> byMuscle,
    String? weekStart,
    String? weekEnd,
  }) = _VolumeMetrics;

  factory VolumeMetrics.fromJson(Map<String, dynamic> json) =>
      _$VolumeMetricsFromJson(json);
}

@freezed
class VolumeByExercise with _$VolumeByExercise {
  const factory VolumeByExercise({
    required String exerciseId,
    required double volume,
  }) = _VolumeByExercise;

  factory VolumeByExercise.fromJson(Map<String, dynamic> json) =>
      _$VolumeByExerciseFromJson(json);
}

@freezed
class VolumeByMuscle with _$VolumeByMuscle {
  const factory VolumeByMuscle({
    required String muscleId,
    required double volume,
  }) = _VolumeByMuscle;

  factory VolumeByMuscle.fromJson(Map<String, dynamic> json) =>
      _$VolumeByMuscleFromJson(json);
}
