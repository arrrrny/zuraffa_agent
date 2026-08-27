// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suite _$SuiteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Suite', json, ($checkedConvert) {
      final val = Suite(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        tasks: $checkedConvert(
          'tasks',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        k: $checkedConvert('k', (v) => (v as num).toInt()),
        gateThreshold: $checkedConvert(
          'gateThreshold',
          (v) => (v as num).toDouble(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SuiteToJson(Suite instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'tasks': instance.tasks,
  'k': instance.k,
  'gateThreshold': instance.gateThreshold,
};
