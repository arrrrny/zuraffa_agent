// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thinking_level_change_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThinkingLevelChangeEntry _$ThinkingLevelChangeEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ThinkingLevelChangeEntry', json, ($checkedConvert) {
  final val = ThinkingLevelChangeEntry(
    id: $checkedConvert('id', (v) => v as String),
    parentId: $checkedConvert('parentId', (v) => v as String?),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    thinkingLevel: $checkedConvert('thinkingLevel', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ThinkingLevelChangeEntryToJson(
  ThinkingLevelChangeEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'parentId': ?instance.parentId,
  'timestamp': instance.timestamp.toIso8601String(),
  'thinkingLevel': instance.thinkingLevel,
};
