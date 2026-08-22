// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_call_signature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCallSignature _$ToolCallSignatureFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolCallSignature', json, ($checkedConvert) {
      final val = ToolCallSignature(
        id: $checkedConvert('id', (v) => v as String?),
        toolName: $checkedConvert('toolName', (v) => v as String),
        normalizedArgs: $checkedConvert('normalizedArgs', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ToolCallSignatureToJson(ToolCallSignature instance) =>
    <String, dynamic>{
      'id': instance.id,
      'toolName': instance.toolName,
      'normalizedArgs': instance.normalizedArgs,
    };
