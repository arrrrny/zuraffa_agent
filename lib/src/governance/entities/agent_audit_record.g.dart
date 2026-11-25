// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_audit_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentAuditRecord _$AgentAuditRecordFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentAuditRecord', json, ($checkedConvert) {
      final val = AgentAuditRecord(
        id: $checkedConvert('id', (v) => v as String),
        at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        phase: $checkedConvert('phase', (v) => v as String),
        outcome: $checkedConvert('outcome', (v) => v as String),
        redacted: $checkedConvert('redacted', (v) => v as bool),
        unredactedOptIn: $checkedConvert('unredactedOptIn', (v) => v as bool),
        error: $checkedConvert('error', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AgentAuditRecordToJson(AgentAuditRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'at': instance.at.toIso8601String(),
      'phase': instance.phase,
      'outcome': instance.outcome,
      'redacted': instance.redacted,
      'unredactedOptIn': instance.unredactedOptIn,
      'error': ?instance.error,
    };
