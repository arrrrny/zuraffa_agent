// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'turn_context.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class TurnContext {
  TurnContext({
    String? id,
    required int this.turnNumber,
    required List<String> this.messageIds,
    required DateTime this.turnStartTime,
    required List<String> this.toolCallIds,
  }) : this.id = id ?? const Uuid().v4();

  factory TurnContext.fromJson(Map<String, dynamic> json) =>
      _$TurnContextFromJson(json);

  final String id;

  final int turnNumber;

  final List<String> messageIds;

  final DateTime turnStartTime;

  final List<String> toolCallIds;

  TurnContext copyWith({
    String? id,
    int? turnNumber,
    List<String>? messageIds,
    DateTime? turnStartTime,
    List<String>? toolCallIds,
  }) {
    return TurnContext(
      id: id ?? this.id,
      turnNumber: turnNumber ?? this.turnNumber,
      messageIds: messageIds ?? this.messageIds,
      turnStartTime: turnStartTime ?? this.turnStartTime,
      toolCallIds: toolCallIds ?? this.toolCallIds,
    );
  }

  TurnContext copyWithTurnContext({
    String? id,
    int? turnNumber,
    List<String>? messageIds,
    DateTime? turnStartTime,
    List<String>? toolCallIds,
  }) {
    return copyWith(
      id: id,
      turnNumber: turnNumber,
      messageIds: messageIds,
      turnStartTime: turnStartTime,
      toolCallIds: toolCallIds,
    );
  }

  TurnContext patchWithTurnContext([TurnContextPatch? patchInput]) {
    final _patcher = patchInput ?? TurnContextPatch();
    final _patchMap = _patcher.patchMap;
    return TurnContext(
      id: _patchMap.containsKey(TurnContext$.id)
          ? ((_patchMap[TurnContext$.id] is Function)
                    ? _patchMap[TurnContext$.id](this.id)
                    : (_patchMap[TurnContext$.id] is Patch)
                    ? _patchMap[TurnContext$.id].applyTo(this.id)
                    : _patchMap[TurnContext$.id])
                as String
          : this.id,
      turnNumber: _patchMap.containsKey(TurnContext$.turnNumber)
          ? ((_patchMap[TurnContext$.turnNumber] is Function)
                    ? _patchMap[TurnContext$.turnNumber](this.turnNumber)
                    : (_patchMap[TurnContext$.turnNumber] is Patch)
                    ? _patchMap[TurnContext$.turnNumber].applyTo(
                        this.turnNumber,
                      )
                    : _patchMap[TurnContext$.turnNumber])
                as int
          : this.turnNumber,
      messageIds: _patchMap.containsKey(TurnContext$.messageIds)
          ? ((_patchMap[TurnContext$.messageIds] is Function)
                    ? _patchMap[TurnContext$.messageIds](this.messageIds)
                    : (_patchMap[TurnContext$.messageIds] is Patch)
                    ? _patchMap[TurnContext$.messageIds].applyTo(
                        this.messageIds,
                      )
                    : _patchMap[TurnContext$.messageIds])
                as List<String>
          : this.messageIds,
      turnStartTime: _patchMap.containsKey(TurnContext$.turnStartTime)
          ? ((_patchMap[TurnContext$.turnStartTime] is Function)
                    ? _patchMap[TurnContext$.turnStartTime](this.turnStartTime)
                    : (_patchMap[TurnContext$.turnStartTime] is Patch)
                    ? _patchMap[TurnContext$.turnStartTime].applyTo(
                        this.turnStartTime,
                      )
                    : _patchMap[TurnContext$.turnStartTime])
                as DateTime
          : this.turnStartTime,
      toolCallIds: _patchMap.containsKey(TurnContext$.toolCallIds)
          ? ((_patchMap[TurnContext$.toolCallIds] is Function)
                    ? _patchMap[TurnContext$.toolCallIds](this.toolCallIds)
                    : (_patchMap[TurnContext$.toolCallIds] is Patch)
                    ? _patchMap[TurnContext$.toolCallIds].applyTo(
                        this.toolCallIds,
                      )
                    : _patchMap[TurnContext$.toolCallIds])
                as List<String>
          : this.toolCallIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnContext &&
        id == other.id &&
        turnNumber == other.turnNumber &&
        messageIds == other.messageIds &&
        turnStartTime == other.turnStartTime &&
        toolCallIds == other.toolCallIds;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.turnNumber,
      this.messageIds,
      this.turnStartTime,
      this.toolCallIds,
    );
  }

  @override
  String toString() {
    return 'TurnContext(' +
        'id: ${id}' +
        ', ' +
        'turnNumber: ${turnNumber}' +
        ', ' +
        'messageIds: ${messageIds}' +
        ', ' +
        'turnStartTime: ${turnStartTime}' +
        ', ' +
        'toolCallIds: ${toolCallIds})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TurnContextToJson(this);
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
}

