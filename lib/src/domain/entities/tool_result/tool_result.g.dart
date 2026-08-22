// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolResult _$ToolResultFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ToolResult',
  json,
  ($checkedConvert) {
    final val = ToolResult(
      content: $checkedConvert('content', (v) => v as String),
      structuredPayload: $checkedConvert(
        'structuredPayload',
        (v) => v as Map<String, dynamic>?,
      ),
      artifactRef: $checkedConvert(
        'artifactRef',
        (v) =>
            v == null ? null : ArtifactRef.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$ToolResultToJson(ToolResult instance) =>
    <String, dynamic>{
      'content': instance.content,
      'structuredPayload': ?instance.structuredPayload,
      'artifactRef': ?instance.artifactRef?.toJson(),
    };
