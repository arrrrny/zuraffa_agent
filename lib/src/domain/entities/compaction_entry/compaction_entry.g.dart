// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compaction_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompactionEntry _$CompactionEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CompactionEntry', json, ($checkedConvert) {
  final val = CompactionEntry(
    id: $checkedConvert('id', (v) => v as String),
    parentId: $checkedConvert('parentId', (v) => v as String?),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    firstKeptEntryId: $checkedConvert('firstKeptEntryId', (v) => v as String),
    tokensBefore: $checkedConvert('tokensBefore', (v) => (v as num).toInt()),
    tokensAfter: $checkedConvert('tokensAfter', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$CompactionEntryToJson(CompactionEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'firstKeptEntryId': instance.firstKeptEntryId,
      'tokensBefore': instance.tokensBefore,
      'tokensAfter': instance.tokensAfter,
    };
