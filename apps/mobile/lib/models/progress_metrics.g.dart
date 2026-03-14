// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressMetricsImpl _$$ProgressMetricsImplFromJson(
        Map<String, dynamic> json) =>
    _$ProgressMetricsImpl(
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseProgressItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      adherenceScore: (json['adherenceScore'] as num?)?.toDouble(),
      fatigueDetected: json['fatigueDetected'] as bool,
    );

Map<String, dynamic> _$$ProgressMetricsImplToJson(
        _$ProgressMetricsImpl instance) =>
    <String, dynamic>{
      'exercises': instance.exercises,
      'adherenceScore': instance.adherenceScore,
      'fatigueDetected': instance.fatigueDetected,
    };

_$ExerciseProgressItemImpl _$$ExerciseProgressItemImplFromJson(
        Map<String, dynamic> json) =>
    _$ExerciseProgressItemImpl(
      exerciseId: json['exerciseId'] as String,
      estimated1RM: (json['estimated1RM'] as num?)?.toDouble(),
      volumeLastWeek: (json['volumeLastWeek'] as num?)?.toDouble(),
      volumeTrend: json['volumeTrend'] as String?,
      fatigueScore: (json['fatigueScore'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] as String?,
    );

Map<String, dynamic> _$$ExerciseProgressItemImplToJson(
        _$ExerciseProgressItemImpl instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'estimated1RM': instance.estimated1RM,
      'volumeLastWeek': instance.volumeLastWeek,
      'volumeTrend': instance.volumeTrend,
      'fatigueScore': instance.fatigueScore,
      'lastUpdated': instance.lastUpdated,
    };
