// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'engine_event.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class EngineEvent {
  factory EngineEvent.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == 'MissionStarted') {
      return MissionStarted.fromJson(json);
    } else if (json['__typename'] == 'MissionCompleted') {
      return MissionCompleted.fromJson(json);
    } else if (json['__typename'] == 'TurnStarted') {
      return TurnStarted.fromJson(json);
    } else if (json['__typename'] == 'TurnCompleted') {
      return TurnCompleted.fromJson(json);
    } else if (json['__typename'] == 'ThinkingDelta') {
      return ThinkingDelta.fromJson(json);
    } else if (json['__typename'] == 'TextDelta') {
      return TextDelta.fromJson(json);
    } else if (json['__typename'] == 'ToolCallStarted') {
      return ToolCallStarted.fromJson(json);
    } else if (json['__typename'] == 'ToolCallCompleted') {
      return ToolCallCompleted.fromJson(json);
    } else if (json['__typename'] == 'ProviderError') {
      return ProviderError.fromJson(json);
    } else if (json['__typename'] == 'SteeringInjected') {
      return SteeringInjected.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the EngineEvent.fromJson constructor.",
    );
  }

  String get eventId;
  int get sequenceNumber;
  DateTime get timestamp;
  String get missionId;
}

extension EngineEventPolymorphicE on EngineEvent {
  bool get isMissionStarted {
    return this is MissionStarted;
  }

  MissionStarted? get asMissionStarted {
    return this is MissionStarted ? this as MissionStarted : null;
  }

  bool get isMissionCompleted {
    return this is MissionCompleted;
  }

  MissionCompleted? get asMissionCompleted {
    return this is MissionCompleted ? this as MissionCompleted : null;
  }

  bool get isTurnStarted {
    return this is TurnStarted;
  }

  TurnStarted? get asTurnStarted {
    return this is TurnStarted ? this as TurnStarted : null;
  }

  bool get isTurnCompleted {
    return this is TurnCompleted;
  }

  TurnCompleted? get asTurnCompleted {
    return this is TurnCompleted ? this as TurnCompleted : null;
  }

  bool get isThinkingDelta {
    return this is ThinkingDelta;
  }

  ThinkingDelta? get asThinkingDelta {
    return this is ThinkingDelta ? this as ThinkingDelta : null;
  }

  bool get isTextDelta {
    return this is TextDelta;
  }

  TextDelta? get asTextDelta {
    return this is TextDelta ? this as TextDelta : null;
  }

  bool get isToolCallStarted {
    return this is ToolCallStarted;
  }

  ToolCallStarted? get asToolCallStarted {
    return this is ToolCallStarted ? this as ToolCallStarted : null;
  }

  bool get isToolCallCompleted {
    return this is ToolCallCompleted;
  }

  ToolCallCompleted? get asToolCallCompleted {
    return this is ToolCallCompleted ? this as ToolCallCompleted : null;
  }

  bool get isProviderError {
    return this is ProviderError;
  }

  ProviderError? get asProviderError {
    return this is ProviderError ? this as ProviderError : null;
  }

  bool get isSteeringInjected {
    return this is SteeringInjected;
  }

  SteeringInjected? get asSteeringInjected {
    return this is SteeringInjected ? this as SteeringInjected : null;
  }
}

extension EngineEventPropertyHelpers on EngineEvent {
  bool get hasEventId {
    return this.eventId.isNotEmpty;
  }

  bool get noEventId {
    return this.eventId.isEmpty;
  }

  bool get hasMissionId {
    return this.missionId.isNotEmpty;
  }

  bool get noMissionId {
    return this.missionId.isEmpty;
  }
}

/// Field descriptors for [EngineEvent] query construction
abstract final class EngineEventFields {
  static const eventId = Field<EngineEvent, String>('eventId', _$eventId);

  static const sequenceNumber = Field<EngineEvent, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<EngineEvent, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<EngineEvent, String>('missionId', _$missionId);

  static String _$eventId(EngineEvent e) {
    return e.eventId;
  }

  static int _$sequenceNumber(EngineEvent e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(EngineEvent e) {
    return e.timestamp;
  }

  static String _$missionId(EngineEvent e) {
    return e.missionId;
  }
}

extension EngineEventCompareE on EngineEvent {
  Map<String, dynamic> compareToEngineEvent(EngineEvent other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }
    return diff;
  }
}

