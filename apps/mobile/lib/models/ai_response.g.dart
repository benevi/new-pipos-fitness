// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIResponseImpl _$$AIResponseImplFromJson(Map<String, dynamic> json) =>
    _$AIResponseImpl(
      responseType: json['responseType'] as String,
      content: json['content'] as String,
      proposal: json['proposal'] as Map<String, dynamic>?,
      proposalStatus: json['proposalStatus'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$$AIResponseImplToJson(_$AIResponseImpl instance) =>
    <String, dynamic>{
      'responseType': instance.responseType,
      'content': instance.content,
      'proposal': instance.proposal,
      'proposalStatus': instance.proposalStatus,
      'rejectionReason': instance.rejectionReason,
    };
