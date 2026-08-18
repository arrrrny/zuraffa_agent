// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_change_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelChangeEntry _$ModelChangeEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModelChangeEntry', json, ($checkedConvert) {
      final val = ModelChangeEntry(
        id: $checkedConvert('id', (v) => v as String),
        parentId: $checkedConvert('parentId', (v) => v as String?),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        modelId: $checkedConvert('modelId', (v) => v as String),
        provider: $checkedConvert('provider', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ModelChangeEntryToJson(ModelChangeEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': ?instance.parentId,
      'timestamp': instance.timestamp.toIso8601String(),
      'modelId': instance.modelId,
      'provider': instance.provider,
    };
