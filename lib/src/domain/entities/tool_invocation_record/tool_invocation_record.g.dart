// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_invocation_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolInvocationRecord _$ToolInvocationRecordFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ToolInvocationRecord', json, ($checkedConvert) {
  final val = ToolInvocationRecord(
    id: $checkedConvert('id', (v) => v as String),
    parentId: $checkedConvert('parentId', (v) => v as String?),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    toolCallId: $checkedConvert('toolCallId', (v) => v as String),
    toolName: $checkedConvert('toolName', (v) => v as String),
    resultEntryId: $checkedConvert('resultEntryId', (v) => v as String?),
    isError: $checkedConvert('isError', (v) => v as bool),
    durationMs: $checkedConvert('durationMs', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ToolInvocationRecordToJson(
  ToolInvocationRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'parentId': ?instance.parentId,
  'timestamp': instance.timestamp.toIso8601String(),
  'toolCallId': instance.toolCallId,
  'toolName': instance.toolName,
  'resultEntryId': ?instance.resultEntryId,
  'isError': instance.isError,
  'durationMs': instance.durationMs,
};
