// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissionStarted _$MissionStartedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissionStarted', json, ($checkedConvert) {
      final val = MissionStarted(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        config: $checkedConvert('config', (v) => v as Map<String, dynamic>),
      );
      return val;
    });

Map<String, dynamic> _$MissionStartedToJson(MissionStarted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'config': instance.config,
    };

MissionCompleted _$MissionCompletedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MissionCompleted', json, ($checkedConvert) {
      final val = MissionCompleted(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        outcome: $checkedConvert('outcome', (v) => v as String),
        errorMessage: $checkedConvert('errorMessage', (v) => v as String?),
        totalTurns: $checkedConvert('totalTurns', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$MissionCompletedToJson(MissionCompleted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'outcome': instance.outcome,
      'errorMessage': ?instance.errorMessage,
      'totalTurns': instance.totalTurns,
    };

TurnStarted _$TurnStartedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TurnStarted', json, ($checkedConvert) {
      final val = TurnStarted(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        turnNumber: $checkedConvert('turnNumber', (v) => (v as num).toInt()),
        messageIds: $checkedConvert(
          'messageIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TurnStartedToJson(TurnStarted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'turnNumber': instance.turnNumber,
      'messageIds': instance.messageIds,
    };

TurnCompleted _$TurnCompletedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TurnCompleted', json, ($checkedConvert) {
  final val = TurnCompleted(
    eventId: $checkedConvert('eventId', (v) => v as String),
    sequenceNumber: $checkedConvert(
      'sequenceNumber',
      (v) => (v as num).toInt(),
    ),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    missionId: $checkedConvert('missionId', (v) => v as String),
    turnNumber: $checkedConvert('turnNumber', (v) => (v as num).toInt()),
    finishReason: $checkedConvert('finishReason', (v) => v as String),
    toolCallCount: $checkedConvert('toolCallCount', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$TurnCompletedToJson(TurnCompleted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'turnNumber': instance.turnNumber,
      'finishReason': instance.finishReason,
      'toolCallCount': instance.toolCallCount,
    };

ThinkingDelta _$ThinkingDeltaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ThinkingDelta', json, ($checkedConvert) {
      final val = ThinkingDelta(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        content: $checkedConvert('content', (v) => v as String),
        deltaIndex: $checkedConvert('deltaIndex', (v) => (v as num).toInt()),
        isComplete: $checkedConvert('isComplete', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ThinkingDeltaToJson(ThinkingDelta instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'content': instance.content,
      'deltaIndex': instance.deltaIndex,
      'isComplete': instance.isComplete,
    };

TextDelta _$TextDeltaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TextDelta', json, ($checkedConvert) {
      final val = TextDelta(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        content: $checkedConvert('content', (v) => v as String),
        deltaIndex: $checkedConvert('deltaIndex', (v) => (v as num).toInt()),
        isComplete: $checkedConvert('isComplete', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$TextDeltaToJson(TextDelta instance) => <String, dynamic>{
  'eventId': instance.eventId,
  'sequenceNumber': instance.sequenceNumber,
  'timestamp': instance.timestamp.toIso8601String(),
  'missionId': instance.missionId,
  'content': instance.content,
  'deltaIndex': instance.deltaIndex,
  'isComplete': instance.isComplete,
};

ToolCallStarted _$ToolCallStartedFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ToolCallStarted', json, ($checkedConvert) {
  final val = ToolCallStarted(
    eventId: $checkedConvert('eventId', (v) => v as String),
    sequenceNumber: $checkedConvert(
      'sequenceNumber',
      (v) => (v as num).toInt(),
    ),
    timestamp: $checkedConvert('timestamp', (v) => DateTime.parse(v as String)),
    missionId: $checkedConvert('missionId', (v) => v as String),
    toolCallId: $checkedConvert('toolCallId', (v) => v as String),
    toolName: $checkedConvert('toolName', (v) => v as String),
    arguments: $checkedConvert('arguments', (v) => v as Map<String, dynamic>),
    callIndex: $checkedConvert('callIndex', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ToolCallStartedToJson(ToolCallStarted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'toolCallId': instance.toolCallId,
      'toolName': instance.toolName,
      'arguments': instance.arguments,
      'callIndex': instance.callIndex,
    };

ToolCallCompleted _$ToolCallCompletedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolCallCompleted', json, ($checkedConvert) {
      final val = ToolCallCompleted(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        toolCallId: $checkedConvert('toolCallId', (v) => v as String),
        result: $checkedConvert('result', (v) => v as String),
        errorMessage: $checkedConvert('errorMessage', (v) => v as String?),
        durationMs: $checkedConvert('durationMs', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ToolCallCompletedToJson(ToolCallCompleted instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'toolCallId': instance.toolCallId,
      'result': instance.result,
      'errorMessage': ?instance.errorMessage,
      'durationMs': instance.durationMs,
    };

ProviderError _$ProviderErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderError', json, ($checkedConvert) {
      final val = ProviderError(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        errorType: $checkedConvert('errorType', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
        isRecoverable: $checkedConvert('isRecoverable', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ProviderErrorToJson(ProviderError instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'errorType': instance.errorType,
      'message': instance.message,
      'isRecoverable': instance.isRecoverable,
    };

SteeringInjected _$SteeringInjectedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SteeringInjected', json, ($checkedConvert) {
      final val = SteeringInjected(
        eventId: $checkedConvert('eventId', (v) => v as String),
        sequenceNumber: $checkedConvert(
          'sequenceNumber',
          (v) => (v as num).toInt(),
        ),
        timestamp: $checkedConvert(
          'timestamp',
          (v) => DateTime.parse(v as String),
        ),
        missionId: $checkedConvert('missionId', (v) => v as String),
        messageId: $checkedConvert('messageId', (v) => v as String),
        content: $checkedConvert('content', (v) => v as String),
        injectionPoint: $checkedConvert(
          'injectionPoint',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SteeringInjectedToJson(SteeringInjected instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'sequenceNumber': instance.sequenceNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'missionId': instance.missionId,
      'messageId': instance.messageId,
      'content': instance.content,
      'injectionPoint': instance.injectionPoint,
    };
