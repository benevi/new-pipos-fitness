// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseMediaImpl _$$ExerciseMediaImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseMediaImpl(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      youtubeVideoId: json['youtubeVideoId'] as String,
      channelName: json['channelName'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      startSeconds: (json['startSeconds'] as num?)?.toInt(),
      endSeconds: (json['endSeconds'] as num?)?.toInt(),
      curationStatus: json['curationStatus'] as String?,
    );

Map<String, dynamic> _$$ExerciseMediaImplToJson(_$ExerciseMediaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'youtubeVideoId': instance.youtubeVideoId,
      'channelName': instance.channelName,
      'isPrimary': instance.isPrimary,
      'startSeconds': instance.startSeconds,
      'endSeconds': instance.endSeconds,
      'curationStatus': instance.curationStatus,
    };
