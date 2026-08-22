// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Enums _$EnumsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Enums', json, ($checkedConvert) {
      final val = Enums(
        id: $checkedConvert('id', (v) => v as String),
        values: $checkedConvert(
          'values',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        description: $checkedConvert('description', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$EnumsToJson(Enums instance) => <String, dynamic>{
  'id': instance.id,
  'values': instance.values,
  'description': ?instance.description,
};
