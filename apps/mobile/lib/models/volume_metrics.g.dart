// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VolumeMetricsImpl _$$VolumeMetricsImplFromJson(Map<String, dynamic> json) =>
    _$VolumeMetricsImpl(
      byExercise: (json['byExercise'] as List<dynamic>)
          .map((e) => VolumeByExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      byMuscle: (json['byMuscle'] as List<dynamic>)
          .map((e) => VolumeByMuscle.fromJson(e as Map<String, dynamic>))
          .toList(),
      weekStart: json['weekStart'] as String?,
      weekEnd: json['weekEnd'] as String?,
    );

Map<String, dynamic> _$$VolumeMetricsImplToJson(_$VolumeMetricsImpl instance) =>
    <String, dynamic>{
      'byExercise': instance.byExercise,
      'byMuscle': instance.byMuscle,
      'weekStart': instance.weekStart,
      'weekEnd': instance.weekEnd,
    };

_$VolumeByExerciseImpl _$$VolumeByExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$VolumeByExerciseImpl(
      exerciseId: json['exerciseId'] as String,
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$$VolumeByExerciseImplToJson(
        _$VolumeByExerciseImpl instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'volume': instance.volume,
    };

_$VolumeByMuscleImpl _$$VolumeByMuscleImplFromJson(Map<String, dynamic> json) =>
    _$VolumeByMuscleImpl(
      muscleId: json['muscleId'] as String,
      volume: (json['volume'] as num).toDouble(),
    );

Map<String, dynamic> _$$VolumeByMuscleImplToJson(
        _$VolumeByMuscleImpl instance) =>
    <String, dynamic>{
      'muscleId': instance.muscleId,
      'volume': instance.volume,
    };
