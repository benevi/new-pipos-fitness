// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'muscle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MuscleImpl _$$MuscleImplFromJson(Map<String, dynamic> json) => _$MuscleImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      region: json['region'] as String,
      meshRegionId: json['meshRegionId'] as String?,
    );

Map<String, dynamic> _$$MuscleImplToJson(_$MuscleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'region': instance.region,
      'meshRegionId': instance.meshRegionId,
    };
