// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planSessionId: json['planSessionId'] as String?,
      planVersionId: json['planVersionId'] as String?,
      startedAt: json['startedAt'] as String,
      completedAt: json['completedAt'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'planSessionId': instance.planSessionId,
      'planVersionId': instance.planVersionId,
      'startedAt': instance.startedAt,
      'completedAt': instance.completedAt,
      'durationMinutes': instance.durationMinutes,
      'notes': instance.notes,
      'exercises': instance.exercises,
    };

_$WorkoutExerciseImpl _$$WorkoutExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkoutExerciseImpl(
      id: json['id'] as String,
      workoutSessionId: json['workoutSessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      order: (json['order'] as num).toInt(),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WorkoutExerciseImplToJson(
        _$WorkoutExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutSessionId': instance.workoutSessionId,
      'exerciseId': instance.exerciseId,
      'order': instance.order,
      'sets': instance.sets,
    };

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      id: json['id'] as String,
      workoutExerciseId: json['workoutExerciseId'] as String,
      setIndex: (json['setIndex'] as num).toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      rir: (json['rir'] as num?)?.toInt(),
      completed: json['completed'] as bool,
    );

Map<String, dynamic> _$$WorkoutSetImplToJson(_$WorkoutSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutExerciseId': instance.workoutExerciseId,
      'setIndex': instance.setIndex,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'rir': instance.rir,
      'completed': instance.completed,
    };
