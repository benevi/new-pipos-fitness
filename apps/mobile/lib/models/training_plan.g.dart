// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrainingPlanImpl _$$TrainingPlanImplFromJson(Map<String, dynamic> json) =>
    _$TrainingPlanImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      currentVersionId: json['currentVersionId'] as String?,
      version:
          TrainingPlanVersion.fromJson(json['version'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TrainingPlanImplToJson(_$TrainingPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'currentVersionId': instance.currentVersionId,
      'version': instance.version,
    };

_$TrainingPlanVersionImpl _$$TrainingPlanVersionImplFromJson(
        Map<String, dynamic> json) =>
    _$TrainingPlanVersionImpl(
      id: json['id'] as String,
      planId: json['planId'] as String,
      version: (json['version'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      engineVersion: json['engineVersion'] as String,
      objectiveScore: (json['objectiveScore'] as num).toDouble(),
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TrainingPlanVersionImplToJson(
        _$TrainingPlanVersionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planId': instance.planId,
      'version': instance.version,
      'createdAt': instance.createdAt,
      'engineVersion': instance.engineVersion,
      'objectiveScore': instance.objectiveScore,
      'sessions': instance.sessions,
    };

_$TrainingSessionImpl _$$TrainingSessionImplFromJson(
        Map<String, dynamic> json) =>
    _$TrainingSessionImpl(
      id: json['id'] as String,
      planVersionId: json['planVersionId'] as String,
      sessionIndex: (json['sessionIndex'] as num).toInt(),
      name: json['name'] as String,
      targetDurationMinutes: (json['targetDurationMinutes'] as num).toInt(),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) =>
              TrainingSessionExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TrainingSessionImplToJson(
        _$TrainingSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'planVersionId': instance.planVersionId,
      'sessionIndex': instance.sessionIndex,
      'name': instance.name,
      'targetDurationMinutes': instance.targetDurationMinutes,
      'exercises': instance.exercises,
    };

_$TrainingSessionExerciseImpl _$$TrainingSessionExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$TrainingSessionExerciseImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as num).toInt(),
      repRangeMin: (json['repRangeMin'] as num).toInt(),
      repRangeMax: (json['repRangeMax'] as num).toInt(),
      restSeconds: (json['restSeconds'] as num).toInt(),
      rirTarget: (json['rirTarget'] as num).toInt(),
    );

Map<String, dynamic> _$$TrainingSessionExerciseImplToJson(
        _$TrainingSessionExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'exerciseId': instance.exerciseId,
      'sets': instance.sets,
      'repRangeMin': instance.repRangeMin,
      'repRangeMax': instance.repRangeMax,
      'restSeconds': instance.restSeconds,
      'rirTarget': instance.rirTarget,
    };
