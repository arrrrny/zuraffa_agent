// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'thinking_level_change_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ThinkingLevelChangeEntry {
  ThinkingLevelChangeEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.thinkingLevel,
  });

  factory ThinkingLevelChangeEntry.fromJson(Map<String, dynamic> json) =>
      _$ThinkingLevelChangeEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String thinkingLevel;

  ThinkingLevelChangeEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? thinkingLevel,
  }) {
    return ThinkingLevelChangeEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      thinkingLevel: thinkingLevel ?? this.thinkingLevel,
    );
  }

  ThinkingLevelChangeEntry copyWithThinkingLevelChangeEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? thinkingLevel,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      thinkingLevel: thinkingLevel,
    );
  }

  ThinkingLevelChangeEntry patchWithThinkingLevelChangeEntry([
    ThinkingLevelChangeEntryPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ThinkingLevelChangeEntryPatch();
    final _patchMap = _patcher.patchMap;
    return ThinkingLevelChangeEntry(
      id: _patchMap.containsKey(ThinkingLevelChangeEntry$.id)
          ? (_patchMap[ThinkingLevelChangeEntry$.id] is Function)
                ? _patchMap[ThinkingLevelChangeEntry$.id](this.id)
                : (_patchMap[ThinkingLevelChangeEntry$.id] is Patch)
                ? _patchMap[ThinkingLevelChangeEntry$.id].applyTo(this.id)
                : _patchMap[ThinkingLevelChangeEntry$.id]
          : this.id,
      parentId: _patchMap.containsKey(ThinkingLevelChangeEntry$.parentId)
          ? (_patchMap[ThinkingLevelChangeEntry$.parentId] is Function)
                ? _patchMap[ThinkingLevelChangeEntry$.parentId](this.parentId)
                : (_patchMap[ThinkingLevelChangeEntry$.parentId] is Patch)
                ? _patchMap[ThinkingLevelChangeEntry$.parentId].applyTo(
                    this.parentId,
                  )
                : _patchMap[ThinkingLevelChangeEntry$.parentId]
          : this.parentId,
      timestamp: _patchMap.containsKey(ThinkingLevelChangeEntry$.timestamp)
          ? (_patchMap[ThinkingLevelChangeEntry$.timestamp] is Function)
                ? _patchMap[ThinkingLevelChangeEntry$.timestamp](this.timestamp)
                : (_patchMap[ThinkingLevelChangeEntry$.timestamp] is Patch)
                ? _patchMap[ThinkingLevelChangeEntry$.timestamp].applyTo(
                    this.timestamp,
                  )
                : _patchMap[ThinkingLevelChangeEntry$.timestamp]
          : this.timestamp,
      thinkingLevel:
          _patchMap.containsKey(ThinkingLevelChangeEntry$.thinkingLevel)
          ? (_patchMap[ThinkingLevelChangeEntry$.thinkingLevel] is Function)
                ? _patchMap[ThinkingLevelChangeEntry$.thinkingLevel](
                    this.thinkingLevel,
                  )
                : (_patchMap[ThinkingLevelChangeEntry$.thinkingLevel] is Patch)
                ? _patchMap[ThinkingLevelChangeEntry$.thinkingLevel].applyTo(
                    this.thinkingLevel,
                  )
                : _patchMap[ThinkingLevelChangeEntry$.thinkingLevel]
          : this.thinkingLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThinkingLevelChangeEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        thinkingLevel == other.thinkingLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.thinkingLevel,
    );
  }

  @override
  String toString() {
    return 'ThinkingLevelChangeEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'thinkingLevel: ${thinkingLevel})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ThinkingLevelChangeEntryToJson(this);
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

extension ThinkingLevelChangeEntryPropertyHelpers on ThinkingLevelChangeEntry {
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

  bool get hasThinkingLevel {
    return this.thinkingLevel.isNotEmpty;
  }

  bool get noThinkingLevel {
    return this.thinkingLevel.isEmpty;
  }
}

extension ThinkingLevelChangeEntrySerialization on ThinkingLevelChangeEntry {
  Map<String, dynamic> toJson() {
    return _$ThinkingLevelChangeEntryToJson(this);
  }
}

enum ThinkingLevelChangeEntry$ { id, parentId, timestamp, thinkingLevel }

class ThinkingLevelChangeEntryPatch
    extends PatchBase<ThinkingLevelChangeEntry, ThinkingLevelChangeEntry$> {
  ThinkingLevelChangeEntry applyTo(ThinkingLevelChangeEntry entity) {
    return entity.patchWithThinkingLevelChangeEntry(this);
  }

  ThinkingLevelChangeEntryPatch withId(String? value) {
    patchMap[ThinkingLevelChangeEntry$.id] = value;
    return this;
  }

  ThinkingLevelChangeEntryPatch withParentId(String? value) {
    patchMap[ThinkingLevelChangeEntry$.parentId] = value;
    return this;
  }

  ThinkingLevelChangeEntryPatch withTimestamp(DateTime? value) {
    patchMap[ThinkingLevelChangeEntry$.timestamp] = value;
    return this;
  }

  ThinkingLevelChangeEntryPatch withThinkingLevel(String? value) {
    patchMap[ThinkingLevelChangeEntry$.thinkingLevel] = value;
    return this;
  }
}

/// Field descriptors for [ThinkingLevelChangeEntry] query construction
abstract final class ThinkingLevelChangeEntryFields {
  static const id = Field<ThinkingLevelChangeEntry, String>('id', _$id);

  static const parentId = Field<ThinkingLevelChangeEntry, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<ThinkingLevelChangeEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const thinkingLevel = Field<ThinkingLevelChangeEntry, String>(
    'thinkingLevel',
    _$thinkingLevel,
  );

  static String _$id(ThinkingLevelChangeEntry e) {
    return e.id;
  }

  static String? _$parentId(ThinkingLevelChangeEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(ThinkingLevelChangeEntry e) {
    return e.timestamp;
  }

  static String _$thinkingLevel(ThinkingLevelChangeEntry e) {
    return e.thinkingLevel;
  }
}

extension ThinkingLevelChangeEntryCompareE on ThinkingLevelChangeEntry {
  Map<String, dynamic> compareToThinkingLevelChangeEntry(
    ThinkingLevelChangeEntry other,
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

    if (thinkingLevel != other.thinkingLevel) {
      diff['thinkingLevel'] = () => other.thinkingLevel;
    }
    return diff;
  }
}
