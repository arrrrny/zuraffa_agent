// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_tool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentTool _$AgentToolFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentTool', json, ($checkedConvert) {
      final val = AgentTool(
        id: $checkedConvert('id', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        inputSchema: $checkedConvert(
          'inputSchema',
          (v) => v as Map<String, dynamic>,
        ),
        riskTier: $checkedConvert(
          'riskTier',
          (v) => $enumDecode(_$RiskTierEnumMap, v),
        ),
        executionMode: $checkedConvert(
          'executionMode',
          (v) => $enumDecode(_$ExecutionModeEnumMap, v),
        ),
        source: $checkedConvert(
          'source',
          (v) => $enumDecode(_$ToolSourceEnumMap, v),
        ),
        transportBinding: $checkedConvert(
          'transportBinding',
          (v) => v as String?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AgentToolToJson(AgentTool instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'inputSchema': instance.inputSchema,
  'riskTier': _$RiskTierEnumMap[instance.riskTier]!,
  'executionMode': _$ExecutionModeEnumMap[instance.executionMode]!,
  'source': _$ToolSourceEnumMap[instance.source]!,
  'transportBinding': ?instance.transportBinding,
};

const _$RiskTierEnumMap = {
  RiskTier.safe: 'safe',
  RiskTier.confirm: 'confirm',
  RiskTier.admin: 'admin',
};

const _$ExecutionModeEnumMap = {
  ExecutionMode.sequential: 'sequential',
  ExecutionMode.parallel: 'parallel',
};

const _$ToolSourceEnumMap = {
  ToolSource.dda: 'dda',
  ToolSource.generated: 'generated',
  ToolSource.mcp: 'mcp',
};
