// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_policy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StopPolicy _$StopPolicyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StopPolicy', json, ($checkedConvert) {
      final val = StopPolicy(
        id: $checkedConvert('id', (v) => v as String?),
        maxTurns: $checkedConvert('maxTurns', (v) => (v as num).toInt()),
        wallClockTimeoutMs: $checkedConvert(
          'wallClockTimeoutMs',
          (v) => (v as num).toInt(),
        ),
        repetitionThreshold: $checkedConvert(
          'repetitionThreshold',
          (v) => (v as num).toInt(),
        ),
        enabled: $checkedConvert('enabled', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$StopPolicyToJson(StopPolicy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'maxTurns': instance.maxTurns,
      'wallClockTimeoutMs': instance.wallClockTimeoutMs,
      'repetitionThreshold': instance.repetitionThreshold,
      'enabled': instance.enabled,
    };
