// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageLedgerEntry _$UsageLedgerEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UsageLedgerEntry', json, ($checkedConvert) {
  final val = UsageLedgerEntry(
    id: $checkedConvert('id', (v) => v as String),
    parentId: $checkedConvert('parentId', (v) => v as String?),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    callId: $checkedConvert('callId', (v) => v as String),
    turnNumber: $checkedConvert('turnNumber', (v) => (v as num).toInt()),
    inputTokens: $checkedConvert('inputTokens', (v) => (v as num).toInt()),
    outputTokens: $checkedConvert('outputTokens', (v) => (v as num).toInt()),
    cacheReadTokens: $checkedConvert(
      'cacheReadTokens',
      (v) => (v as num).toInt(),
    ),
    cacheWriteTokens: $checkedConvert(
      'cacheWriteTokens',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$UsageLedgerEntryToJson(UsageLedgerEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'callId': instance.callId,
      'turnNumber': instance.turnNumber,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
      'cacheReadTokens': instance.cacheReadTokens,
      'cacheWriteTokens': instance.cacheWriteTokens,
    };
