// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'turn_record.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class TurnRecord {
  TurnRecord({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required int this.turnNumber,
    required List<String> this.messageEntryIds,
    required List<String> this.toolInvocationEntryIds,
    required String this.stopReason,
    required DateTime this.startedAt,
    required DateTime this.endedAt,
    required int this.durationMs,
  });

  factory TurnRecord.fromJson(Map<String, dynamic> json) =>
      _$TurnRecordFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final int turnNumber;

  final List<String> messageEntryIds;

  final List<String> toolInvocationEntryIds;

  final String stopReason;

  final DateTime startedAt;

  final DateTime endedAt;

  final int durationMs;

  TurnRecord copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    int? turnNumber,
    List<String>? messageEntryIds,
    List<String>? toolInvocationEntryIds,
    String? stopReason,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMs,
  }) {
    return TurnRecord(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      turnNumber: turnNumber ?? this.turnNumber,
      messageEntryIds: messageEntryIds ?? this.messageEntryIds,
      toolInvocationEntryIds:
          toolInvocationEntryIds ?? this.toolInvocationEntryIds,
      stopReason: stopReason ?? this.stopReason,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  TurnRecord copyWithTurnRecord({
    String? id,
    String? parentId,
    DateTime? timestamp,
    int? turnNumber,
    List<String>? messageEntryIds,
    List<String>? toolInvocationEntryIds,
    String? stopReason,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMs,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      turnNumber: turnNumber,
      messageEntryIds: messageEntryIds,
      toolInvocationEntryIds: toolInvocationEntryIds,
      stopReason: stopReason,
      startedAt: startedAt,
      endedAt: endedAt,
      durationMs: durationMs,
    );
  }

  TurnRecord patchWithTurnRecord([TurnRecordPatch? patchInput]) {
    final _patcher = patchInput ?? TurnRecordPatch();
    final _patchMap = _patcher.patchMap;
    return TurnRecord(
      id: _patchMap.containsKey(TurnRecord$.id)
          ? (_patchMap[TurnRecord$.id] is Function)
                ? _patchMap[TurnRecord$.id](this.id)
                : (_patchMap[TurnRecord$.id] is Patch)
                ? _patchMap[TurnRecord$.id].applyTo(this.id)
                : _patchMap[TurnRecord$.id]
          : this.id,
      parentId: _patchMap.containsKey(TurnRecord$.parentId)
          ? (_patchMap[TurnRecord$.parentId] is Function)
                ? _patchMap[TurnRecord$.parentId](this.parentId)
                : (_patchMap[TurnRecord$.parentId] is Patch)
                ? _patchMap[TurnRecord$.parentId].applyTo(this.parentId)
                : _patchMap[TurnRecord$.parentId]
          : this.parentId,
      timestamp: _patchMap.containsKey(TurnRecord$.timestamp)
          ? (_patchMap[TurnRecord$.timestamp] is Function)
                ? _patchMap[TurnRecord$.timestamp](this.timestamp)
                : (_patchMap[TurnRecord$.timestamp] is Patch)
                ? _patchMap[TurnRecord$.timestamp].applyTo(this.timestamp)
                : _patchMap[TurnRecord$.timestamp]
          : this.timestamp,
      turnNumber: _patchMap.containsKey(TurnRecord$.turnNumber)
          ? (_patchMap[TurnRecord$.turnNumber] is Function)
                ? _patchMap[TurnRecord$.turnNumber](this.turnNumber)
                : (_patchMap[TurnRecord$.turnNumber] is Patch)
                ? _patchMap[TurnRecord$.turnNumber].applyTo(this.turnNumber)
                : _patchMap[TurnRecord$.turnNumber]
          : this.turnNumber,
      messageEntryIds: _patchMap.containsKey(TurnRecord$.messageEntryIds)
          ? (_patchMap[TurnRecord$.messageEntryIds] is Function)
                ? _patchMap[TurnRecord$.messageEntryIds](this.messageEntryIds)
                : (_patchMap[TurnRecord$.messageEntryIds] is Patch)
                ? _patchMap[TurnRecord$.messageEntryIds].applyTo(
                    this.messageEntryIds,
                  )
                : _patchMap[TurnRecord$.messageEntryIds]
          : this.messageEntryIds,
      toolInvocationEntryIds:
          _patchMap.containsKey(TurnRecord$.toolInvocationEntryIds)
          ? (_patchMap[TurnRecord$.toolInvocationEntryIds] is Function)
                ? _patchMap[TurnRecord$.toolInvocationEntryIds](
                    this.toolInvocationEntryIds,
                  )
                : (_patchMap[TurnRecord$.toolInvocationEntryIds] is Patch)
                ? _patchMap[TurnRecord$.toolInvocationEntryIds].applyTo(
                    this.toolInvocationEntryIds,
                  )
                : _patchMap[TurnRecord$.toolInvocationEntryIds]
          : this.toolInvocationEntryIds,
      stopReason: _patchMap.containsKey(TurnRecord$.stopReason)
          ? (_patchMap[TurnRecord$.stopReason] is Function)
                ? _patchMap[TurnRecord$.stopReason](this.stopReason)
                : (_patchMap[TurnRecord$.stopReason] is Patch)
                ? _patchMap[TurnRecord$.stopReason].applyTo(this.stopReason)
                : _patchMap[TurnRecord$.stopReason]
          : this.stopReason,
      startedAt: _patchMap.containsKey(TurnRecord$.startedAt)
          ? (_patchMap[TurnRecord$.startedAt] is Function)
                ? _patchMap[TurnRecord$.startedAt](this.startedAt)
                : (_patchMap[TurnRecord$.startedAt] is Patch)
                ? _patchMap[TurnRecord$.startedAt].applyTo(this.startedAt)
                : _patchMap[TurnRecord$.startedAt]
          : this.startedAt,
      endedAt: _patchMap.containsKey(TurnRecord$.endedAt)
          ? (_patchMap[TurnRecord$.endedAt] is Function)
                ? _patchMap[TurnRecord$.endedAt](this.endedAt)
                : (_patchMap[TurnRecord$.endedAt] is Patch)
                ? _patchMap[TurnRecord$.endedAt].applyTo(this.endedAt)
                : _patchMap[TurnRecord$.endedAt]
          : this.endedAt,
      durationMs: _patchMap.containsKey(TurnRecord$.durationMs)
          ? (_patchMap[TurnRecord$.durationMs] is Function)
                ? _patchMap[TurnRecord$.durationMs](this.durationMs)
                : (_patchMap[TurnRecord$.durationMs] is Patch)
                ? _patchMap[TurnRecord$.durationMs].applyTo(this.durationMs)
                : _patchMap[TurnRecord$.durationMs]
          : this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TurnRecord &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        turnNumber == other.turnNumber &&
        messageEntryIds == other.messageEntryIds &&
        toolInvocationEntryIds == other.toolInvocationEntryIds &&
        stopReason == other.stopReason &&
        startedAt == other.startedAt &&
        endedAt == other.endedAt &&
        durationMs == other.durationMs;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.turnNumber,
      this.messageEntryIds,
      this.toolInvocationEntryIds,
      this.stopReason,
      this.startedAt,
      this.endedAt,
      this.durationMs,
    );
  }

  @override
  String toString() {
    return 'TurnRecord(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'turnNumber: ${turnNumber}' +
        ', ' +
        'messageEntryIds: ${messageEntryIds}' +
        ', ' +
        'toolInvocationEntryIds: ${toolInvocationEntryIds}' +
        ', ' +
        'stopReason: ${stopReason}' +
        ', ' +
        'startedAt: ${startedAt}' +
        ', ' +
        'endedAt: ${endedAt}' +
        ', ' +
        'durationMs: ${durationMs})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TurnRecordToJson(this);
    return _sanitizeJson(data);
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

extension TurnRecordPropertyHelpers on TurnRecord {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasParentId {
    return this.parentId?.isNotEmpty == true;
  }

  bool get noParentId {
    return this.parentId?.isEmpty ?? true;
  }

  String get parentIdRequired {
    return this.parentId ??
        (throw StateError('parentId is required but was null'));
  }

  bool get hasMessageEntryIds {
    return this.messageEntryIds.isNotEmpty;
  }

  bool get noMessageEntryIds {
    return this.messageEntryIds.isEmpty;
  }

  bool get hasToolInvocationEntryIds {
    return this.toolInvocationEntryIds.isNotEmpty;
  }

  bool get noToolInvocationEntryIds {
    return this.toolInvocationEntryIds.isEmpty;
  }

  bool get hasStopReason {
    return this.stopReason.isNotEmpty;
  }

  bool get noStopReason {
    return this.stopReason.isEmpty;
  }
}

extension TurnRecordSerialization on TurnRecord {
  Map<String, dynamic> toJson() {
    return _$TurnRecordToJson(this);
  }
}

enum TurnRecord$ {
  id,
  parentId,
  timestamp,
  turnNumber,
  messageEntryIds,
  toolInvocationEntryIds,
  stopReason,
  startedAt,
  endedAt,
  durationMs,
}

class TurnRecordPatch extends PatchBase<TurnRecord, TurnRecord$> {
  TurnRecord applyTo(TurnRecord entity) {
    return entity.patchWithTurnRecord(this);
  }

  TurnRecordPatch withId(String? value) {
    patchMap[TurnRecord$.id] = value;
    return this;
  }

  TurnRecordPatch withParentId(String? value) {
    patchMap[TurnRecord$.parentId] = value;
    return this;
  }

  TurnRecordPatch withTimestamp(DateTime? value) {
    patchMap[TurnRecord$.timestamp] = value;
    return this;
  }

  TurnRecordPatch withTurnNumber(int? value) {
    patchMap[TurnRecord$.turnNumber] = value;
    return this;
  }

  TurnRecordPatch withMessageEntryIds(List<String>? value) {
    patchMap[TurnRecord$.messageEntryIds] = value;
    return this;
  }

  TurnRecordPatch withToolInvocationEntryIds(List<String>? value) {
    patchMap[TurnRecord$.toolInvocationEntryIds] = value;
    return this;
  }

  TurnRecordPatch withStopReason(String? value) {
    patchMap[TurnRecord$.stopReason] = value;
    return this;
  }

  TurnRecordPatch withStartedAt(DateTime? value) {
    patchMap[TurnRecord$.startedAt] = value;
    return this;
  }

  TurnRecordPatch withEndedAt(DateTime? value) {
    patchMap[TurnRecord$.endedAt] = value;
    return this;
  }

  TurnRecordPatch withDurationMs(int? value) {
    patchMap[TurnRecord$.durationMs] = value;
    return this;
  }
}

/// Field descriptors for [TurnRecord] query construction
abstract final class TurnRecordFields {
  static const id = Field<TurnRecord, String>('id', _$id);

  static const parentId = Field<TurnRecord, String?>('parentId', _$parentId);

  static const timestamp = Field<TurnRecord, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const turnNumber = Field<TurnRecord, int>('turnNumber', _$turnNumber);

  static const messageEntryIds = Field<TurnRecord, List<String>>(
    'messageEntryIds',
    _$messageEntryIds,
  );

  static const toolInvocationEntryIds = Field<TurnRecord, List<String>>(
    'toolInvocationEntryIds',
    _$toolInvocationEntryIds,
  );

  static const stopReason = Field<TurnRecord, String>(
    'stopReason',
    _$stopReason,
  );

  static const startedAt = Field<TurnRecord, DateTime>(
    'startedAt',
    _$startedAt,
  );

  static const endedAt = Field<TurnRecord, DateTime>('endedAt', _$endedAt);

  static const durationMs = Field<TurnRecord, int>('durationMs', _$durationMs);

  static String _$id(TurnRecord e) {
    return e.id;
  }

  static String? _$parentId(TurnRecord e) {
    return e.parentId;
  }

  static DateTime _$timestamp(TurnRecord e) {
    return e.timestamp;
  }

  static int _$turnNumber(TurnRecord e) {
    return e.turnNumber;
  }

  static List<String> _$messageEntryIds(TurnRecord e) {
    return e.messageEntryIds;
  }

  static List<String> _$toolInvocationEntryIds(TurnRecord e) {
    return e.toolInvocationEntryIds;
  }

  static String _$stopReason(TurnRecord e) {
    return e.stopReason;
  }

  static DateTime _$startedAt(TurnRecord e) {
    return e.startedAt;
  }

  static DateTime _$endedAt(TurnRecord e) {
    return e.endedAt;
  }

  static int _$durationMs(TurnRecord e) {
    return e.durationMs;
  }
}

extension TurnRecordCompareE on TurnRecord {
  Map<String, dynamic> compareToTurnRecord(TurnRecord other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (parentId != other.parentId) {
      diff['parentId'] = () => other.parentId;
    }

    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }

    if (turnNumber != other.turnNumber) {
      diff['turnNumber'] = () => other.turnNumber;
    }

    if (messageEntryIds != other.messageEntryIds) {
      diff['messageEntryIds'] = () => other.messageEntryIds;
    }

    if (toolInvocationEntryIds != other.toolInvocationEntryIds) {
      diff['toolInvocationEntryIds'] = () => other.toolInvocationEntryIds;
    }

    if (stopReason != other.stopReason) {
      diff['stopReason'] = () => other.stopReason;
    }

    if (startedAt != other.startedAt) {
      diff['startedAt'] = () => other.startedAt;
    }

    if (endedAt != other.endedAt) {
      diff['endedAt'] = () => other.endedAt;
    }

    if (durationMs != other.durationMs) {
      diff['durationMs'] = () => other.durationMs;
    }
    return diff;
  }
}
