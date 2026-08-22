// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientHealth _$ClientHealthFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClientHealth', json, ($checkedConvert) {
      final val = ClientHealth(
        id: $checkedConvert('id', (v) => v as String?),
        state: $checkedConvert('state', (v) => v as String),
        consecutiveFailures: $checkedConvert(
          'consecutiveFailures',
          (v) => (v as num).toInt(),
        ),
        cooldownWindowMs: $checkedConvert(
          'cooldownWindowMs',
          (v) => (v as num).toInt(),
        ),
        lastFailureAt: $checkedConvert(
          'lastFailureAt',
          (v) => DateTime.parse(v as String),
        ),
        isHealthy: $checkedConvert('isHealthy', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ClientHealthToJson(ClientHealth instance) =>
    <String, dynamic>{
      'id': instance.id,
      'state': instance.state,
      'consecutiveFailures': instance.consecutiveFailures,
      'cooldownWindowMs': instance.cooldownWindowMs,
      'lastFailureAt': instance.lastFailureAt.toIso8601String(),
      'isHealthy': instance.isHealthy,
    };
