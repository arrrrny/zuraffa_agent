// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_tool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispatchTool _$DispatchToolFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DispatchTool', json, ($checkedConvert) {
      final val = DispatchTool(
        id: $checkedConvert('id', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        task: $checkedConvert('task', (v) => v as String),
        instanceId: $checkedConvert('instanceId', (v) => v as String),
        lifecycle: $checkedConvert('lifecycle', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DispatchToolToJson(DispatchTool instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'task': instance.task,
      'instanceId': instance.instanceId,
      'lifecycle': instance.lifecycle,
    };
