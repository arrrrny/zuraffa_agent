// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_agent_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubAgentType _$SubAgentTypeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubAgentType', json, ($checkedConvert) {
      final val = SubAgentType(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        specRef: $checkedConvert('specRef', (v) => v as String),
        allowlist: $checkedConvert(
          'allowlist',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        budgetProfile: $checkedConvert('budgetProfile', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SubAgentTypeToJson(SubAgentType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'specRef': instance.specRef,
      'allowlist': instance.allowlist,
      'budgetProfile': instance.budgetProfile,
    };
