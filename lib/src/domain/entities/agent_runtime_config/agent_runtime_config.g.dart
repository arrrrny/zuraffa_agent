// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_runtime_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentRuntimeConfig _$AgentRuntimeConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentRuntimeConfig', json, ($checkedConvert) {
      final val = AgentRuntimeConfig(
        modelProvider: $checkedConvert('modelProvider', (v) => v as String),
        modelId: $checkedConvert('modelId', (v) => v as String),
        systemPrompt: $checkedConvert('systemPrompt', (v) => v as String?),
        thinkingLevel: $checkedConvert('thinkingLevel', (v) => v as String?),
        toolNames: $checkedConvert(
          'toolNames',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AgentRuntimeConfigToJson(AgentRuntimeConfig instance) =>
    <String, dynamic>{
      'modelProvider': instance.modelProvider,
      'modelId': instance.modelId,
      'systemPrompt': ?instance.systemPrompt,
      'thinkingLevel': ?instance.thinkingLevel,
      'toolNames': instance.toolNames,
    };
