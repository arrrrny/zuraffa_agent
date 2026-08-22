// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turn_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurnContext _$TurnContextFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TurnContext', json, ($checkedConvert) {
      final val = TurnContext(
        id: $checkedConvert('id', (v) => v as String?),
        turnNumber: $checkedConvert('turnNumber', (v) => (v as num).toInt()),
        messageIds: $checkedConvert(
          'messageIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        turnStartTime: $checkedConvert(
          'turnStartTime',
          (v) => DateTime.parse(v as String),
        ),
        toolCallIds: $checkedConvert(
          'toolCallIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TurnContextToJson(TurnContext instance) =>
    <String, dynamic>{
      'id': instance.id,
      'turnNumber': instance.turnNumber,
      'messageIds': instance.messageIds,
      'turnStartTime': instance.turnStartTime.toIso8601String(),
      'toolCallIds': instance.toolCallIds,
    };
