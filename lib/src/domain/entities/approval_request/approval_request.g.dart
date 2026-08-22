// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalRequest _$ApprovalRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApprovalRequest', json, ($checkedConvert) {
      final val = ApprovalRequest(
        toolName: $checkedConvert('toolName', (v) => v as String),
        arguments: $checkedConvert(
          'arguments',
          (v) => v as Map<String, dynamic>,
        ),
        requestedAt: $checkedConvert(
          'requestedAt',
          (v) => DateTime.parse(v as String),
        ),
        timeoutMs: $checkedConvert('timeoutMs', (v) => (v as num).toInt()),
        id: $checkedConvert('id', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ApprovalRequestToJson(ApprovalRequest instance) =>
    <String, dynamic>{
      'toolName': instance.toolName,
      'arguments': instance.arguments,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'timeoutMs': instance.timeoutMs,
      'id': instance.id,
    };