extension EngineEventChangeToE on EngineEvent {
  MissionStarted changeToMissionStarted({
    required Map<String, dynamic> config,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = MissionStartedPatch();
    _patcher.withConfig(config);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return MissionStarted.fromJson(_json);
  }

  MissionCompleted changeToMissionCompleted({
    required String outcome,
    String? errorMessage,
    required int totalTurns,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = MissionCompletedPatch();
    _patcher.withOutcome(outcome);
    if (errorMessage != null) {
      _patcher.withErrorMessage(errorMessage);
    }
    _patcher.withTotalTurns(totalTurns);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return MissionCompleted.fromJson(_json);
  }

  TurnStarted changeToTurnStarted({
    required int turnNumber,
    required List<String> messageIds,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = TurnStartedPatch();
    _patcher.withTurnNumber(turnNumber);
    _patcher.withMessageIds(messageIds);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return TurnStarted.fromJson(_json);
  }

  TurnCompleted changeToTurnCompleted({
    required int turnNumber,
    required String finishReason,
    required int toolCallCount,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = TurnCompletedPatch();
    _patcher.withTurnNumber(turnNumber);
    _patcher.withFinishReason(finishReason);
    _patcher.withToolCallCount(toolCallCount);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return TurnCompleted.fromJson(_json);
  }

  ThinkingDelta changeToThinkingDelta({
    required String content,
    required int deltaIndex,
    required bool isComplete,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = ThinkingDeltaPatch();
    _patcher.withContent(content);
    _patcher.withDeltaIndex(deltaIndex);
    _patcher.withIsComplete(isComplete);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return ThinkingDelta.fromJson(_json);
  }

  TextDelta changeToTextDelta({
    required String content,
    required int deltaIndex,
    required bool isComplete,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = TextDeltaPatch();
    _patcher.withContent(content);
    _patcher.withDeltaIndex(deltaIndex);
    _patcher.withIsComplete(isComplete);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return TextDelta.fromJson(_json);
  }

  ToolCallStarted changeToToolCallStarted({
    required String toolCallId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required int callIndex,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = ToolCallStartedPatch();
    _patcher.withToolCallId(toolCallId);
    _patcher.withToolName(toolName);
    _patcher.withArguments(arguments);
    _patcher.withCallIndex(callIndex);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return ToolCallStarted.fromJson(_json);
  }

  ToolCallCompleted changeToToolCallCompleted({
    required String toolCallId,
    required String result,
    String? errorMessage,
    required int durationMs,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = ToolCallCompletedPatch();
    _patcher.withToolCallId(toolCallId);
    _patcher.withResult(result);
    if (errorMessage != null) {
      _patcher.withErrorMessage(errorMessage);
    }
    _patcher.withDurationMs(durationMs);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return ToolCallCompleted.fromJson(_json);
  }

  ProviderError changeToProviderError({
    required String errorType,
    required String message,
    required bool isRecoverable,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = ProviderErrorPatch();
    _patcher.withErrorType(errorType);
    _patcher.withMessage(message);
    _patcher.withIsRecoverable(isRecoverable);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return ProviderError.fromJson(_json);
  }

  SteeringInjected changeToSteeringInjected({
    required String messageId,
    required String content,
    required int injectionPoint,
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
  }) {
    final _patcher = SteeringInjectedPatch();
    _patcher.withMessageId(messageId);
    _patcher.withContent(content);
    _patcher.withInjectionPoint(injectionPoint);
    if (eventId != null) {
      _patcher.withEventId(eventId);
    }
    if (sequenceNumber != null) {
      _patcher.withSequenceNumber(sequenceNumber);
    }
    if (timestamp != null) {
      _patcher.withTimestamp(timestamp);
    }
    if (missionId != null) {
      _patcher.withMissionId(missionId);
    }
    final _json = Map<String, dynamic>.from(switch (this) {
      MissionStarted missionStarted => missionStarted.toJson(),
      MissionCompleted missionCompleted => missionCompleted.toJson(),
      TurnStarted turnStarted => turnStarted.toJson(),
      TurnCompleted turnCompleted => turnCompleted.toJson(),
      ThinkingDelta thinkingDelta => thinkingDelta.toJson(),
      TextDelta textDelta => textDelta.toJson(),
      ToolCallStarted toolCallStarted => toolCallStarted.toJson(),
      ToolCallCompleted toolCallCompleted => toolCallCompleted.toJson(),
      ProviderError providerError => providerError.toJson(),
      SteeringInjected steeringInjected => steeringInjected.toJson(),
    });
    _json.addAll(_patcher.toJson());
    return SteeringInjected.fromJson(_json);
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class MissionStarted implements EngineEvent {
  MissionStarted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required Map<String, dynamic> this.config,
  });

  factory MissionStarted.fromJson(Map<String, dynamic> json) =>
      _$MissionStartedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final Map<String, dynamic> config;

  MissionStarted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    Map<String, dynamic>? config,
  }) {
    return MissionStarted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      config: config ?? this.config,
    );
  }

  MissionStarted copyWithMissionStarted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    Map<String, dynamic>? config,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      config: config,
    );
  }

  MissionStarted patchWithMissionStarted([MissionStartedPatch? patchInput]) {
    final _patcher = patchInput ?? MissionStartedPatch();
    final _patchMap = _patcher.patchMap;
    return MissionStarted(
      eventId: _patchMap.containsKey(MissionStarted$.eventId)
          ? ((_patchMap[MissionStarted$.eventId] is Function)
                    ? _patchMap[MissionStarted$.eventId](this.eventId)
                    : (_patchMap[MissionStarted$.eventId] is Patch)
                    ? _patchMap[MissionStarted$.eventId].applyTo(this.eventId)
                    : _patchMap[MissionStarted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(MissionStarted$.sequenceNumber)
          ? ((_patchMap[MissionStarted$.sequenceNumber] is Function)
                    ? _patchMap[MissionStarted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[MissionStarted$.sequenceNumber] is Patch)
                    ? _patchMap[MissionStarted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[MissionStarted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(MissionStarted$.timestamp)
          ? ((_patchMap[MissionStarted$.timestamp] is Function)
                    ? _patchMap[MissionStarted$.timestamp](this.timestamp)
                    : (_patchMap[MissionStarted$.timestamp] is Patch)
                    ? _patchMap[MissionStarted$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[MissionStarted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(MissionStarted$.missionId)
          ? ((_patchMap[MissionStarted$.missionId] is Function)
                    ? _patchMap[MissionStarted$.missionId](this.missionId)
                    : (_patchMap[MissionStarted$.missionId] is Patch)
                    ? _patchMap[MissionStarted$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[MissionStarted$.missionId])
                as String
          : this.missionId,
      config: _patchMap.containsKey(MissionStarted$.config)
          ? ((_patchMap[MissionStarted$.config] is Function)
                    ? _patchMap[MissionStarted$.config](this.config)
                    : (_patchMap[MissionStarted$.config] is Patch)
                    ? _patchMap[MissionStarted$.config].applyTo(this.config)
                    : _patchMap[MissionStarted$.config])
                as Map<String, dynamic>
          : this.config,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionStarted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        config == other.config;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.config,
    );
  }

  @override
  String toString() {
    return 'MissionStarted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'config: ${config})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$MissionStartedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$MissionStartedToJson(this);
    json['__typename'] = 'MissionStarted';
    return json;
  }
}

extension MissionStartedPropertyHelpers on MissionStarted {
  bool get hasConfig {
    return this.config.isNotEmpty;
  }

  bool get noConfig {
    return this.config.isEmpty;
  }
}

extension MissionStartedSerialization on MissionStarted {
  Map<String, dynamic> toJson() {
    return _$MissionStartedToJson(this);
  }
}

enum MissionStarted$ { eventId, sequenceNumber, timestamp, missionId, config }

class MissionStartedPatch extends PatchBase<MissionStarted, MissionStarted$> {
  MissionStarted applyTo(MissionStarted entity) {
    return entity.patchWithMissionStarted(this);
  }

  MissionStartedPatch withEventId(String? value) {
    patchMap[MissionStarted$.eventId] = value;
    return this;
  }

  MissionStartedPatch withSequenceNumber(int? value) {
    patchMap[MissionStarted$.sequenceNumber] = value;
    return this;
  }

  MissionStartedPatch withTimestamp(DateTime? value) {
    patchMap[MissionStarted$.timestamp] = value;
    return this;
  }

  MissionStartedPatch withMissionId(String? value) {
    patchMap[MissionStarted$.missionId] = value;
    return this;
  }

  MissionStartedPatch withConfig(Map<String, dynamic>? value) {
    patchMap[MissionStarted$.config] = value;
    return this;
  }
}

/// Field descriptors for [MissionStarted] query construction
abstract final class MissionStartedFields {
  static const eventId = Field<MissionStarted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<MissionStarted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<MissionStarted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<MissionStarted, String>(
    'missionId',
    _$missionId,
  );

  static const config = Field<MissionStarted, Map<String, dynamic>>(
    'config',
    _$config,
  );

  static String _$eventId(MissionStarted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(MissionStarted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(MissionStarted e) {
    return e.timestamp;
  }

  static String _$missionId(MissionStarted e) {
    return e.missionId;
  }

  static Map<String, dynamic> _$config(MissionStarted e) {
    return e.config;
  }
}

extension MissionStartedCompareE on MissionStarted {
  Map<String, dynamic> compareToMissionStarted(MissionStarted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (config != other.config) {
      diff['config'] = () => other.config;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class MissionCompleted implements EngineEvent {
  MissionCompleted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.outcome,
    String? this.errorMessage,
    required int this.totalTurns,
  });

  factory MissionCompleted.fromJson(Map<String, dynamic> json) =>
      _$MissionCompletedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String outcome;

  final String? errorMessage;

  final int totalTurns;

  MissionCompleted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? outcome,
    String? errorMessage,
    int? totalTurns,
  }) {
    return MissionCompleted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      outcome: outcome ?? this.outcome,
      errorMessage: errorMessage ?? this.errorMessage,
      totalTurns: totalTurns ?? this.totalTurns,
    );
  }

  MissionCompleted copyWithMissionCompleted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? outcome,
    String? errorMessage,
    int? totalTurns,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      outcome: outcome,
      errorMessage: errorMessage,
      totalTurns: totalTurns,
    );
  }

  MissionCompleted patchWithMissionCompleted([
    MissionCompletedPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? MissionCompletedPatch();
    final _patchMap = _patcher.patchMap;
    return MissionCompleted(
      eventId: _patchMap.containsKey(MissionCompleted$.eventId)
          ? ((_patchMap[MissionCompleted$.eventId] is Function)
                    ? _patchMap[MissionCompleted$.eventId](this.eventId)
                    : (_patchMap[MissionCompleted$.eventId] is Patch)
                    ? _patchMap[MissionCompleted$.eventId].applyTo(this.eventId)
                    : _patchMap[MissionCompleted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(MissionCompleted$.sequenceNumber)
          ? ((_patchMap[MissionCompleted$.sequenceNumber] is Function)
                    ? _patchMap[MissionCompleted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[MissionCompleted$.sequenceNumber] is Patch)
                    ? _patchMap[MissionCompleted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[MissionCompleted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(MissionCompleted$.timestamp)
          ? ((_patchMap[MissionCompleted$.timestamp] is Function)
                    ? _patchMap[MissionCompleted$.timestamp](this.timestamp)
                    : (_patchMap[MissionCompleted$.timestamp] is Patch)
                    ? _patchMap[MissionCompleted$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[MissionCompleted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(MissionCompleted$.missionId)
          ? ((_patchMap[MissionCompleted$.missionId] is Function)
                    ? _patchMap[MissionCompleted$.missionId](this.missionId)
                    : (_patchMap[MissionCompleted$.missionId] is Patch)
                    ? _patchMap[MissionCompleted$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[MissionCompleted$.missionId])
                as String
          : this.missionId,
      outcome: _patchMap.containsKey(MissionCompleted$.outcome)
          ? ((_patchMap[MissionCompleted$.outcome] is Function)
                    ? _patchMap[MissionCompleted$.outcome](this.outcome)
                    : (_patchMap[MissionCompleted$.outcome] is Patch)
                    ? _patchMap[MissionCompleted$.outcome].applyTo(this.outcome)
                    : _patchMap[MissionCompleted$.outcome])
                as String
          : this.outcome,
      errorMessage: _patchMap.containsKey(MissionCompleted$.errorMessage)
          ? ((_patchMap[MissionCompleted$.errorMessage] is Function)
                    ? _patchMap[MissionCompleted$.errorMessage](
                        this.errorMessage,
                      )
                    : (_patchMap[MissionCompleted$.errorMessage] is Patch)
                    ? _patchMap[MissionCompleted$.errorMessage].applyTo(
                        this.errorMessage,
                      )
                    : _patchMap[MissionCompleted$.errorMessage])
                as String?
          : this.errorMessage,
      totalTurns: _patchMap.containsKey(MissionCompleted$.totalTurns)
          ? ((_patchMap[MissionCompleted$.totalTurns] is Function)
                    ? _patchMap[MissionCompleted$.totalTurns](this.totalTurns)
                    : (_patchMap[MissionCompleted$.totalTurns] is Patch)
                    ? _patchMap[MissionCompleted$.totalTurns].applyTo(
                        this.totalTurns,
                      )
                    : _patchMap[MissionCompleted$.totalTurns])
                as int
          : this.totalTurns,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionCompleted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        outcome == other.outcome &&
        errorMessage == other.errorMessage &&
        totalTurns == other.totalTurns;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.outcome,
      this.errorMessage,
      this.totalTurns,
    );
  }

  @override
  String toString() {
    return 'MissionCompleted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'outcome: ${outcome}' +
        ', ' +
        'errorMessage: ${errorMessage}' +
        ', ' +
        'totalTurns: ${totalTurns})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$MissionCompletedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$MissionCompletedToJson(this);
    json['__typename'] = 'MissionCompleted';
    return json;
  }
}

extension MissionCompletedPropertyHelpers on MissionCompleted {
  bool get hasOutcome {
    return this.outcome.isNotEmpty;
  }

  bool get noOutcome {
    return this.outcome.isEmpty;
  }

  bool get hasErrorMessage {
    return this.errorMessage?.isNotEmpty == true;
  }

  bool get noErrorMessage {
    return this.errorMessage?.isEmpty ?? true;
  }

  String get errorMessageRequired {
    return this.errorMessage ??
        (throw StateError('errorMessage is required but was null'));
  }
}

extension MissionCompletedSerialization on MissionCompleted {
  Map<String, dynamic> toJson() {
    return _$MissionCompletedToJson(this);
  }
}

enum MissionCompleted$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  outcome,
  errorMessage,
  totalTurns,
}

class MissionCompletedPatch
    extends PatchBase<MissionCompleted, MissionCompleted$> {
  MissionCompleted applyTo(MissionCompleted entity) {
    return entity.patchWithMissionCompleted(this);
  }

  MissionCompletedPatch withEventId(String? value) {
    patchMap[MissionCompleted$.eventId] = value;
    return this;
  }

  MissionCompletedPatch withSequenceNumber(int? value) {
    patchMap[MissionCompleted$.sequenceNumber] = value;
    return this;
  }

  MissionCompletedPatch withTimestamp(DateTime? value) {
    patchMap[MissionCompleted$.timestamp] = value;
    return this;
  }

  MissionCompletedPatch withMissionId(String? value) {
    patchMap[MissionCompleted$.missionId] = value;
    return this;
  }

  MissionCompletedPatch withOutcome(String? value) {
    patchMap[MissionCompleted$.outcome] = value;
    return this;
  }

  MissionCompletedPatch withErrorMessage(String? value) {
    patchMap[MissionCompleted$.errorMessage] = value;
    return this;
  }

  MissionCompletedPatch withTotalTurns(int? value) {
    patchMap[MissionCompleted$.totalTurns] = value;
    return this;
  }
}

/// Field descriptors for [MissionCompleted] query construction
abstract final class MissionCompletedFields {
  static const eventId = Field<MissionCompleted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<MissionCompleted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<MissionCompleted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<MissionCompleted, String>(
    'missionId',
    _$missionId,
  );

  static const outcome = Field<MissionCompleted, String>('outcome', _$outcome);

  static const errorMessage = Field<MissionCompleted, String?>(
    'errorMessage',
    _$errorMessage,
  );

  static const totalTurns = Field<MissionCompleted, int>(
    'totalTurns',
    _$totalTurns,
  );

  static String _$eventId(MissionCompleted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(MissionCompleted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(MissionCompleted e) {
    return e.timestamp;
  }

  static String _$missionId(MissionCompleted e) {
    return e.missionId;
  }

  static String _$outcome(MissionCompleted e) {
    return e.outcome;
  }

  static String? _$errorMessage(MissionCompleted e) {
    return e.errorMessage;
  }

  static int _$totalTurns(MissionCompleted e) {
    return e.totalTurns;
  }
}

extension MissionCompletedCompareE on MissionCompleted {
  Map<String, dynamic> compareToMissionCompleted(MissionCompleted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (outcome != other.outcome) {
      diff['outcome'] = () => other.outcome;
    }

    if (errorMessage != other.errorMessage) {
      diff['errorMessage'] = () => other.errorMessage;
    }

    if (totalTurns != other.totalTurns) {
      diff['totalTurns'] = () => other.totalTurns;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class TurnStarted implements EngineEvent {
  TurnStarted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required int this.turnNumber,
    required List<String> this.messageIds,
  });

  factory TurnStarted.fromJson(Map<String, dynamic> json) =>
      _$TurnStartedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final int turnNumber;

  final List<String> messageIds;

  TurnStarted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    int? turnNumber,
    List<String>? messageIds,
  }) {
    return TurnStarted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      turnNumber: turnNumber ?? this.turnNumber,
      messageIds: messageIds ?? this.messageIds,
    );
  }

  TurnStarted copyWithTurnStarted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    int? turnNumber,
    List<String>? messageIds,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      turnNumber: turnNumber,
      messageIds: messageIds,
    );
  }

  TurnStarted patchWithTurnStarted([TurnStartedPatch? patchInput]) {
    final _patcher = patchInput ?? TurnStartedPatch();
    final _patchMap = _patcher.patchMap;
    return TurnStarted(
      eventId: _patchMap.containsKey(TurnStarted$.eventId)
          ? ((_patchMap[TurnStarted$.eventId] is Function)
                    ? _patchMap[TurnStarted$.eventId](this.eventId)
                    : (_patchMap[TurnStarted$.eventId] is Patch)
                    ? _patchMap[TurnStarted$.eventId].applyTo(this.eventId)
                    : _patchMap[TurnStarted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(TurnStarted$.sequenceNumber)
          ? ((_patchMap[TurnStarted$.sequenceNumber] is Function)
                    ? _patchMap[TurnStarted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[TurnStarted$.sequenceNumber] is Patch)
                    ? _patchMap[TurnStarted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[TurnStarted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(TurnStarted$.timestamp)
          ? ((_patchMap[TurnStarted$.timestamp] is Function)
                    ? _patchMap[TurnStarted$.timestamp](this.timestamp)
                    : (_patchMap[TurnStarted$.timestamp] is Patch)
                    ? _patchMap[TurnStarted$.timestamp].applyTo(this.timestamp)
                    : _patchMap[TurnStarted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(TurnStarted$.missionId)
          ? ((_patchMap[TurnStarted$.missionId] is Function)
                    ? _patchMap[TurnStarted$.missionId](this.missionId)
                    : (_patchMap[TurnStarted$.missionId] is Patch)
                    ? _patchMap[TurnStarted$.missionId].applyTo(this.missionId)
                    : _patchMap[TurnStarted$.missionId])
                as String
          : this.missionId,
      turnNumber: _patchMap.containsKey(TurnStarted$.turnNumber)
          ? ((_patchMap[TurnStarted$.turnNumber] is Function)
                    ? _patchMap[TurnStarted$.turnNumber](this.turnNumber)
                    : (_patchMap[TurnStarted$.turnNumber] is Patch)
                    ? _patchMap[TurnStarted$.turnNumber].applyTo(
                        this.turnNumber,
                      )
                    : _patchMap[TurnStarted$.turnNumber])
                as int
          : this.turnNumber,
      messageIds: _patchMap.containsKey(TurnStarted$.messageIds)
          ? ((_patchMap[TurnStarted$.messageIds] is Function)
                    ? _patchMap[TurnStarted$.messageIds](this.messageIds)
                    : (_patchMap[TurnStarted$.messageIds] is Patch)
                    ? _patchMap[TurnStarted$.messageIds].applyTo(
                        this.messageIds,
                      )
                    : _patchMap[TurnStarted$.messageIds])
                as List<String>
          : this.messageIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnStarted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        turnNumber == other.turnNumber &&
        messageIds == other.messageIds;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.turnNumber,
      this.messageIds,
    );
  }

  @override
  String toString() {
    return 'TurnStarted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'turnNumber: ${turnNumber}' +
        ', ' +
        'messageIds: ${messageIds})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TurnStartedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$TurnStartedToJson(this);
    json['__typename'] = 'TurnStarted';
    return json;
  }
}

extension TurnStartedPropertyHelpers on TurnStarted {
  bool get hasMessageIds {
    return this.messageIds.isNotEmpty;
  }

  bool get noMessageIds {
    return this.messageIds.isEmpty;
  }
}

extension TurnStartedSerialization on TurnStarted {
  Map<String, dynamic> toJson() {
    return _$TurnStartedToJson(this);
  }
}

enum TurnStarted$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  turnNumber,
  messageIds,
}

class TurnStartedPatch extends PatchBase<TurnStarted, TurnStarted$> {
  TurnStarted applyTo(TurnStarted entity) {
    return entity.patchWithTurnStarted(this);
  }

  TurnStartedPatch withEventId(String? value) {
    patchMap[TurnStarted$.eventId] = value;
    return this;
  }

  TurnStartedPatch withSequenceNumber(int? value) {
    patchMap[TurnStarted$.sequenceNumber] = value;
    return this;
  }

  TurnStartedPatch withTimestamp(DateTime? value) {
    patchMap[TurnStarted$.timestamp] = value;
    return this;
  }

  TurnStartedPatch withMissionId(String? value) {
    patchMap[TurnStarted$.missionId] = value;
    return this;
  }

  TurnStartedPatch withTurnNumber(int? value) {
    patchMap[TurnStarted$.turnNumber] = value;
    return this;
  }

  TurnStartedPatch withMessageIds(List<String>? value) {
    patchMap[TurnStarted$.messageIds] = value;
    return this;
  }
}

/// Field descriptors for [TurnStarted] query construction
abstract final class TurnStartedFields {
  static const eventId = Field<TurnStarted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<TurnStarted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<TurnStarted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<TurnStarted, String>('missionId', _$missionId);

  static const turnNumber = Field<TurnStarted, int>('turnNumber', _$turnNumber);

  static const messageIds = Field<TurnStarted, List<String>>(
    'messageIds',
    _$messageIds,
  );

  static String _$eventId(TurnStarted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(TurnStarted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(TurnStarted e) {
    return e.timestamp;
  }

  static String _$missionId(TurnStarted e) {
    return e.missionId;
  }

  static int _$turnNumber(TurnStarted e) {
    return e.turnNumber;
  }

  static List<String> _$messageIds(TurnStarted e) {
    return e.messageIds;
  }
}

extension TurnStartedCompareE on TurnStarted {
  Map<String, dynamic> compareToTurnStarted(TurnStarted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (turnNumber != other.turnNumber) {
      diff['turnNumber'] = () => other.turnNumber;
    }

    if (messageIds != other.messageIds) {
      diff['messageIds'] = () => other.messageIds;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class TurnCompleted implements EngineEvent {
  TurnCompleted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required int this.turnNumber,
    required String this.finishReason,
    required int this.toolCallCount,
  });

  factory TurnCompleted.fromJson(Map<String, dynamic> json) =>
      _$TurnCompletedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final int turnNumber;

  final String finishReason;

  final int toolCallCount;

  TurnCompleted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    int? turnNumber,
    String? finishReason,
    int? toolCallCount,
  }) {
    return TurnCompleted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      turnNumber: turnNumber ?? this.turnNumber,
      finishReason: finishReason ?? this.finishReason,
      toolCallCount: toolCallCount ?? this.toolCallCount,
    );
  }

  TurnCompleted copyWithTurnCompleted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    int? turnNumber,
    String? finishReason,
    int? toolCallCount,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      turnNumber: turnNumber,
      finishReason: finishReason,
      toolCallCount: toolCallCount,
    );
  }

  TurnCompleted patchWithTurnCompleted([TurnCompletedPatch? patchInput]) {
    final _patcher = patchInput ?? TurnCompletedPatch();
    final _patchMap = _patcher.patchMap;
    return TurnCompleted(
      eventId: _patchMap.containsKey(TurnCompleted$.eventId)
          ? ((_patchMap[TurnCompleted$.eventId] is Function)
                    ? _patchMap[TurnCompleted$.eventId](this.eventId)
                    : (_patchMap[TurnCompleted$.eventId] is Patch)
                    ? _patchMap[TurnCompleted$.eventId].applyTo(this.eventId)
                    : _patchMap[TurnCompleted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(TurnCompleted$.sequenceNumber)
          ? ((_patchMap[TurnCompleted$.sequenceNumber] is Function)
                    ? _patchMap[TurnCompleted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[TurnCompleted$.sequenceNumber] is Patch)
                    ? _patchMap[TurnCompleted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[TurnCompleted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(TurnCompleted$.timestamp)
          ? ((_patchMap[TurnCompleted$.timestamp] is Function)
                    ? _patchMap[TurnCompleted$.timestamp](this.timestamp)
                    : (_patchMap[TurnCompleted$.timestamp] is Patch)
                    ? _patchMap[TurnCompleted$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[TurnCompleted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(TurnCompleted$.missionId)
          ? ((_patchMap[TurnCompleted$.missionId] is Function)
                    ? _patchMap[TurnCompleted$.missionId](this.missionId)
                    : (_patchMap[TurnCompleted$.missionId] is Patch)
                    ? _patchMap[TurnCompleted$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[TurnCompleted$.missionId])
                as String
          : this.missionId,
      turnNumber: _patchMap.containsKey(TurnCompleted$.turnNumber)
          ? ((_patchMap[TurnCompleted$.turnNumber] is Function)
                    ? _patchMap[TurnCompleted$.turnNumber](this.turnNumber)
                    : (_patchMap[TurnCompleted$.turnNumber] is Patch)
                    ? _patchMap[TurnCompleted$.turnNumber].applyTo(
                        this.turnNumber,
                      )
                    : _patchMap[TurnCompleted$.turnNumber])
                as int
          : this.turnNumber,
      finishReason: _patchMap.containsKey(TurnCompleted$.finishReason)
          ? ((_patchMap[TurnCompleted$.finishReason] is Function)
                    ? _patchMap[TurnCompleted$.finishReason](this.finishReason)
                    : (_patchMap[TurnCompleted$.finishReason] is Patch)
                    ? _patchMap[TurnCompleted$.finishReason].applyTo(
                        this.finishReason,
                      )
                    : _patchMap[TurnCompleted$.finishReason])
                as String
          : this.finishReason,
      toolCallCount: _patchMap.containsKey(TurnCompleted$.toolCallCount)
          ? ((_patchMap[TurnCompleted$.toolCallCount] is Function)
                    ? _patchMap[TurnCompleted$.toolCallCount](
                        this.toolCallCount,
                      )
                    : (_patchMap[TurnCompleted$.toolCallCount] is Patch)
                    ? _patchMap[TurnCompleted$.toolCallCount].applyTo(
                        this.toolCallCount,
                      )
                    : _patchMap[TurnCompleted$.toolCallCount])
                as int
          : this.toolCallCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnCompleted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        turnNumber == other.turnNumber &&
        finishReason == other.finishReason &&
        toolCallCount == other.toolCallCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.turnNumber,
      this.finishReason,
      this.toolCallCount,
    );
  }

  @override
  String toString() {
    return 'TurnCompleted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'turnNumber: ${turnNumber}' +
        ', ' +
        'finishReason: ${finishReason}' +
        ', ' +
        'toolCallCount: ${toolCallCount})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TurnCompletedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$TurnCompletedToJson(this);
    json['__typename'] = 'TurnCompleted';
    return json;
  }
}

extension TurnCompletedPropertyHelpers on TurnCompleted {
  bool get hasFinishReason {
    return this.finishReason.isNotEmpty;
  }

  bool get noFinishReason {
    return this.finishReason.isEmpty;
  }
}

extension TurnCompletedSerialization on TurnCompleted {
  Map<String, dynamic> toJson() {
    return _$TurnCompletedToJson(this);
  }
}

enum TurnCompleted$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  turnNumber,
  finishReason,
  toolCallCount,
}

class TurnCompletedPatch extends PatchBase<TurnCompleted, TurnCompleted$> {
  TurnCompleted applyTo(TurnCompleted entity) {
    return entity.patchWithTurnCompleted(this);
  }

  TurnCompletedPatch withEventId(String? value) {
    patchMap[TurnCompleted$.eventId] = value;
    return this;
  }

  TurnCompletedPatch withSequenceNumber(int? value) {
    patchMap[TurnCompleted$.sequenceNumber] = value;
    return this;
  }

  TurnCompletedPatch withTimestamp(DateTime? value) {
    patchMap[TurnCompleted$.timestamp] = value;
    return this;
  }

  TurnCompletedPatch withMissionId(String? value) {
    patchMap[TurnCompleted$.missionId] = value;
    return this;
  }

  TurnCompletedPatch withTurnNumber(int? value) {
    patchMap[TurnCompleted$.turnNumber] = value;
    return this;
  }

  TurnCompletedPatch withFinishReason(String? value) {
    patchMap[TurnCompleted$.finishReason] = value;
    return this;
  }

  TurnCompletedPatch withToolCallCount(int? value) {
    patchMap[TurnCompleted$.toolCallCount] = value;
    return this;
  }
}

/// Field descriptors for [TurnCompleted] query construction
abstract final class TurnCompletedFields {
  static const eventId = Field<TurnCompleted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<TurnCompleted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<TurnCompleted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<TurnCompleted, String>(
    'missionId',
    _$missionId,
  );

  static const turnNumber = Field<TurnCompleted, int>(
    'turnNumber',
    _$turnNumber,
  );

  static const finishReason = Field<TurnCompleted, String>(
    'finishReason',
    _$finishReason,
  );

  static const toolCallCount = Field<TurnCompleted, int>(
    'toolCallCount',
    _$toolCallCount,
  );

  static String _$eventId(TurnCompleted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(TurnCompleted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(TurnCompleted e) {
    return e.timestamp;
  }

  static String _$missionId(TurnCompleted e) {
    return e.missionId;
  }

  static int _$turnNumber(TurnCompleted e) {
    return e.turnNumber;
  }

  static String _$finishReason(TurnCompleted e) {
    return e.finishReason;
  }

  static int _$toolCallCount(TurnCompleted e) {
    return e.toolCallCount;
  }
}

extension TurnCompletedCompareE on TurnCompleted {
  Map<String, dynamic> compareToTurnCompleted(TurnCompleted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (turnNumber != other.turnNumber) {
      diff['turnNumber'] = () => other.turnNumber;
    }

    if (finishReason != other.finishReason) {
      diff['finishReason'] = () => other.finishReason;
    }

    if (toolCallCount != other.toolCallCount) {
      diff['toolCallCount'] = () => other.toolCallCount;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class ThinkingDelta implements EngineEvent {
  ThinkingDelta({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.content,
    required int this.deltaIndex,
    required bool this.isComplete,
  });

  factory ThinkingDelta.fromJson(Map<String, dynamic> json) =>
      _$ThinkingDeltaFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String content;

  final int deltaIndex;

  final bool isComplete;

  ThinkingDelta copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? content,
    int? deltaIndex,
    bool? isComplete,
  }) {
    return ThinkingDelta(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      content: content ?? this.content,
      deltaIndex: deltaIndex ?? this.deltaIndex,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  ThinkingDelta copyWithThinkingDelta({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? content,
    int? deltaIndex,
    bool? isComplete,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      content: content,
      deltaIndex: deltaIndex,
      isComplete: isComplete,
    );
  }

  ThinkingDelta patchWithThinkingDelta([ThinkingDeltaPatch? patchInput]) {
    final _patcher = patchInput ?? ThinkingDeltaPatch();
    final _patchMap = _patcher.patchMap;
    return ThinkingDelta(
      eventId: _patchMap.containsKey(ThinkingDelta$.eventId)
          ? ((_patchMap[ThinkingDelta$.eventId] is Function)
                    ? _patchMap[ThinkingDelta$.eventId](this.eventId)
                    : (_patchMap[ThinkingDelta$.eventId] is Patch)
                    ? _patchMap[ThinkingDelta$.eventId].applyTo(this.eventId)
                    : _patchMap[ThinkingDelta$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(ThinkingDelta$.sequenceNumber)
          ? ((_patchMap[ThinkingDelta$.sequenceNumber] is Function)
                    ? _patchMap[ThinkingDelta$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[ThinkingDelta$.sequenceNumber] is Patch)
                    ? _patchMap[ThinkingDelta$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[ThinkingDelta$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(ThinkingDelta$.timestamp)
          ? ((_patchMap[ThinkingDelta$.timestamp] is Function)
                    ? _patchMap[ThinkingDelta$.timestamp](this.timestamp)
                    : (_patchMap[ThinkingDelta$.timestamp] is Patch)
                    ? _patchMap[ThinkingDelta$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ThinkingDelta$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(ThinkingDelta$.missionId)
          ? ((_patchMap[ThinkingDelta$.missionId] is Function)
                    ? _patchMap[ThinkingDelta$.missionId](this.missionId)
                    : (_patchMap[ThinkingDelta$.missionId] is Patch)
                    ? _patchMap[ThinkingDelta$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[ThinkingDelta$.missionId])
                as String
          : this.missionId,
      content: _patchMap.containsKey(ThinkingDelta$.content)
          ? ((_patchMap[ThinkingDelta$.content] is Function)
                    ? _patchMap[ThinkingDelta$.content](this.content)
                    : (_patchMap[ThinkingDelta$.content] is Patch)
                    ? _patchMap[ThinkingDelta$.content].applyTo(this.content)
                    : _patchMap[ThinkingDelta$.content])
                as String
          : this.content,
      deltaIndex: _patchMap.containsKey(ThinkingDelta$.deltaIndex)
          ? ((_patchMap[ThinkingDelta$.deltaIndex] is Function)
                    ? _patchMap[ThinkingDelta$.deltaIndex](this.deltaIndex)
                    : (_patchMap[ThinkingDelta$.deltaIndex] is Patch)
                    ? _patchMap[ThinkingDelta$.deltaIndex].applyTo(
                        this.deltaIndex,
                      )
                    : _patchMap[ThinkingDelta$.deltaIndex])
                as int
          : this.deltaIndex,
      isComplete: _patchMap.containsKey(ThinkingDelta$.isComplete)
          ? ((_patchMap[ThinkingDelta$.isComplete] is Function)
                    ? _patchMap[ThinkingDelta$.isComplete](this.isComplete)
                    : (_patchMap[ThinkingDelta$.isComplete] is Patch)
                    ? _patchMap[ThinkingDelta$.isComplete].applyTo(
                        this.isComplete,
                      )
                    : _patchMap[ThinkingDelta$.isComplete])
                as bool
          : this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingDelta &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        content == other.content &&
        deltaIndex == other.deltaIndex &&
        isComplete == other.isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.content,
      this.deltaIndex,
      this.isComplete,
    );
  }

  @override
  String toString() {
    return 'ThinkingDelta(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'deltaIndex: ${deltaIndex}' +
        ', ' +
        'isComplete: ${isComplete})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ThinkingDeltaToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$ThinkingDeltaToJson(this);
    json['__typename'] = 'ThinkingDelta';
    return json;
  }
}

extension ThinkingDeltaPropertyHelpers on ThinkingDelta {
  bool get hasContent {
    return this.content.isNotEmpty;
  }

  bool get noContent {
    return this.content.isEmpty;
  }
}

extension ThinkingDeltaSerialization on ThinkingDelta {
  Map<String, dynamic> toJson() {
    return _$ThinkingDeltaToJson(this);
  }
}

enum ThinkingDelta$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  content,
  deltaIndex,
  isComplete,
}

class ThinkingDeltaPatch extends PatchBase<ThinkingDelta, ThinkingDelta$> {
  ThinkingDelta applyTo(ThinkingDelta entity) {
    return entity.patchWithThinkingDelta(this);
  }

  ThinkingDeltaPatch withEventId(String? value) {
    patchMap[ThinkingDelta$.eventId] = value;
    return this;
  }

  ThinkingDeltaPatch withSequenceNumber(int? value) {
    patchMap[ThinkingDelta$.sequenceNumber] = value;
    return this;
  }

  ThinkingDeltaPatch withTimestamp(DateTime? value) {
    patchMap[ThinkingDelta$.timestamp] = value;
    return this;
  }

  ThinkingDeltaPatch withMissionId(String? value) {
    patchMap[ThinkingDelta$.missionId] = value;
    return this;
  }

  ThinkingDeltaPatch withContent(String? value) {
    patchMap[ThinkingDelta$.content] = value;
    return this;
  }

  ThinkingDeltaPatch withDeltaIndex(int? value) {
    patchMap[ThinkingDelta$.deltaIndex] = value;
    return this;
  }

  ThinkingDeltaPatch withIsComplete(bool? value) {
    patchMap[ThinkingDelta$.isComplete] = value;
    return this;
  }
}

/// Field descriptors for [ThinkingDelta] query construction
abstract final class ThinkingDeltaFields {
  static const eventId = Field<ThinkingDelta, String>('eventId', _$eventId);

  static const sequenceNumber = Field<ThinkingDelta, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<ThinkingDelta, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<ThinkingDelta, String>(
    'missionId',
    _$missionId,
  );

  static const content = Field<ThinkingDelta, String>('content', _$content);

  static const deltaIndex = Field<ThinkingDelta, int>(
    'deltaIndex',
    _$deltaIndex,
  );

  static const isComplete = Field<ThinkingDelta, bool>(
    'isComplete',
    _$isComplete,
  );

  static String _$eventId(ThinkingDelta e) {
    return e.eventId;
  }

  static int _$sequenceNumber(ThinkingDelta e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(ThinkingDelta e) {
    return e.timestamp;
  }

  static String _$missionId(ThinkingDelta e) {
    return e.missionId;
  }

  static String _$content(ThinkingDelta e) {
    return e.content;
  }

  static int _$deltaIndex(ThinkingDelta e) {
    return e.deltaIndex;
  }

  static bool _$isComplete(ThinkingDelta e) {
    return e.isComplete;
  }
}

extension ThinkingDeltaCompareE on ThinkingDelta {
  Map<String, dynamic> compareToThinkingDelta(ThinkingDelta other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (content != other.content) {
      diff['content'] = () => other.content;
    }

    if (deltaIndex != other.deltaIndex) {
      diff['deltaIndex'] = () => other.deltaIndex;
    }

    if (isComplete != other.isComplete) {
      diff['isComplete'] = () => other.isComplete;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class TextDelta implements EngineEvent {
  TextDelta({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.content,
    required int this.deltaIndex,
    required bool this.isComplete,
  });

  factory TextDelta.fromJson(Map<String, dynamic> json) =>
      _$TextDeltaFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String content;

  final int deltaIndex;

  final bool isComplete;

  TextDelta copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? content,
    int? deltaIndex,
    bool? isComplete,
  }) {
    return TextDelta(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      content: content ?? this.content,
      deltaIndex: deltaIndex ?? this.deltaIndex,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  TextDelta copyWithTextDelta({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? content,
    int? deltaIndex,
    bool? isComplete,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      content: content,
      deltaIndex: deltaIndex,
      isComplete: isComplete,
    );
  }

  TextDelta patchWithTextDelta([TextDeltaPatch? patchInput]) {
    final _patcher = patchInput ?? TextDeltaPatch();
    final _patchMap = _patcher.patchMap;
    return TextDelta(
      eventId: _patchMap.containsKey(TextDelta$.eventId)
          ? ((_patchMap[TextDelta$.eventId] is Function)
                    ? _patchMap[TextDelta$.eventId](this.eventId)
                    : (_patchMap[TextDelta$.eventId] is Patch)
                    ? _patchMap[TextDelta$.eventId].applyTo(this.eventId)
                    : _patchMap[TextDelta$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(TextDelta$.sequenceNumber)
          ? ((_patchMap[TextDelta$.sequenceNumber] is Function)
                    ? _patchMap[TextDelta$.sequenceNumber](this.sequenceNumber)
                    : (_patchMap[TextDelta$.sequenceNumber] is Patch)
                    ? _patchMap[TextDelta$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[TextDelta$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(TextDelta$.timestamp)
          ? ((_patchMap[TextDelta$.timestamp] is Function)
                    ? _patchMap[TextDelta$.timestamp](this.timestamp)
                    : (_patchMap[TextDelta$.timestamp] is Patch)
                    ? _patchMap[TextDelta$.timestamp].applyTo(this.timestamp)
                    : _patchMap[TextDelta$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(TextDelta$.missionId)
          ? ((_patchMap[TextDelta$.missionId] is Function)
                    ? _patchMap[TextDelta$.missionId](this.missionId)
                    : (_patchMap[TextDelta$.missionId] is Patch)
                    ? _patchMap[TextDelta$.missionId].applyTo(this.missionId)
                    : _patchMap[TextDelta$.missionId])
                as String
          : this.missionId,
      content: _patchMap.containsKey(TextDelta$.content)
          ? ((_patchMap[TextDelta$.content] is Function)
                    ? _patchMap[TextDelta$.content](this.content)
                    : (_patchMap[TextDelta$.content] is Patch)
                    ? _patchMap[TextDelta$.content].applyTo(this.content)
                    : _patchMap[TextDelta$.content])
                as String
          : this.content,
      deltaIndex: _patchMap.containsKey(TextDelta$.deltaIndex)
          ? ((_patchMap[TextDelta$.deltaIndex] is Function)
                    ? _patchMap[TextDelta$.deltaIndex](this.deltaIndex)
                    : (_patchMap[TextDelta$.deltaIndex] is Patch)
                    ? _patchMap[TextDelta$.deltaIndex].applyTo(this.deltaIndex)
                    : _patchMap[TextDelta$.deltaIndex])
                as int
          : this.deltaIndex,
      isComplete: _patchMap.containsKey(TextDelta$.isComplete)
          ? ((_patchMap[TextDelta$.isComplete] is Function)
                    ? _patchMap[TextDelta$.isComplete](this.isComplete)
                    : (_patchMap[TextDelta$.isComplete] is Patch)
                    ? _patchMap[TextDelta$.isComplete].applyTo(this.isComplete)
                    : _patchMap[TextDelta$.isComplete])
                as bool
          : this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextDelta &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        content == other.content &&
        deltaIndex == other.deltaIndex &&
        isComplete == other.isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.content,
      this.deltaIndex,
      this.isComplete,
    );
  }

  @override
  String toString() {
    return 'TextDelta(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'deltaIndex: ${deltaIndex}' +
        ', ' +
        'isComplete: ${isComplete})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TextDeltaToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$TextDeltaToJson(this);
    json['__typename'] = 'TextDelta';
    return json;
  }
}

extension TextDeltaPropertyHelpers on TextDelta {
  bool get hasContent {
    return this.content.isNotEmpty;
  }

  bool get noContent {
    return this.content.isEmpty;
  }
}

extension TextDeltaSerialization on TextDelta {
  Map<String, dynamic> toJson() {
    return _$TextDeltaToJson(this);
  }
}

enum TextDelta$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  content,
  deltaIndex,
  isComplete,
}

class TextDeltaPatch extends PatchBase<TextDelta, TextDelta$> {
  TextDelta applyTo(TextDelta entity) {
    return entity.patchWithTextDelta(this);
  }

  TextDeltaPatch withEventId(String? value) {
    patchMap[TextDelta$.eventId] = value;
    return this;
  }

  TextDeltaPatch withSequenceNumber(int? value) {
    patchMap[TextDelta$.sequenceNumber] = value;
    return this;
  }

  TextDeltaPatch withTimestamp(DateTime? value) {
    patchMap[TextDelta$.timestamp] = value;
    return this;
  }

  TextDeltaPatch withMissionId(String? value) {
    patchMap[TextDelta$.missionId] = value;
    return this;
  }

  TextDeltaPatch withContent(String? value) {
    patchMap[TextDelta$.content] = value;
    return this;
  }

  TextDeltaPatch withDeltaIndex(int? value) {
    patchMap[TextDelta$.deltaIndex] = value;
    return this;
  }

  TextDeltaPatch withIsComplete(bool? value) {
    patchMap[TextDelta$.isComplete] = value;
    return this;
  }
}

/// Field descriptors for [TextDelta] query construction
abstract final class TextDeltaFields {
  static const eventId = Field<TextDelta, String>('eventId', _$eventId);

  static const sequenceNumber = Field<TextDelta, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<TextDelta, DateTime>('timestamp', _$timestamp);

  static const missionId = Field<TextDelta, String>('missionId', _$missionId);

  static const content = Field<TextDelta, String>('content', _$content);

  static const deltaIndex = Field<TextDelta, int>('deltaIndex', _$deltaIndex);

  static const isComplete = Field<TextDelta, bool>('isComplete', _$isComplete);

  static String _$eventId(TextDelta e) {
    return e.eventId;
  }

  static int _$sequenceNumber(TextDelta e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(TextDelta e) {
    return e.timestamp;
  }

  static String _$missionId(TextDelta e) {
    return e.missionId;
  }

  static String _$content(TextDelta e) {
    return e.content;
  }

  static int _$deltaIndex(TextDelta e) {
    return e.deltaIndex;
  }

  static bool _$isComplete(TextDelta e) {
    return e.isComplete;
  }
}

extension TextDeltaCompareE on TextDelta {
  Map<String, dynamic> compareToTextDelta(TextDelta other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (content != other.content) {
      diff['content'] = () => other.content;
    }

    if (deltaIndex != other.deltaIndex) {
      diff['deltaIndex'] = () => other.deltaIndex;
    }

    if (isComplete != other.isComplete) {
      diff['isComplete'] = () => other.isComplete;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class ToolCallStarted implements EngineEvent {
  ToolCallStarted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.toolCallId,
    required String this.toolName,
    required Map<String, dynamic> this.arguments,
    required int this.callIndex,
  });

  factory ToolCallStarted.fromJson(Map<String, dynamic> json) =>
      _$ToolCallStartedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String toolCallId;

  final String toolName;

  final Map<String, dynamic> arguments;

  final int callIndex;

  ToolCallStarted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? arguments,
    int? callIndex,
  }) {
    return ToolCallStarted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      callIndex: callIndex ?? this.callIndex,
    );
  }

  ToolCallStarted copyWithToolCallStarted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? arguments,
    int? callIndex,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      toolCallId: toolCallId,
      toolName: toolName,
      arguments: arguments,
      callIndex: callIndex,
    );
  }

  ToolCallStarted patchWithToolCallStarted([ToolCallStartedPatch? patchInput]) {
    final _patcher = patchInput ?? ToolCallStartedPatch();
    final _patchMap = _patcher.patchMap;
    return ToolCallStarted(
      eventId: _patchMap.containsKey(ToolCallStarted$.eventId)
          ? ((_patchMap[ToolCallStarted$.eventId] is Function)
                    ? _patchMap[ToolCallStarted$.eventId](this.eventId)
                    : (_patchMap[ToolCallStarted$.eventId] is Patch)
                    ? _patchMap[ToolCallStarted$.eventId].applyTo(this.eventId)
                    : _patchMap[ToolCallStarted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(ToolCallStarted$.sequenceNumber)
          ? ((_patchMap[ToolCallStarted$.sequenceNumber] is Function)
                    ? _patchMap[ToolCallStarted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[ToolCallStarted$.sequenceNumber] is Patch)
                    ? _patchMap[ToolCallStarted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[ToolCallStarted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(ToolCallStarted$.timestamp)
          ? ((_patchMap[ToolCallStarted$.timestamp] is Function)
                    ? _patchMap[ToolCallStarted$.timestamp](this.timestamp)
                    : (_patchMap[ToolCallStarted$.timestamp] is Patch)
                    ? _patchMap[ToolCallStarted$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ToolCallStarted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(ToolCallStarted$.missionId)
          ? ((_patchMap[ToolCallStarted$.missionId] is Function)
                    ? _patchMap[ToolCallStarted$.missionId](this.missionId)
                    : (_patchMap[ToolCallStarted$.missionId] is Patch)
                    ? _patchMap[ToolCallStarted$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[ToolCallStarted$.missionId])
                as String
          : this.missionId,
      toolCallId: _patchMap.containsKey(ToolCallStarted$.toolCallId)
          ? ((_patchMap[ToolCallStarted$.toolCallId] is Function)
                    ? _patchMap[ToolCallStarted$.toolCallId](this.toolCallId)
                    : (_patchMap[ToolCallStarted$.toolCallId] is Patch)
                    ? _patchMap[ToolCallStarted$.toolCallId].applyTo(
                        this.toolCallId,
                      )
                    : _patchMap[ToolCallStarted$.toolCallId])
                as String
          : this.toolCallId,
      toolName: _patchMap.containsKey(ToolCallStarted$.toolName)
          ? ((_patchMap[ToolCallStarted$.toolName] is Function)
                    ? _patchMap[ToolCallStarted$.toolName](this.toolName)
                    : (_patchMap[ToolCallStarted$.toolName] is Patch)
                    ? _patchMap[ToolCallStarted$.toolName].applyTo(
                        this.toolName,
                      )
                    : _patchMap[ToolCallStarted$.toolName])
                as String
          : this.toolName,
      arguments: _patchMap.containsKey(ToolCallStarted$.arguments)
          ? ((_patchMap[ToolCallStarted$.arguments] is Function)
                    ? _patchMap[ToolCallStarted$.arguments](this.arguments)
                    : (_patchMap[ToolCallStarted$.arguments] is Patch)
                    ? _patchMap[ToolCallStarted$.arguments].applyTo(
                        this.arguments,
                      )
                    : _patchMap[ToolCallStarted$.arguments])
                as Map<String, dynamic>
          : this.arguments,
      callIndex: _patchMap.containsKey(ToolCallStarted$.callIndex)
          ? ((_patchMap[ToolCallStarted$.callIndex] is Function)
                    ? _patchMap[ToolCallStarted$.callIndex](this.callIndex)
                    : (_patchMap[ToolCallStarted$.callIndex] is Patch)
                    ? _patchMap[ToolCallStarted$.callIndex].applyTo(
                        this.callIndex,
                      )
                    : _patchMap[ToolCallStarted$.callIndex])
                as int
          : this.callIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCallStarted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        toolCallId == other.toolCallId &&
        toolName == other.toolName &&
        arguments == other.arguments &&
        callIndex == other.callIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.toolCallId,
      this.toolName,
      this.arguments,
      this.callIndex,
    );
  }

  @override
  String toString() {
    return 'ToolCallStarted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'toolCallId: ${toolCallId}' +
        ', ' +
        'toolName: ${toolName}' +
        ', ' +
        'arguments: ${arguments}' +
        ', ' +
        'callIndex: ${callIndex})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolCallStartedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$ToolCallStartedToJson(this);
    json['__typename'] = 'ToolCallStarted';
    return json;
  }
}

extension ToolCallStartedPropertyHelpers on ToolCallStarted {
  bool get hasToolCallId {
    return this.toolCallId.isNotEmpty;
  }

  bool get noToolCallId {
    return this.toolCallId.isEmpty;
  }

  bool get hasToolName {
    return this.toolName.isNotEmpty;
  }

  bool get noToolName {
    return this.toolName.isEmpty;
  }

  bool get hasArguments {
    return this.arguments.isNotEmpty;
  }

  bool get noArguments {
    return this.arguments.isEmpty;
  }
}

extension ToolCallStartedSerialization on ToolCallStarted {
  Map<String, dynamic> toJson() {
    return _$ToolCallStartedToJson(this);
  }
}

enum ToolCallStarted$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  toolCallId,
  toolName,
  arguments,
  callIndex,
}

class ToolCallStartedPatch
    extends PatchBase<ToolCallStarted, ToolCallStarted$> {
  ToolCallStarted applyTo(ToolCallStarted entity) {
    return entity.patchWithToolCallStarted(this);
  }

  ToolCallStartedPatch withEventId(String? value) {
    patchMap[ToolCallStarted$.eventId] = value;
    return this;
  }

  ToolCallStartedPatch withSequenceNumber(int? value) {
    patchMap[ToolCallStarted$.sequenceNumber] = value;
    return this;
  }

  ToolCallStartedPatch withTimestamp(DateTime? value) {
    patchMap[ToolCallStarted$.timestamp] = value;
    return this;
  }

  ToolCallStartedPatch withMissionId(String? value) {
    patchMap[ToolCallStarted$.missionId] = value;
    return this;
  }

  ToolCallStartedPatch withToolCallId(String? value) {
    patchMap[ToolCallStarted$.toolCallId] = value;
    return this;
  }

  ToolCallStartedPatch withToolName(String? value) {
    patchMap[ToolCallStarted$.toolName] = value;
    return this;
  }

  ToolCallStartedPatch withArguments(Map<String, dynamic>? value) {
    patchMap[ToolCallStarted$.arguments] = value;
    return this;
  }

  ToolCallStartedPatch withCallIndex(int? value) {
    patchMap[ToolCallStarted$.callIndex] = value;
    return this;
  }
}

/// Field descriptors for [ToolCallStarted] query construction
abstract final class ToolCallStartedFields {
  static const eventId = Field<ToolCallStarted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<ToolCallStarted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<ToolCallStarted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<ToolCallStarted, String>(
    'missionId',
    _$missionId,
  );

  static const toolCallId = Field<ToolCallStarted, String>(
    'toolCallId',
    _$toolCallId,
  );

  static const toolName = Field<ToolCallStarted, String>(
    'toolName',
    _$toolName,
  );

  static const arguments = Field<ToolCallStarted, Map<String, dynamic>>(
    'arguments',
    _$arguments,
  );

  static const callIndex = Field<ToolCallStarted, int>(
    'callIndex',
    _$callIndex,
  );

  static String _$eventId(ToolCallStarted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(ToolCallStarted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(ToolCallStarted e) {
    return e.timestamp;
  }

  static String _$missionId(ToolCallStarted e) {
    return e.missionId;
  }

  static String _$toolCallId(ToolCallStarted e) {
    return e.toolCallId;
  }

  static String _$toolName(ToolCallStarted e) {
    return e.toolName;
  }

  static Map<String, dynamic> _$arguments(ToolCallStarted e) {
    return e.arguments;
  }

  static int _$callIndex(ToolCallStarted e) {
    return e.callIndex;
  }
}

extension ToolCallStartedCompareE on ToolCallStarted {
  Map<String, dynamic> compareToToolCallStarted(ToolCallStarted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (toolCallId != other.toolCallId) {
      diff['toolCallId'] = () => other.toolCallId;
    }

    if (toolName != other.toolName) {
      diff['toolName'] = () => other.toolName;
    }

    if (arguments != other.arguments) {
      diff['arguments'] = () => other.arguments;
    }

    if (callIndex != other.callIndex) {
      diff['callIndex'] = () => other.callIndex;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class ToolCallCompleted implements EngineEvent {
  ToolCallCompleted({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.toolCallId,
    required String this.result,
    String? this.errorMessage,
    required int this.durationMs,
  });

  factory ToolCallCompleted.fromJson(Map<String, dynamic> json) =>
      _$ToolCallCompletedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String toolCallId;

  final String result;

  final String? errorMessage;

  final int durationMs;

  ToolCallCompleted copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? toolCallId,
    String? result,
    String? errorMessage,
    int? durationMs,
  }) {
    return ToolCallCompleted(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      toolCallId: toolCallId ?? this.toolCallId,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  ToolCallCompleted copyWithToolCallCompleted({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? toolCallId,
    String? result,
    String? errorMessage,
    int? durationMs,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      toolCallId: toolCallId,
      result: result,
      errorMessage: errorMessage,
      durationMs: durationMs,
    );
  }

  ToolCallCompleted patchWithToolCallCompleted([
    ToolCallCompletedPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ToolCallCompletedPatch();
    final _patchMap = _patcher.patchMap;
    return ToolCallCompleted(
      eventId: _patchMap.containsKey(ToolCallCompleted$.eventId)
          ? ((_patchMap[ToolCallCompleted$.eventId] is Function)
                    ? _patchMap[ToolCallCompleted$.eventId](this.eventId)
                    : (_patchMap[ToolCallCompleted$.eventId] is Patch)
                    ? _patchMap[ToolCallCompleted$.eventId].applyTo(
                        this.eventId,
                      )
                    : _patchMap[ToolCallCompleted$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(ToolCallCompleted$.sequenceNumber)
          ? ((_patchMap[ToolCallCompleted$.sequenceNumber] is Function)
                    ? _patchMap[ToolCallCompleted$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[ToolCallCompleted$.sequenceNumber] is Patch)
                    ? _patchMap[ToolCallCompleted$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[ToolCallCompleted$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(ToolCallCompleted$.timestamp)
          ? ((_patchMap[ToolCallCompleted$.timestamp] is Function)
                    ? _patchMap[ToolCallCompleted$.timestamp](this.timestamp)
                    : (_patchMap[ToolCallCompleted$.timestamp] is Patch)
                    ? _patchMap[ToolCallCompleted$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ToolCallCompleted$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(ToolCallCompleted$.missionId)
          ? ((_patchMap[ToolCallCompleted$.missionId] is Function)
                    ? _patchMap[ToolCallCompleted$.missionId](this.missionId)
                    : (_patchMap[ToolCallCompleted$.missionId] is Patch)
                    ? _patchMap[ToolCallCompleted$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[ToolCallCompleted$.missionId])
                as String
          : this.missionId,
      toolCallId: _patchMap.containsKey(ToolCallCompleted$.toolCallId)
          ? ((_patchMap[ToolCallCompleted$.toolCallId] is Function)
                    ? _patchMap[ToolCallCompleted$.toolCallId](this.toolCallId)
                    : (_patchMap[ToolCallCompleted$.toolCallId] is Patch)
                    ? _patchMap[ToolCallCompleted$.toolCallId].applyTo(
                        this.toolCallId,
                      )
                    : _patchMap[ToolCallCompleted$.toolCallId])
                as String
          : this.toolCallId,
      result: _patchMap.containsKey(ToolCallCompleted$.result)
          ? ((_patchMap[ToolCallCompleted$.result] is Function)
                    ? _patchMap[ToolCallCompleted$.result](this.result)
                    : (_patchMap[ToolCallCompleted$.result] is Patch)
                    ? _patchMap[ToolCallCompleted$.result].applyTo(this.result)
                    : _patchMap[ToolCallCompleted$.result])
                as String
          : this.result,
      errorMessage: _patchMap.containsKey(ToolCallCompleted$.errorMessage)
          ? ((_patchMap[ToolCallCompleted$.errorMessage] is Function)
                    ? _patchMap[ToolCallCompleted$.errorMessage](
                        this.errorMessage,
                      )
                    : (_patchMap[ToolCallCompleted$.errorMessage] is Patch)
                    ? _patchMap[ToolCallCompleted$.errorMessage].applyTo(
                        this.errorMessage,
                      )
                    : _patchMap[ToolCallCompleted$.errorMessage])
                as String?
          : this.errorMessage,
      durationMs: _patchMap.containsKey(ToolCallCompleted$.durationMs)
          ? ((_patchMap[ToolCallCompleted$.durationMs] is Function)
                    ? _patchMap[ToolCallCompleted$.durationMs](this.durationMs)
                    : (_patchMap[ToolCallCompleted$.durationMs] is Patch)
                    ? _patchMap[ToolCallCompleted$.durationMs].applyTo(
                        this.durationMs,
                      )
                    : _patchMap[ToolCallCompleted$.durationMs])
                as int
          : this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCallCompleted &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        toolCallId == other.toolCallId &&
        result == other.result &&
        errorMessage == other.errorMessage &&
        durationMs == other.durationMs;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.toolCallId,
      this.result,
      this.errorMessage,
      this.durationMs,
    );
  }

  @override
  String toString() {
    return 'ToolCallCompleted(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'toolCallId: ${toolCallId}' +
        ', ' +
        'result: ${result}' +
        ', ' +
        'errorMessage: ${errorMessage}' +
        ', ' +
        'durationMs: ${durationMs})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolCallCompletedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$ToolCallCompletedToJson(this);
    json['__typename'] = 'ToolCallCompleted';
    return json;
  }
}

extension ToolCallCompletedPropertyHelpers on ToolCallCompleted {
  bool get hasToolCallId {
    return this.toolCallId.isNotEmpty;
  }

  bool get noToolCallId {
    return this.toolCallId.isEmpty;
  }

  bool get hasResult {
    return this.result.isNotEmpty;
  }

  bool get noResult {
    return this.result.isEmpty;
  }

  bool get hasErrorMessage {
    return this.errorMessage?.isNotEmpty == true;
  }

  bool get noErrorMessage {
    return this.errorMessage?.isEmpty ?? true;
  }

  String get errorMessageRequired {
    return this.errorMessage ??
        (throw StateError('errorMessage is required but was null'));
  }
}

extension ToolCallCompletedSerialization on ToolCallCompleted {
  Map<String, dynamic> toJson() {
    return _$ToolCallCompletedToJson(this);
  }
}

enum ToolCallCompleted$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  toolCallId,
  result,
  errorMessage,
  durationMs,
}

class ToolCallCompletedPatch
    extends PatchBase<ToolCallCompleted, ToolCallCompleted$> {
  ToolCallCompleted applyTo(ToolCallCompleted entity) {
    return entity.patchWithToolCallCompleted(this);
  }

  ToolCallCompletedPatch withEventId(String? value) {
    patchMap[ToolCallCompleted$.eventId] = value;
    return this;
  }

  ToolCallCompletedPatch withSequenceNumber(int? value) {
    patchMap[ToolCallCompleted$.sequenceNumber] = value;
    return this;
  }

  ToolCallCompletedPatch withTimestamp(DateTime? value) {
    patchMap[ToolCallCompleted$.timestamp] = value;
    return this;
  }

  ToolCallCompletedPatch withMissionId(String? value) {
    patchMap[ToolCallCompleted$.missionId] = value;
    return this;
  }

  ToolCallCompletedPatch withToolCallId(String? value) {
    patchMap[ToolCallCompleted$.toolCallId] = value;
    return this;
  }

  ToolCallCompletedPatch withResult(String? value) {
    patchMap[ToolCallCompleted$.result] = value;
    return this;
  }

  ToolCallCompletedPatch withErrorMessage(String? value) {
    patchMap[ToolCallCompleted$.errorMessage] = value;
    return this;
  }

  ToolCallCompletedPatch withDurationMs(int? value) {
    patchMap[ToolCallCompleted$.durationMs] = value;
    return this;
  }
}

/// Field descriptors for [ToolCallCompleted] query construction
abstract final class ToolCallCompletedFields {
  static const eventId = Field<ToolCallCompleted, String>('eventId', _$eventId);

  static const sequenceNumber = Field<ToolCallCompleted, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<ToolCallCompleted, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<ToolCallCompleted, String>(
    'missionId',
    _$missionId,
  );

  static const toolCallId = Field<ToolCallCompleted, String>(
    'toolCallId',
    _$toolCallId,
  );

  static const result = Field<ToolCallCompleted, String>('result', _$result);

  static const errorMessage = Field<ToolCallCompleted, String?>(
    'errorMessage',
    _$errorMessage,
  );

  static const durationMs = Field<ToolCallCompleted, int>(
    'durationMs',
    _$durationMs,
  );

  static String _$eventId(ToolCallCompleted e) {
    return e.eventId;
  }

  static int _$sequenceNumber(ToolCallCompleted e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(ToolCallCompleted e) {
    return e.timestamp;
  }

  static String _$missionId(ToolCallCompleted e) {
    return e.missionId;
  }

  static String _$toolCallId(ToolCallCompleted e) {
    return e.toolCallId;
  }

  static String _$result(ToolCallCompleted e) {
    return e.result;
  }

  static String? _$errorMessage(ToolCallCompleted e) {
    return e.errorMessage;
  }

  static int _$durationMs(ToolCallCompleted e) {
    return e.durationMs;
  }
}

extension ToolCallCompletedCompareE on ToolCallCompleted {
  Map<String, dynamic> compareToToolCallCompleted(ToolCallCompleted other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (toolCallId != other.toolCallId) {
      diff['toolCallId'] = () => other.toolCallId;
    }

    if (result != other.result) {
      diff['result'] = () => other.result;
    }

    if (errorMessage != other.errorMessage) {
      diff['errorMessage'] = () => other.errorMessage;
    }

    if (durationMs != other.durationMs) {
      diff['durationMs'] = () => other.durationMs;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class ProviderError implements EngineEvent {
  ProviderError({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.errorType,
    required String this.message,
    required bool this.isRecoverable,
  });

  factory ProviderError.fromJson(Map<String, dynamic> json) =>
      _$ProviderErrorFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String errorType;

  final String message;

  final bool isRecoverable;

  ProviderError copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? errorType,
    String? message,
    bool? isRecoverable,
  }) {
    return ProviderError(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      errorType: errorType ?? this.errorType,
      message: message ?? this.message,
      isRecoverable: isRecoverable ?? this.isRecoverable,
    );
  }

  ProviderError copyWithProviderError({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? errorType,
    String? message,
    bool? isRecoverable,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      errorType: errorType,
      message: message,
      isRecoverable: isRecoverable,
    );
  }

  ProviderError patchWithProviderError([ProviderErrorPatch? patchInput]) {
    final _patcher = patchInput ?? ProviderErrorPatch();
    final _patchMap = _patcher.patchMap;
    return ProviderError(
      eventId: _patchMap.containsKey(ProviderError$.eventId)
          ? ((_patchMap[ProviderError$.eventId] is Function)
                    ? _patchMap[ProviderError$.eventId](this.eventId)
                    : (_patchMap[ProviderError$.eventId] is Patch)
                    ? _patchMap[ProviderError$.eventId].applyTo(this.eventId)
                    : _patchMap[ProviderError$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(ProviderError$.sequenceNumber)
          ? ((_patchMap[ProviderError$.sequenceNumber] is Function)
                    ? _patchMap[ProviderError$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[ProviderError$.sequenceNumber] is Patch)
                    ? _patchMap[ProviderError$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[ProviderError$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(ProviderError$.timestamp)
          ? ((_patchMap[ProviderError$.timestamp] is Function)
                    ? _patchMap[ProviderError$.timestamp](this.timestamp)
                    : (_patchMap[ProviderError$.timestamp] is Patch)
                    ? _patchMap[ProviderError$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ProviderError$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(ProviderError$.missionId)
          ? ((_patchMap[ProviderError$.missionId] is Function)
                    ? _patchMap[ProviderError$.missionId](this.missionId)
                    : (_patchMap[ProviderError$.missionId] is Patch)
                    ? _patchMap[ProviderError$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[ProviderError$.missionId])
                as String
          : this.missionId,
      errorType: _patchMap.containsKey(ProviderError$.errorType)
          ? ((_patchMap[ProviderError$.errorType] is Function)
                    ? _patchMap[ProviderError$.errorType](this.errorType)
                    : (_patchMap[ProviderError$.errorType] is Patch)
                    ? _patchMap[ProviderError$.errorType].applyTo(
                        this.errorType,
                      )
                    : _patchMap[ProviderError$.errorType])
                as String
          : this.errorType,
      message: _patchMap.containsKey(ProviderError$.message)
          ? ((_patchMap[ProviderError$.message] is Function)
                    ? _patchMap[ProviderError$.message](this.message)
                    : (_patchMap[ProviderError$.message] is Patch)
                    ? _patchMap[ProviderError$.message].applyTo(this.message)
                    : _patchMap[ProviderError$.message])
                as String
          : this.message,
      isRecoverable: _patchMap.containsKey(ProviderError$.isRecoverable)
          ? ((_patchMap[ProviderError$.isRecoverable] is Function)
                    ? _patchMap[ProviderError$.isRecoverable](
                        this.isRecoverable,
                      )
                    : (_patchMap[ProviderError$.isRecoverable] is Patch)
                    ? _patchMap[ProviderError$.isRecoverable].applyTo(
                        this.isRecoverable,
                      )
                    : _patchMap[ProviderError$.isRecoverable])
                as bool
          : this.isRecoverable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProviderError &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        errorType == other.errorType &&
        message == other.message &&
        isRecoverable == other.isRecoverable;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.errorType,
      this.message,
      this.isRecoverable,
    );
  }

  @override
  String toString() {
    return 'ProviderError(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'errorType: ${errorType}' +
        ', ' +
        'message: ${message}' +
        ', ' +
        'isRecoverable: ${isRecoverable})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProviderErrorToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$ProviderErrorToJson(this);
    json['__typename'] = 'ProviderError';
    return json;
  }
}

extension ProviderErrorPropertyHelpers on ProviderError {
  bool get hasErrorType {
    return this.errorType.isNotEmpty;
  }

  bool get noErrorType {
    return this.errorType.isEmpty;
  }

  bool get hasMessage {
    return this.message.isNotEmpty;
  }

  bool get noMessage {
    return this.message.isEmpty;
  }
}

extension ProviderErrorSerialization on ProviderError {
  Map<String, dynamic> toJson() {
    return _$ProviderErrorToJson(this);
  }
}

enum ProviderError$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  errorType,
  message,
  isRecoverable,
}

class ProviderErrorPatch extends PatchBase<ProviderError, ProviderError$> {
  ProviderError applyTo(ProviderError entity) {
    return entity.patchWithProviderError(this);
  }

  ProviderErrorPatch withEventId(String? value) {
    patchMap[ProviderError$.eventId] = value;
    return this;
  }

  ProviderErrorPatch withSequenceNumber(int? value) {
    patchMap[ProviderError$.sequenceNumber] = value;
    return this;
  }

  ProviderErrorPatch withTimestamp(DateTime? value) {
    patchMap[ProviderError$.timestamp] = value;
    return this;
  }

  ProviderErrorPatch withMissionId(String? value) {
    patchMap[ProviderError$.missionId] = value;
    return this;
  }

  ProviderErrorPatch withErrorType(String? value) {
    patchMap[ProviderError$.errorType] = value;
    return this;
  }

  ProviderErrorPatch withMessage(String? value) {
    patchMap[ProviderError$.message] = value;
    return this;
  }

  ProviderErrorPatch withIsRecoverable(bool? value) {
    patchMap[ProviderError$.isRecoverable] = value;
    return this;
  }
}

/// Field descriptors for [ProviderError] query construction
abstract final class ProviderErrorFields {
  static const eventId = Field<ProviderError, String>('eventId', _$eventId);

  static const sequenceNumber = Field<ProviderError, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<ProviderError, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<ProviderError, String>(
    'missionId',
    _$missionId,
  );

  static const errorType = Field<ProviderError, String>(
    'errorType',
    _$errorType,
  );

  static const message = Field<ProviderError, String>('message', _$message);

  static const isRecoverable = Field<ProviderError, bool>(
    'isRecoverable',
    _$isRecoverable,
  );

  static String _$eventId(ProviderError e) {
    return e.eventId;
  }

  static int _$sequenceNumber(ProviderError e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(ProviderError e) {
    return e.timestamp;
  }

  static String _$missionId(ProviderError e) {
    return e.missionId;
  }

  static String _$errorType(ProviderError e) {
    return e.errorType;
  }

  static String _$message(ProviderError e) {
    return e.message;
  }

  static bool _$isRecoverable(ProviderError e) {
    return e.isRecoverable;
  }
}

extension ProviderErrorCompareE on ProviderError {
  Map<String, dynamic> compareToProviderError(ProviderError other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (errorType != other.errorType) {
      diff['errorType'] = () => other.errorType;
    }

    if (message != other.message) {
      diff['message'] = () => other.message;
    }

    if (isRecoverable != other.isRecoverable) {
      diff['isRecoverable'] = () => other.isRecoverable;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class SteeringInjected implements EngineEvent {
  SteeringInjected({
    required String this.eventId,
    required int this.sequenceNumber,
    required DateTime this.timestamp,
    required String this.missionId,
    required String this.messageId,
    required String this.content,
    required int this.injectionPoint,
  });

  factory SteeringInjected.fromJson(Map<String, dynamic> json) =>
      _$SteeringInjectedFromJson(json);

  final String eventId;

  final int sequenceNumber;

  final DateTime timestamp;

  final String missionId;

  final String messageId;

  final String content;

  final int injectionPoint;

  SteeringInjected copyWith({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? messageId,
    String? content,
    int? injectionPoint,
  }) {
    return SteeringInjected(
      eventId: eventId ?? this.eventId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      missionId: missionId ?? this.missionId,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      injectionPoint: injectionPoint ?? this.injectionPoint,
    );
  }

  SteeringInjected copyWithSteeringInjected({
    String? eventId,
    int? sequenceNumber,
    DateTime? timestamp,
    String? missionId,
    String? messageId,
    String? content,
    int? injectionPoint,
  }) {
    return copyWith(
      eventId: eventId,
      sequenceNumber: sequenceNumber,
      timestamp: timestamp,
      missionId: missionId,
      messageId: messageId,
      content: content,
      injectionPoint: injectionPoint,
    );
  }

  SteeringInjected patchWithSteeringInjected([
    SteeringInjectedPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? SteeringInjectedPatch();
    final _patchMap = _patcher.patchMap;
    return SteeringInjected(
      eventId: _patchMap.containsKey(SteeringInjected$.eventId)
          ? ((_patchMap[SteeringInjected$.eventId] is Function)
                    ? _patchMap[SteeringInjected$.eventId](this.eventId)
                    : (_patchMap[SteeringInjected$.eventId] is Patch)
                    ? _patchMap[SteeringInjected$.eventId].applyTo(this.eventId)
                    : _patchMap[SteeringInjected$.eventId])
                as String
          : this.eventId,
      sequenceNumber: _patchMap.containsKey(SteeringInjected$.sequenceNumber)
          ? ((_patchMap[SteeringInjected$.sequenceNumber] is Function)
                    ? _patchMap[SteeringInjected$.sequenceNumber](
                        this.sequenceNumber,
                      )
                    : (_patchMap[SteeringInjected$.sequenceNumber] is Patch)
                    ? _patchMap[SteeringInjected$.sequenceNumber].applyTo(
                        this.sequenceNumber,
                      )
                    : _patchMap[SteeringInjected$.sequenceNumber])
                as int
          : this.sequenceNumber,
      timestamp: _patchMap.containsKey(SteeringInjected$.timestamp)
          ? ((_patchMap[SteeringInjected$.timestamp] is Function)
                    ? _patchMap[SteeringInjected$.timestamp](this.timestamp)
                    : (_patchMap[SteeringInjected$.timestamp] is Patch)
                    ? _patchMap[SteeringInjected$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[SteeringInjected$.timestamp])
                as DateTime
          : this.timestamp,
      missionId: _patchMap.containsKey(SteeringInjected$.missionId)
          ? ((_patchMap[SteeringInjected$.missionId] is Function)
                    ? _patchMap[SteeringInjected$.missionId](this.missionId)
                    : (_patchMap[SteeringInjected$.missionId] is Patch)
                    ? _patchMap[SteeringInjected$.missionId].applyTo(
                        this.missionId,
                      )
                    : _patchMap[SteeringInjected$.missionId])
                as String
          : this.missionId,
      messageId: _patchMap.containsKey(SteeringInjected$.messageId)
          ? ((_patchMap[SteeringInjected$.messageId] is Function)
                    ? _patchMap[SteeringInjected$.messageId](this.messageId)
                    : (_patchMap[SteeringInjected$.messageId] is Patch)
                    ? _patchMap[SteeringInjected$.messageId].applyTo(
                        this.messageId,
                      )
                    : _patchMap[SteeringInjected$.messageId])
                as String
          : this.messageId,
      content: _patchMap.containsKey(SteeringInjected$.content)
          ? ((_patchMap[SteeringInjected$.content] is Function)
                    ? _patchMap[SteeringInjected$.content](this.content)
                    : (_patchMap[SteeringInjected$.content] is Patch)
                    ? _patchMap[SteeringInjected$.content].applyTo(this.content)
                    : _patchMap[SteeringInjected$.content])
                as String
          : this.content,
      injectionPoint: _patchMap.containsKey(SteeringInjected$.injectionPoint)
          ? ((_patchMap[SteeringInjected$.injectionPoint] is Function)
                    ? _patchMap[SteeringInjected$.injectionPoint](
                        this.injectionPoint,
                      )
                    : (_patchMap[SteeringInjected$.injectionPoint] is Patch)
                    ? _patchMap[SteeringInjected$.injectionPoint].applyTo(
                        this.injectionPoint,
                      )
                    : _patchMap[SteeringInjected$.injectionPoint])
                as int
          : this.injectionPoint,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SteeringInjected &&
        eventId == other.eventId &&
        sequenceNumber == other.sequenceNumber &&
        timestamp == other.timestamp &&
        missionId == other.missionId &&
        messageId == other.messageId &&
        content == other.content &&
        injectionPoint == other.injectionPoint;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.eventId,
      this.sequenceNumber,
      this.timestamp,
      this.missionId,
      this.messageId,
      this.content,
      this.injectionPoint,
    );
  }

  @override
  String toString() {
    return 'SteeringInjected(' +
        'eventId: ${eventId}' +
        ', ' +
        'sequenceNumber: ${sequenceNumber}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'missionId: ${missionId}' +
        ', ' +
        'messageId: ${messageId}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'injectionPoint: ${injectionPoint})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SteeringInjectedToJson(this);
    _sanitizeJson(data);
    return data;
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$SteeringInjectedToJson(this);
    json['__typename'] = 'SteeringInjected';
    return json;
  }
}

extension SteeringInjectedPropertyHelpers on SteeringInjected {
  bool get hasMessageId {
    return this.messageId.isNotEmpty;
  }

  bool get noMessageId {
    return this.messageId.isEmpty;
  }

  bool get hasContent {
    return this.content.isNotEmpty;
  }

  bool get noContent {
    return this.content.isEmpty;
  }
}

extension SteeringInjectedSerialization on SteeringInjected {
  Map<String, dynamic> toJson() {
    return _$SteeringInjectedToJson(this);
  }
}

enum SteeringInjected$ {
  eventId,
  sequenceNumber,
  timestamp,
  missionId,
  messageId,
  content,
  injectionPoint,
}

class SteeringInjectedPatch
    extends PatchBase<SteeringInjected, SteeringInjected$> {
  SteeringInjected applyTo(SteeringInjected entity) {
    return entity.patchWithSteeringInjected(this);
  }

  SteeringInjectedPatch withEventId(String? value) {
    patchMap[SteeringInjected$.eventId] = value;
    return this;
  }

  SteeringInjectedPatch withSequenceNumber(int? value) {
    patchMap[SteeringInjected$.sequenceNumber] = value;
    return this;
  }

  SteeringInjectedPatch withTimestamp(DateTime? value) {
    patchMap[SteeringInjected$.timestamp] = value;
    return this;
  }

  SteeringInjectedPatch withMissionId(String? value) {
    patchMap[SteeringInjected$.missionId] = value;
    return this;
  }

  SteeringInjectedPatch withMessageId(String? value) {
    patchMap[SteeringInjected$.messageId] = value;
    return this;
  }

  SteeringInjectedPatch withContent(String? value) {
    patchMap[SteeringInjected$.content] = value;
    return this;
  }

  SteeringInjectedPatch withInjectionPoint(int? value) {
    patchMap[SteeringInjected$.injectionPoint] = value;
    return this;
  }
}

/// Field descriptors for [SteeringInjected] query construction
abstract final class SteeringInjectedFields {
  static const eventId = Field<SteeringInjected, String>('eventId', _$eventId);

  static const sequenceNumber = Field<SteeringInjected, int>(
    'sequenceNumber',
    _$sequenceNumber,
  );

  static const timestamp = Field<SteeringInjected, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const missionId = Field<SteeringInjected, String>(
    'missionId',
    _$missionId,
  );

  static const messageId = Field<SteeringInjected, String>(
    'messageId',
    _$messageId,
  );

  static const content = Field<SteeringInjected, String>('content', _$content);

  static const injectionPoint = Field<SteeringInjected, int>(
    'injectionPoint',
    _$injectionPoint,
  );

  static String _$eventId(SteeringInjected e) {
    return e.eventId;
  }

  static int _$sequenceNumber(SteeringInjected e) {
    return e.sequenceNumber;
  }

  static DateTime _$timestamp(SteeringInjected e) {
    return e.timestamp;
  }

  static String _$missionId(SteeringInjected e) {
    return e.missionId;
  }

  static String _$messageId(SteeringInjected e) {
    return e.messageId;
  }

  static String _$content(SteeringInjected e) {
    return e.content;
  }

  static int _$injectionPoint(SteeringInjected e) {
    return e.injectionPoint;
  }
}

extension SteeringInjectedCompareE on SteeringInjected {
  Map<String, dynamic> compareToSteeringInjected(SteeringInjected other) {
    final Map<String, dynamic> diff = {};

    if (eventId != other.eventId) {
      diff['eventId'] = () => other.eventId;
    }

    if (sequenceNumber != other.sequenceNumber) {
      diff['sequenceNumber'] = () => other.sequenceNumber;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (missionId != other.missionId) {
      diff['missionId'] = () => other.missionId;
    }

    if (messageId != other.messageId) {
      diff['messageId'] = () => other.messageId;
    }

    if (content != other.content) {
      diff['content'] = () => other.content;
    }

    if (injectionPoint != other.injectionPoint) {
      diff['injectionPoint'] = () => other.injectionPoint;
    }
    return diff;
  }
}