extension TurnContextPropertyHelpers on TurnContext {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasMessageIds {
    return this.messageIds.isNotEmpty;
  }

  bool get noMessageIds {
    return this.messageIds.isEmpty;
  }

  bool get hasToolCallIds {
    return this.toolCallIds.isNotEmpty;
  }

  bool get noToolCallIds {
    return this.toolCallIds.isEmpty;
  }
}

extension TurnContextSerialization on TurnContext {
  Map<String, dynamic> toJson() {
    return _$TurnContextToJson(this);
  }
}

enum TurnContext$ { id, turnNumber, messageIds, turnStartTime, toolCallIds }

class TurnContextPatch extends PatchBase<TurnContext, TurnContext$> {
  TurnContext applyTo(TurnContext entity) {
    return entity.patchWithTurnContext(this);
  }

  TurnContextPatch withId(String? value) {
    patchMap[TurnContext$.id] = value;
    return this;
  }

  TurnContextPatch withTurnNumber(int? value) {
    patchMap[TurnContext$.turnNumber] = value;
    return this;
  }

  TurnContextPatch withMessageIds(List<String>? value) {
    patchMap[TurnContext$.messageIds] = value;
    return this;
  }

  TurnContextPatch withTurnStartTime(DateTime? value) {
    patchMap[TurnContext$.turnStartTime] = value;
    return this;
  }

  TurnContextPatch withToolCallIds(List<String>? value) {
    patchMap[TurnContext$.toolCallIds] = value;
    return this;
  }
}

/// Field descriptors for [TurnContext] query construction
abstract final class TurnContextFields {
  static const id = Field<TurnContext, String>('id', _$id);

  static const turnNumber = Field<TurnContext, int>('turnNumber', _$turnNumber);

  static const messageIds = Field<TurnContext, List<String>>(
    'messageIds',
    _$messageIds,
  );

  static const turnStartTime = Field<TurnContext, DateTime>(
    'turnStartTime',
    _$turnStartTime,
  );

  static const toolCallIds = Field<TurnContext, List<String>>(
    'toolCallIds',
    _$toolCallIds,
  );

  static String _$id(TurnContext e) {
    return e.id;
  }

  static int _$turnNumber(TurnContext e) {
    return e.turnNumber;
  }

  static List<String> _$messageIds(TurnContext e) {
    return e.messageIds;
  }

  static DateTime _$turnStartTime(TurnContext e) {
    return e.turnStartTime;
  }

  static List<String> _$toolCallIds(TurnContext e) {
    return e.toolCallIds;
  }
}

extension TurnContextCompareE on TurnContext {
  Map<String, dynamic> compareToTurnContext(TurnContext other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (turnNumber != other.turnNumber) {
      diff['turnNumber'] = () => other.turnNumber;
    }

    if (messageIds != other.messageIds) {
      diff['messageIds'] = () => other.messageIds;
    }

    if (turnStartTime != other.turnStartTime) {
      diff['turnStartTime'] = () => other.turnStartTime;
    }

    if (toolCallIds != other.toolCallIds) {
      diff['toolCallIds'] = () => other.toolCallIds;
    }
    return diff;
  }
}
