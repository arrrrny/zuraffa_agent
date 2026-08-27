// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'golden_mission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoldenMission _$GoldenMissionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GoldenMission', json, ($checkedConvert) {
      final val = GoldenMission(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        cassette: $checkedConvert('cassette', (v) => v as Map<String, dynamic>),
        taskDefinition: $checkedConvert('taskDefinition', (v) => v as String),
        graderBindings: $checkedConvert(
          'graderBindings',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GoldenMissionToJson(GoldenMission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cassette': instance.cassette,
      'taskDefinition': instance.taskDefinition,
      'graderBindings': instance.graderBindings,
    };
