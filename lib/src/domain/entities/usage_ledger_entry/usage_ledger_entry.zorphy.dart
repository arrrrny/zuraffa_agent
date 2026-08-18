// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'usage_ledger_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class UsageLedgerEntry {
  UsageLedgerEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.callId,
    required int this.turnNumber,
    required int this.inputTokens,
    required int this.outputTokens,
    required int this.cacheReadTokens,
    required int this.cacheWriteTokens,
  });

  factory UsageLedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$UsageLedgerEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String callId;

  final int turnNumber;

  final int inputTokens;

  final int outputTokens;

  final int cacheReadTokens;

  final int cacheWriteTokens;

  UsageLedgerEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? callId,
    int? turnNumber,
    int? inputTokens,
    int? outputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) {
    return UsageLedgerEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      callId: callId ?? this.callId,
      turnNumber: turnNumber ?? this.turnNumber,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    );
  }

  UsageLedgerEntry copyWithUsageLedgerEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? callId,
    int? turnNumber,
    int? inputTokens,
    int? outputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      callId: callId,
      turnNumber: turnNumber,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cacheReadTokens: cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens,
    );
  }

  UsageLedgerEntry patchWithUsageLedgerEntry([
    UsageLedgerEntryPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? UsageLedgerEntryPatch();
    final _patchMap = _patcher.patchMap;
    return UsageLedgerEntry(
      id: _patchMap.containsKey(UsageLedgerEntry$.id)
          ? ((_patchMap[UsageLedgerEntry$.id] is Function)
                    ? _patchMap[UsageLedgerEntry$.id](this.id)
                    : (_patchMap[UsageLedgerEntry$.id] is Patch)
                    ? _patchMap[UsageLedgerEntry$.id].applyTo(this.id)
                    : _patchMap[UsageLedgerEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(UsageLedgerEntry$.parentId)
          ? ((_patchMap[UsageLedgerEntry$.parentId] is Function)
                    ? _patchMap[UsageLedgerEntry$.parentId](this.parentId)
                    : (_patchMap[UsageLedgerEntry$.parentId] is Patch)
                    ? _patchMap[UsageLedgerEntry$.parentId].applyTo(
                        this.parentId,
                      )
                    : _patchMap[UsageLedgerEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(UsageLedgerEntry$.timestamp)
          ? ((_patchMap[UsageLedgerEntry$.timestamp] is Function)
                    ? _patchMap[UsageLedgerEntry$.timestamp](this.timestamp)
                    : (_patchMap[UsageLedgerEntry$.timestamp] is Patch)
                    ? _patchMap[UsageLedgerEntry$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[UsageLedgerEntry$.timestamp])
                as DateTime
          : this.timestamp,
      callId: _patchMap.containsKey(UsageLedgerEntry$.callId)
          ? ((_patchMap[UsageLedgerEntry$.callId] is Function)
                    ? _patchMap[UsageLedgerEntry$.callId](this.callId)
                    : (_patchMap[UsageLedgerEntry$.callId] is Patch)
                    ? _patchMap[UsageLedgerEntry$.callId].applyTo(this.callId)
                    : _patchMap[UsageLedgerEntry$.callId])
                as String
          : this.callId,
      turnNumber: _patchMap.containsKey(UsageLedgerEntry$.turnNumber)
          ? ((_patchMap[UsageLedgerEntry$.turnNumber] is Function)
                    ? _patchMap[UsageLedgerEntry$.turnNumber](this.turnNumber)
                    : (_patchMap[UsageLedgerEntry$.turnNumber] is Patch)
                    ? _patchMap[UsageLedgerEntry$.turnNumber].applyTo(
                        this.turnNumber,
                      )
                    : _patchMap[UsageLedgerEntry$.turnNumber])
                as int
          : this.turnNumber,
      inputTokens: _patchMap.containsKey(UsageLedgerEntry$.inputTokens)
          ? ((_patchMap[UsageLedgerEntry$.inputTokens] is Function)
                    ? _patchMap[UsageLedgerEntry$.inputTokens](this.inputTokens)
                    : (_patchMap[UsageLedgerEntry$.inputTokens] is Patch)
                    ? _patchMap[UsageLedgerEntry$.inputTokens].applyTo(
                        this.inputTokens,
                      )
                    : _patchMap[UsageLedgerEntry$.inputTokens])
                as int
          : this.inputTokens,
      outputTokens: _patchMap.containsKey(UsageLedgerEntry$.outputTokens)
          ? ((_patchMap[UsageLedgerEntry$.outputTokens] is Function)
                    ? _patchMap[UsageLedgerEntry$.outputTokens](
                        this.outputTokens,
                      )
                    : (_patchMap[UsageLedgerEntry$.outputTokens] is Patch)
                    ? _patchMap[UsageLedgerEntry$.outputTokens].applyTo(
                        this.outputTokens,
                      )
                    : _patchMap[UsageLedgerEntry$.outputTokens])
                as int
          : this.outputTokens,
      cacheReadTokens: _patchMap.containsKey(UsageLedgerEntry$.cacheReadTokens)
          ? ((_patchMap[UsageLedgerEntry$.cacheReadTokens] is Function)
                    ? _patchMap[UsageLedgerEntry$.cacheReadTokens](
                        this.cacheReadTokens,
                      )
                    : (_patchMap[UsageLedgerEntry$.cacheReadTokens] is Patch)
                    ? _patchMap[UsageLedgerEntry$.cacheReadTokens].applyTo(
                        this.cacheReadTokens,
                      )
                    : _patchMap[UsageLedgerEntry$.cacheReadTokens])
                as int
          : this.cacheReadTokens,
      cacheWriteTokens:
          _patchMap.containsKey(UsageLedgerEntry$.cacheWriteTokens)
          ? ((_patchMap[UsageLedgerEntry$.cacheWriteTokens] is Function)
                    ? _patchMap[UsageLedgerEntry$.cacheWriteTokens](
                        this.cacheWriteTokens,
                      )
                    : (_patchMap[UsageLedgerEntry$.cacheWriteTokens] is Patch)
                    ? _patchMap[UsageLedgerEntry$.cacheWriteTokens].applyTo(
                        this.cacheWriteTokens,
                      )
                    : _patchMap[UsageLedgerEntry$.cacheWriteTokens])
                as int
          : this.cacheWriteTokens,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageLedgerEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        callId == other.callId &&
        turnNumber == other.turnNumber &&
        inputTokens == other.inputTokens &&
        outputTokens == other.outputTokens &&
        cacheReadTokens == other.cacheReadTokens &&
        cacheWriteTokens == other.cacheWriteTokens;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.callId,
      this.turnNumber,
      this.inputTokens,
      this.outputTokens,
      this.cacheReadTokens,
      this.cacheWriteTokens,
    );
  }

  @override
  String toString() {
    return 'UsageLedgerEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'callId: ${callId}' +
        ', ' +
        'turnNumber: ${turnNumber}' +
        ', ' +
        'inputTokens: ${inputTokens}' +
        ', ' +
        'outputTokens: ${outputTokens}' +
        ', ' +
        'cacheReadTokens: ${cacheReadTokens}' +
        ', ' +
        'cacheWriteTokens: ${cacheWriteTokens})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UsageLedgerEntryToJson(this);
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

extension UsageLedgerEntryPropertyHelpers on UsageLedgerEntry {
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

  bool get hasCallId {
    return this.callId.isNotEmpty;
  }

  bool get noCallId {
    return this.callId.isEmpty;
  }
}

extension UsageLedgerEntrySerialization on UsageLedgerEntry {
  Map<String, dynamic> toJson() {
    return _$UsageLedgerEntryToJson(this);
  }
}

enum UsageLedgerEntry$ {
  id,
  parentId,
  timestamp,
  callId,
  turnNumber,
  inputTokens,
  outputTokens,
  cacheReadTokens,
  cacheWriteTokens,
}

class UsageLedgerEntryPatch
    extends PatchBase<UsageLedgerEntry, UsageLedgerEntry$> {
  UsageLedgerEntry applyTo(UsageLedgerEntry entity) {
    return entity.patchWithUsageLedgerEntry(this);
  }

  UsageLedgerEntryPatch withId(String? value) {
    patchMap[UsageLedgerEntry$.id] = value;
    return this;
  }

  UsageLedgerEntryPatch withParentId(String? value) {
    patchMap[UsageLedgerEntry$.parentId] = value;
    return this;
  }

  UsageLedgerEntryPatch withTimestamp(DateTime? value) {
    patchMap[UsageLedgerEntry$.timestamp] = value;
    return this;
  }

  UsageLedgerEntryPatch withCallId(String? value) {
    patchMap[UsageLedgerEntry$.callId] = value;
    return this;
  }

  UsageLedgerEntryPatch withTurnNumber(int? value) {
    patchMap[UsageLedgerEntry$.turnNumber] = value;
    return this;
  }

  UsageLedgerEntryPatch withInputTokens(int? value) {
    patchMap[UsageLedgerEntry$.inputTokens] = value;
    return this;
  }

  UsageLedgerEntryPatch withOutputTokens(int? value) {
    patchMap[UsageLedgerEntry$.outputTokens] = value;
    return this;
  }

  UsageLedgerEntryPatch withCacheReadTokens(int? value) {
    patchMap[UsageLedgerEntry$.cacheReadTokens] = value;
    return this;
  }

  UsageLedgerEntryPatch withCacheWriteTokens(int? value) {
    patchMap[UsageLedgerEntry$.cacheWriteTokens] = value;
    return this;
  }
}

/// Field descriptors for [UsageLedgerEntry] query construction
abstract final class UsageLedgerEntryFields {
  static const id = Field<UsageLedgerEntry, String>('id', _$id);

  static const parentId = Field<UsageLedgerEntry, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<UsageLedgerEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const callId = Field<UsageLedgerEntry, String>('callId', _$callId);

  static const turnNumber = Field<UsageLedgerEntry, int>(
    'turnNumber',
    _$turnNumber,
  );

  static const inputTokens = Field<UsageLedgerEntry, int>(
    'inputTokens',
    _$inputTokens,
  );

  static const outputTokens = Field<UsageLedgerEntry, int>(
    'outputTokens',
    _$outputTokens,
  );

  static const cacheReadTokens = Field<UsageLedgerEntry, int>(
    'cacheReadTokens',
    _$cacheReadTokens,
  );

  static const cacheWriteTokens = Field<UsageLedgerEntry, int>(
    'cacheWriteTokens',
    _$cacheWriteTokens,
  );

  static String _$id(UsageLedgerEntry e) {
    return e.id;
  }

  static String? _$parentId(UsageLedgerEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(UsageLedgerEntry e) {
    return e.timestamp;
  }

  static String _$callId(UsageLedgerEntry e) {
    return e.callId;
  }

  static int _$turnNumber(UsageLedgerEntry e) {
    return e.turnNumber;
  }

  static int _$inputTokens(UsageLedgerEntry e) {
    return e.inputTokens;
  }

  static int _$outputTokens(UsageLedgerEntry e) {
    return e.outputTokens;
  }

  static int _$cacheReadTokens(UsageLedgerEntry e) {
    return e.cacheReadTokens;
  }

  static int _$cacheWriteTokens(UsageLedgerEntry e) {
    return e.cacheWriteTokens;
  }
}

extension UsageLedgerEntryCompareE on UsageLedgerEntry {
  Map<String, dynamic> compareToUsageLedgerEntry(UsageLedgerEntry other) {
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

    if (callId != other.callId) {
      diff['callId'] = () => other.callId;
    }

    if (turnNumber != other.turnNumber) {
      diff['turnNumber'] = () => other.turnNumber;
    }

    if (inputTokens != other.inputTokens) {
      diff['inputTokens'] = () => other.inputTokens;
    }

    if (outputTokens != other.outputTokens) {
      diff['outputTokens'] = () => other.outputTokens;
    }

    if (cacheReadTokens != other.cacheReadTokens) {
      diff['cacheReadTokens'] = () => other.cacheReadTokens;
    }

    if (cacheWriteTokens != other.cacheWriteTokens) {
      diff['cacheWriteTokens'] = () => other.cacheWriteTokens;
    }
    return diff;
  }
}
