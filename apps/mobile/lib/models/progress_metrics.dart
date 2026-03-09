import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_metrics.freezed.dart';
part 'progress_metrics.g.dart';

@freezed
class ProgressMetrics with _$ProgressMetrics {
  const factory ProgressMetrics({
    required List<ExerciseProgressItem> exercises,
    required double? adherenceScore,
    required bool fatigueDetected,
  }) = _ProgressMetrics;

  factory ProgressMetrics.fromJson(Map<String, dynamic> json) =>
      _$ProgressMetricsFromJson(json);
}

@freezed
class ExerciseProgressItem with _$ExerciseProgressItem {
  const factory ExerciseProgressItem({
    required String exerciseId,
    double? estimated1RM,
    double? volumeLastWeek,
    String? volumeTrend,
    double? fatigueScore,
    String? lastUpdated,
  }) = _ExerciseProgressItem;

  factory ExerciseProgressItem.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressItemFromJson(json);
}
