// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'custom_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class CustomEntry {
  CustomEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.customType,
    required String this.payload,
  });

  factory CustomEntry.fromJson(Map<String, dynamic> json) =>
      _$CustomEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String customType;

  final String payload;

  CustomEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? customType,
    String? payload,
  }) {
    return CustomEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      customType: customType ?? this.customType,
      payload: payload ?? this.payload,
    );
  }

  CustomEntry copyWithCustomEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? customType,
    String? payload,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      customType: customType,
      payload: payload,
    );
  }

  CustomEntry patchWithCustomEntry([CustomEntryPatch? patchInput]) {
    final _patcher = patchInput ?? CustomEntryPatch();
    final _patchMap = _patcher.patchMap;
    return CustomEntry(
      id: _patchMap.containsKey(CustomEntry$.id)
          ? ((_patchMap[CustomEntry$.id] is Function)
                    ? _patchMap[CustomEntry$.id](this.id)
                    : (_patchMap[CustomEntry$.id] is Patch)
                    ? _patchMap[CustomEntry$.id].applyTo(this.id)
                    : _patchMap[CustomEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(CustomEntry$.parentId)
          ? ((_patchMap[CustomEntry$.parentId] is Function)
                    ? _patchMap[CustomEntry$.parentId](this.parentId)
                    : (_patchMap[CustomEntry$.parentId] is Patch)
                    ? _patchMap[CustomEntry$.parentId].applyTo(this.parentId)
                    : _patchMap[CustomEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(CustomEntry$.timestamp)
          ? ((_patchMap[CustomEntry$.timestamp] is Function)
                    ? _patchMap[CustomEntry$.timestamp](this.timestamp)
                    : (_patchMap[CustomEntry$.timestamp] is Patch)
                    ? _patchMap[CustomEntry$.timestamp].applyTo(this.timestamp)
                    : _patchMap[CustomEntry$.timestamp])
                as DateTime
          : this.timestamp,
      customType: _patchMap.containsKey(CustomEntry$.customType)
          ? ((_patchMap[CustomEntry$.customType] is Function)
                    ? _patchMap[CustomEntry$.customType](this.customType)
                    : (_patchMap[CustomEntry$.customType] is Patch)
                    ? _patchMap[CustomEntry$.customType].applyTo(
                        this.customType,
                      )
                    : _patchMap[CustomEntry$.customType])
                as String
          : this.customType,
      payload: _patchMap.containsKey(CustomEntry$.payload)
          ? ((_patchMap[CustomEntry$.payload] is Function)
                    ? _patchMap[CustomEntry$.payload](this.payload)
                    : (_patchMap[CustomEntry$.payload] is Patch)
                    ? _patchMap[CustomEntry$.payload].applyTo(this.payload)
                    : _patchMap[CustomEntry$.payload])
                as String
          : this.payload,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        customType == other.customType &&
        payload == other.payload;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.customType,
      this.payload,
    );
  }

  @override
  String toString() {
    return 'CustomEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'customType: ${customType}' +
        ', ' +
        'payload: ${payload})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CustomEntryToJson(this);
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

extension CustomEntryPropertyHelpers on CustomEntry {
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

  bool get hasCustomType {
    return this.customType.isNotEmpty;
  }

  bool get noCustomType {
    return this.customType.isEmpty;
  }

  bool get hasPayload {
    return this.payload.isNotEmpty;
  }

  bool get noPayload {
    return this.payload.isEmpty;
  }
}

extension CustomEntrySerialization on CustomEntry {
  Map<String, dynamic> toJson() {
    return _$CustomEntryToJson(this);
  }
}

enum CustomEntry$ { id, parentId, timestamp, customType, payload }

class CustomEntryPatch extends PatchBase<CustomEntry, CustomEntry$> {
  CustomEntry applyTo(CustomEntry entity) {
    return entity.patchWithCustomEntry(this);
  }

  CustomEntryPatch withId(String? value) {
    patchMap[CustomEntry$.id] = value;
    return this;
  }

  CustomEntryPatch withParentId(String? value) {
    patchMap[CustomEntry$.parentId] = value;
    return this;
  }

  CustomEntryPatch withTimestamp(DateTime? value) {
    patchMap[CustomEntry$.timestamp] = value;
    return this;
  }

  CustomEntryPatch withCustomType(String? value) {
    patchMap[CustomEntry$.customType] = value;
    return this;
  }

  CustomEntryPatch withPayload(String? value) {
    patchMap[CustomEntry$.payload] = value;
    return this;
  }
}

/// Field descriptors for [CustomEntry] query construction
abstract final class CustomEntryFields {
  static const id = Field<CustomEntry, String>('id', _$id);

  static const parentId = Field<CustomEntry, String?>('parentId', _$parentId);

  static const timestamp = Field<CustomEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const customType = Field<CustomEntry, String>(
    'customType',
    _$customType,
  );

  static const payload = Field<CustomEntry, String>('payload', _$payload);

  static String _$id(CustomEntry e) {
    return e.id;
  }

  static String? _$parentId(CustomEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(CustomEntry e) {
    return e.timestamp;
  }

  static String _$customType(CustomEntry e) {
    return e.customType;
  }

  static String _$payload(CustomEntry e) {
    return e.payload;
  }
}

extension CustomEntryCompareE on CustomEntry {
  Map<String, dynamic> compareToCustomEntry(CustomEntry other) {
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

    if (customType != other.customType) {
      diff['customType'] = () => other.customType;
    }

    if (payload != other.payload) {
      diff['payload'] = () => other.payload;
    }
    return diff;
  }
}
