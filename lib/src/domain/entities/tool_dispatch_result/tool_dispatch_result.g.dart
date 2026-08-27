// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_dispatch_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolDispatchResult _$ToolDispatchResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolDispatchResult', json, ($checkedConvert) {
      final val = ToolDispatchResult(
        success: $checkedConvert('success', (v) => v as bool),
        result: $checkedConvert('result', (v) => v as String),
        error: $checkedConvert('error', (v) => v as String),
        artifactRefs: $checkedConvert(
          'artifactRefs',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ToolDispatchResultToJson(ToolDispatchResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'result': instance.result,
      'error': instance.error,
      'artifactRefs': instance.artifactRefs,
    };
