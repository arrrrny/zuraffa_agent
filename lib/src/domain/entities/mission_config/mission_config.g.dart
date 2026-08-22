// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissionConfig _$MissionConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissionConfig', json, ($checkedConvert) {
      final val = MissionConfig(
        id: $checkedConvert('id', (v) => v as String?),
        missionId: $checkedConvert('missionId', (v) => v as String),
        initialPrompt: $checkedConvert('initialPrompt', (v) => v as String),
        availableTools: $checkedConvert(
          'availableTools',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        metadata: $checkedConvert('metadata', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

Map<String, dynamic> _$MissionConfigToJson(MissionConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'missionId': instance.missionId,
      'initialPrompt': instance.initialPrompt,
      'availableTools': instance.availableTools,
      'metadata': instance.metadata,
    };
