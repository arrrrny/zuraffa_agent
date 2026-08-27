// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentSpec _$AgentSpecFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentSpec', json, ($checkedConvert) {
      final val = AgentSpec(
        id: $checkedConvert('id', (v) => v as String),
        tools: $checkedConvert(
          'tools',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        subagents: $checkedConvert(
          'subagents',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        budget: $checkedConvert('budget', (v) => v as String),
        systemPrompt: $checkedConvert('systemPrompt', (v) => v as String),
        riskTier: $checkedConvert('riskTier', (v) => v as String),
        extendsSpec: $checkedConvert('extendsSpec', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AgentSpecToJson(AgentSpec instance) => <String, dynamic>{
  'id': instance.id,
  'tools': instance.tools,
  'subagents': instance.subagents,
  'budget': instance.budget,
  'systemPrompt': instance.systemPrompt,
  'riskTier': instance.riskTier,
  'extendsSpec': instance.extendsSpec,
};
