// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restart_policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestartPolicy _$RestartPolicyFromJson(Map<String, dynamic> json) =>
    RestartPolicy(
      maxRetries: (json['maxRetries'] as num).toInt(),
      backoffDelaysMs: (json['backoffDelaysMs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RestartPolicyToJson(RestartPolicy instance) =>
    <String, dynamic>{
      'maxRetries': instance.maxRetries,
      'backoffDelaysMs': instance.backoffDelaysMs,
    };
