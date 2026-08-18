// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomEntry _$CustomEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CustomEntry', json, ($checkedConvert) {
      final val = CustomEntry(
        id: $checkedConvert('id', (v) => v as String),
        parentId: $checkedConvert('parentId', (v) => v as String?),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        customType: $checkedConvert('customType', (v) => v as String),
        payload: $checkedConvert('payload', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CustomEntryToJson(CustomEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'customType': instance.customType,
      'payload': instance.payload,
    };
