// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'tool_invocation_record.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ToolInvocationRecord {
  ToolInvocationRecord({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.toolCallId,
    required String this.toolName,
    String? this.resultEntryId,
    required bool this.isError,
    required int this.durationMs,
  });

  factory ToolInvocationRecord.fromJson(Map<String, dynamic> json) =>
      _$ToolInvocationRecordFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String toolCallId;

  final String toolName;

  final String? resultEntryId;

  final bool isError;

  final int durationMs;

  ToolInvocationRecord copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? toolCallId,
    String? toolName,
    String? resultEntryId,
    bool? isError,
    int? durationMs,
  }) {
    return ToolInvocationRecord(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      resultEntryId: resultEntryId ?? this.resultEntryId,
      isError: isError ?? this.isError,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  ToolInvocationRecord copyWithToolInvocationRecord({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? toolCallId,
    String? toolName,
    String? resultEntryId,
    bool? isError,
    int? durationMs,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      toolCallId: toolCallId,
      toolName: toolName,
      resultEntryId: resultEntryId,
      isError: isError,
      durationMs: durationMs,
    );
  }

  ToolInvocationRecord patchWithToolInvocationRecord([
    ToolInvocationRecordPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ToolInvocationRecordPatch();
    final _patchMap = _patcher.patchMap;
    return ToolInvocationRecord(
      id: _patchMap.containsKey(ToolInvocationRecord$.id)
          ? ((_patchMap[ToolInvocationRecord$.id] is Function)
                    ? _patchMap[ToolInvocationRecord$.id](this.id)
                    : (_patchMap[ToolInvocationRecord$.id] is Patch)
                    ? _patchMap[ToolInvocationRecord$.id].applyTo(this.id)
                    : _patchMap[ToolInvocationRecord$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(ToolInvocationRecord$.parentId)
          ? ((_patchMap[ToolInvocationRecord$.parentId] is Function)
                    ? _patchMap[ToolInvocationRecord$.parentId](this.parentId)
                    : (_patchMap[ToolInvocationRecord$.parentId] is Patch)
                    ? _patchMap[ToolInvocationRecord$.parentId].applyTo(
                        this.parentId,
                      )
                    : _patchMap[ToolInvocationRecord$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(ToolInvocationRecord$.timestamp)
          ? ((_patchMap[ToolInvocationRecord$.timestamp] is Function)
                    ? _patchMap[ToolInvocationRecord$.timestamp](this.timestamp)
                    : (_patchMap[ToolInvocationRecord$.timestamp] is Patch)
                    ? _patchMap[ToolInvocationRecord$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ToolInvocationRecord$.timestamp])
                as DateTime
          : this.timestamp,
      toolCallId: _patchMap.containsKey(ToolInvocationRecord$.toolCallId)
          ? ((_patchMap[ToolInvocationRecord$.toolCallId] is Function)
                    ? _patchMap[ToolInvocationRecord$.toolCallId](
                        this.toolCallId,
                      )
                    : (_patchMap[ToolInvocationRecord$.toolCallId] is Patch)
                    ? _patchMap[ToolInvocationRecord$.toolCallId].applyTo(
                        this.toolCallId,
                      )
                    : _patchMap[ToolInvocationRecord$.toolCallId])
                as String
          : this.toolCallId,
      toolName: _patchMap.containsKey(ToolInvocationRecord$.toolName)
          ? ((_patchMap[ToolInvocationRecord$.toolName] is Function)
                    ? _patchMap[ToolInvocationRecord$.toolName](this.toolName)
                    : (_patchMap[ToolInvocationRecord$.toolName] is Patch)
                    ? _patchMap[ToolInvocationRecord$.toolName].applyTo(
                        this.toolName,
                      )
                    : _patchMap[ToolInvocationRecord$.toolName])
                as String
          : this.toolName,
      resultEntryId: _patchMap.containsKey(ToolInvocationRecord$.resultEntryId)
          ? ((_patchMap[ToolInvocationRecord$.resultEntryId] is Function)
                    ? _patchMap[ToolInvocationRecord$.resultEntryId](
                        this.resultEntryId,
                      )
                    : (_patchMap[ToolInvocationRecord$.resultEntryId] is Patch)
                    ? _patchMap[ToolInvocationRecord$.resultEntryId].applyTo(
                        this.resultEntryId,
                      )
                    : _patchMap[ToolInvocationRecord$.resultEntryId])
                as String?
          : this.resultEntryId,
      isError: _patchMap.containsKey(ToolInvocationRecord$.isError)
          ? ((_patchMap[ToolInvocationRecord$.isError] is Function)
                    ? _patchMap[ToolInvocationRecord$.isError](this.isError)
                    : (_patchMap[ToolInvocationRecord$.isError] is Patch)
                    ? _patchMap[ToolInvocationRecord$.isError].applyTo(
                        this.isError,
                      )
                    : _patchMap[ToolInvocationRecord$.isError])
                as bool
          : this.isError,
      durationMs: _patchMap.containsKey(ToolInvocationRecord$.durationMs)
          ? ((_patchMap[ToolInvocationRecord$.durationMs] is Function)
                    ? _patchMap[ToolInvocationRecord$.durationMs](
                        this.durationMs,
                      )
                    : (_patchMap[ToolInvocationRecord$.durationMs] is Patch)
                    ? _patchMap[ToolInvocationRecord$.durationMs].applyTo(
                        this.durationMs,
                      )
                    : _patchMap[ToolInvocationRecord$.durationMs])
                as int
          : this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolInvocationRecord &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        toolCallId == other.toolCallId &&
        toolName == other.toolName &&
        resultEntryId == other.resultEntryId &&
        isError == other.isError &&
        durationMs == other.durationMs;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.toolCallId,
      this.toolName,
      this.resultEntryId,
      this.isError,
      this.durationMs,
    );
  }

  @override
  String toString() {
    return 'ToolInvocationRecord(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'toolCallId: ${toolCallId}' +
        ', ' +
        'toolName: ${toolName}' +
        ', ' +
        'resultEntryId: ${resultEntryId}' +
        ', ' +
        'isError: ${isError}' +
        ', ' +
        'durationMs: ${durationMs})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolInvocationRecordToJson(this);
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

extension ToolInvocationRecordPropertyHelpers on ToolInvocationRecord {
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

  bool get hasResultEntryId {
    return this.resultEntryId?.isNotEmpty == true;
  }

  bool get noResultEntryId {
    return this.resultEntryId?.isEmpty ?? true;
  }

  String get resultEntryIdRequired {
    return this.resultEntryId ??
        (throw StateError('resultEntryId is required but was null'));
  }
}

extension ToolInvocationRecordSerialization on ToolInvocationRecord {
  Map<String, dynamic> toJson() {
    return _$ToolInvocationRecordToJson(this);
  }
}

enum ToolInvocationRecord$ {
  id,
  parentId,
  timestamp,
  toolCallId,
  toolName,
  resultEntryId,
  isError,
  durationMs,
}

class ToolInvocationRecordPatch
    extends PatchBase<ToolInvocationRecord, ToolInvocationRecord$> {
  ToolInvocationRecord applyTo(ToolInvocationRecord entity) {
    return entity.patchWithToolInvocationRecord(this);
  }

  ToolInvocationRecordPatch withId(String? value) {
    patchMap[ToolInvocationRecord$.id] = value;
    return this;
  }

  ToolInvocationRecordPatch withParentId(String? value) {
    patchMap[ToolInvocationRecord$.parentId] = value;
    return this;
  }

  ToolInvocationRecordPatch withTimestamp(DateTime? value) {
    patchMap[ToolInvocationRecord$.timestamp] = value;
    return this;
  }

  ToolInvocationRecordPatch withToolCallId(String? value) {
    patchMap[ToolInvocationRecord$.toolCallId] = value;
    return this;
  }

  ToolInvocationRecordPatch withToolName(String? value) {
    patchMap[ToolInvocationRecord$.toolName] = value;
    return this;
  }

  ToolInvocationRecordPatch withResultEntryId(String? value) {
    patchMap[ToolInvocationRecord$.resultEntryId] = value;
    return this;
  }

  ToolInvocationRecordPatch withIsError(bool? value) {
    patchMap[ToolInvocationRecord$.isError] = value;
    return this;
  }

  ToolInvocationRecordPatch withDurationMs(int? value) {
    patchMap[ToolInvocationRecord$.durationMs] = value;
    return this;
  }
}

/// Field descriptors for [ToolInvocationRecord] query construction
abstract final class ToolInvocationRecordFields {
  static const id = Field<ToolInvocationRecord, String>('id', _$id);

  static const parentId = Field<ToolInvocationRecord, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<ToolInvocationRecord, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const toolCallId = Field<ToolInvocationRecord, String>(
    'toolCallId',
    _$toolCallId,
  );

  static const toolName = Field<ToolInvocationRecord, String>(
    'toolName',
    _$toolName,
  );

  static const resultEntryId = Field<ToolInvocationRecord, String?>(
    'resultEntryId',
    _$resultEntryId,
  );

  static const isError = Field<ToolInvocationRecord, bool>(
    'isError',
    _$isError,
  );

  static const durationMs = Field<ToolInvocationRecord, int>(
    'durationMs',
    _$durationMs,
  );

  static String _$id(ToolInvocationRecord e) {
    return e.id;
  }

  static String? _$parentId(ToolInvocationRecord e) {
    return e.parentId;
  }

  static DateTime _$timestamp(ToolInvocationRecord e) {
    return e.timestamp;
  }

  static String _$toolCallId(ToolInvocationRecord e) {
    return e.toolCallId;
  }

  static String _$toolName(ToolInvocationRecord e) {
    return e.toolName;
  }

  static String? _$resultEntryId(ToolInvocationRecord e) {
    return e.resultEntryId;
  }

  static bool _$isError(ToolInvocationRecord e) {
    return e.isError;
  }

  static int _$durationMs(ToolInvocationRecord e) {
    return e.durationMs;
  }
}

extension ToolInvocationRecordCompareE on ToolInvocationRecord {
  Map<String, dynamic> compareToToolInvocationRecord(
    ToolInvocationRecord other,
  ) {
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

    if (toolCallId != other.toolCallId) {
      diff['toolCallId'] = () => other.toolCallId;
    }

    if (toolName != other.toolName) {
      diff['toolName'] = () => other.toolName;
    }

    if (resultEntryId != other.resultEntryId) {
      diff['resultEntryId'] = () => other.resultEntryId;
    }

    if (isError != other.isError) {
      diff['isError'] = () => other.isError;
    }

    if (durationMs != other.durationMs) {
      diff['durationMs'] = () => other.durationMs;
    }
    return diff;
  }
}
