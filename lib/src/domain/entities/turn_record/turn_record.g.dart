// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turn_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurnRecord _$TurnRecordFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TurnRecord', json, ($checkedConvert) {
  final val = TurnRecord(
    id: $checkedConvert('id', (v) => v as String),
    parentId: $checkedConvert('parentId', (v) => v as String?),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    turnNumber: $checkedConvert('turnNumber', (v) => (v as num).toInt()),
    messageEntryIds: $checkedConvert(
      'messageEntryIds',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    toolInvocationEntryIds: $checkedConvert(
      'toolInvocationEntryIds',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    stopReason: $checkedConvert('stopReason', (v) => v as String),
    startedAt: $checkedConvert('startedAt', (v) => DateTime.parse(v as String)),
    endedAt: $checkedConvert('endedAt', (v) => DateTime.parse(v as String)),
    durationMs: $checkedConvert('durationMs', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$TurnRecordToJson(TurnRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'turnNumber': instance.turnNumber,
      'messageEntryIds': instance.messageEntryIds,
      'toolInvocationEntryIds': instance.toolInvocationEntryIds,
      'stopReason': instance.stopReason,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt.toIso8601String(),
      'durationMs': instance.durationMs,
    };
