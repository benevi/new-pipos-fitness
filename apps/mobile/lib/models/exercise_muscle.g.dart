// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_muscle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseMuscleImpl _$$ExerciseMuscleImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseMuscleImpl(
      exerciseId: json['exerciseId'] as String,
      muscleId: json['muscleId'] as String,
      role: json['role'] as String,
      muscle: json['muscle'] == null
          ? null
          : Muscle.fromJson(json['muscle'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ExerciseMuscleImplToJson(
        _$ExerciseMuscleImpl instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'muscleId': instance.muscleId,
      'role': instance.role,
      'muscle': instance.muscle,
    };
