// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconnect_policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReconnectPolicy _$ReconnectPolicyFromJson(Map<String, dynamic> json) =>
    ReconnectPolicy(
      baseDelayMs: (json['baseDelayMs'] as num).toInt(),
      maxDelayMs: (json['maxDelayMs'] as num).toInt(),
      multiplier: (json['multiplier'] as num).toDouble(),
      jitterFactor: (json['jitterFactor'] as num).toDouble(),
      maxRetries: (json['maxRetries'] as num).toInt(),
    );

Map<String, dynamic> _$ReconnectPolicyToJson(ReconnectPolicy instance) =>
    <String, dynamic>{
      'baseDelayMs': instance.baseDelayMs,
      'maxDelayMs': instance.maxDelayMs,
      'multiplier': instance.multiplier,
      'jitterFactor': instance.jitterFactor,
      'maxRetries': instance.maxRetries,
    };
