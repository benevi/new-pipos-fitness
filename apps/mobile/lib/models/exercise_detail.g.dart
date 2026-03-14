// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseDetailImpl _$$ExerciseDetailImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseDetailImpl(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      difficulty: (json['difficulty'] as num).toInt(),
      movementPattern: json['movementPattern'] as String?,
      place: json['place'] as String,
      muscles: (json['muscles'] as List<dynamic>?)
              ?.map((e) => ExerciseMuscle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => ExerciseMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ExerciseDetailImplToJson(
        _$ExerciseDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'description': instance.description,
      'difficulty': instance.difficulty,
      'movementPattern': instance.movementPattern,
      'place': instance.place,
      'muscles': instance.muscles,
      'media': instance.media,
    };
