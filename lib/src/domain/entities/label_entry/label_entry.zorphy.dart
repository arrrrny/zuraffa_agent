// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'label_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class LabelEntry {
  LabelEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.label,
  });

  factory LabelEntry.fromJson(Map<String, dynamic> json) =>
      _$LabelEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String label;

  LabelEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? label,
  }) {
    return LabelEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
    );
  }

  LabelEntry copyWithLabelEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? label,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      label: label,
    );
  }

  LabelEntry patchWithLabelEntry([LabelEntryPatch? patchInput]) {
    final _patcher = patchInput ?? LabelEntryPatch();
    final _patchMap = _patcher.patchMap;
    return LabelEntry(
      id: _patchMap.containsKey(LabelEntry$.id)
          ? ((_patchMap[LabelEntry$.id] is Function)
                    ? _patchMap[LabelEntry$.id](this.id)
                    : (_patchMap[LabelEntry$.id] is Patch)
                    ? _patchMap[LabelEntry$.id].applyTo(this.id)
                    : _patchMap[LabelEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(LabelEntry$.parentId)
          ? ((_patchMap[LabelEntry$.parentId] is Function)
                    ? _patchMap[LabelEntry$.parentId](this.parentId)
                    : (_patchMap[LabelEntry$.parentId] is Patch)
                    ? _patchMap[LabelEntry$.parentId].applyTo(this.parentId)
                    : _patchMap[LabelEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(LabelEntry$.timestamp)
          ? ((_patchMap[LabelEntry$.timestamp] is Function)
                    ? _patchMap[LabelEntry$.timestamp](this.timestamp)
                    : (_patchMap[LabelEntry$.timestamp] is Patch)
                    ? _patchMap[LabelEntry$.timestamp].applyTo(this.timestamp)
                    : _patchMap[LabelEntry$.timestamp])
                as DateTime
          : this.timestamp,
      label: _patchMap.containsKey(LabelEntry$.label)
          ? ((_patchMap[LabelEntry$.label] is Function)
                    ? _patchMap[LabelEntry$.label](this.label)
                    : (_patchMap[LabelEntry$.label] is Patch)
                    ? _patchMap[LabelEntry$.label].applyTo(this.label)
                    : _patchMap[LabelEntry$.label])
                as String
          : this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        label == other.label;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.parentId, this.timestamp, this.label);
  }

  @override
  String toString() {
    return 'LabelEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'label: ${label})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$LabelEntryToJson(this);
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

extension LabelEntryPropertyHelpers on LabelEntry {
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

  bool get hasLabel {
    return this.label.isNotEmpty;
  }

  bool get noLabel {
    return this.label.isEmpty;
  }
}

extension LabelEntrySerialization on LabelEntry {
  Map<String, dynamic> toJson() {
    return _$LabelEntryToJson(this);
  }
}

enum LabelEntry$ { id, parentId, timestamp, label }

class LabelEntryPatch extends PatchBase<LabelEntry, LabelEntry$> {
  LabelEntry applyTo(LabelEntry entity) {
    return entity.patchWithLabelEntry(this);
  }

  LabelEntryPatch withId(String? value) {
    patchMap[LabelEntry$.id] = value;
    return this;
  }

  LabelEntryPatch withParentId(String? value) {
    patchMap[LabelEntry$.parentId] = value;
    return this;
  }

  LabelEntryPatch withTimestamp(DateTime? value) {
    patchMap[LabelEntry$.timestamp] = value;
    return this;
  }

  LabelEntryPatch withLabel(String? value) {
    patchMap[LabelEntry$.label] = value;
    return this;
  }
}

/// Field descriptors for [LabelEntry] query construction
abstract final class LabelEntryFields {
  static const id = Field<LabelEntry, String>('id', _$id);

  static const parentId = Field<LabelEntry, String?>('parentId', _$parentId);

  static const timestamp = Field<LabelEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const label = Field<LabelEntry, String>('label', _$label);

  static String _$id(LabelEntry e) {
    return e.id;
  }

  static String? _$parentId(LabelEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(LabelEntry e) {
    return e.timestamp;
  }

  static String _$label(LabelEntry e) {
    return e.label;
  }
}

extension LabelEntryCompareE on LabelEntry {
  Map<String, dynamic> compareToLabelEntry(LabelEntry other) {
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

    if (label != other.label) {
      diff['label'] = () => other.label;
    }
    return diff;
  }
}
