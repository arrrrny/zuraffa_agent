// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabelEntry _$LabelEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LabelEntry', json, ($checkedConvert) {
      final val = LabelEntry(
        id: $checkedConvert('id', (v) => v as String),
        parentId: $checkedConvert('parentId', (v) => v as String?),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LabelEntryToJson(LabelEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': instance.label,
    };
