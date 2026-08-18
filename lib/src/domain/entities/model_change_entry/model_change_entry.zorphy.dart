// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'model_change_entry.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ModelChangeEntry {
  ModelChangeEntry({
    required String this.id,
    String? this.parentId,
    required DateTime this.timestamp,
    required String this.modelId,
    required String this.provider,
  });

  factory ModelChangeEntry.fromJson(Map<String, dynamic> json) =>
      _$ModelChangeEntryFromJson(json);

  final String id;

  final String? parentId;

  final DateTime timestamp;

  final String modelId;

  final String provider;

  ModelChangeEntry copyWith({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? modelId,
    String? provider,
  }) {
    return ModelChangeEntry(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      timestamp: timestamp ?? this.timestamp,
      modelId: modelId ?? this.modelId,
      provider: provider ?? this.provider,
    );
  }

  ModelChangeEntry copyWithModelChangeEntry({
    String? id,
    String? parentId,
    DateTime? timestamp,
    String? modelId,
    String? provider,
  }) {
    return copyWith(
      id: id,
      parentId: parentId,
      timestamp: timestamp,
      modelId: modelId,
      provider: provider,
    );
  }

  ModelChangeEntry patchWithModelChangeEntry([
    ModelChangeEntryPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ModelChangeEntryPatch();
    final _patchMap = _patcher.patchMap;
    return ModelChangeEntry(
      id: _patchMap.containsKey(ModelChangeEntry$.id)
          ? ((_patchMap[ModelChangeEntry$.id] is Function)
                    ? _patchMap[ModelChangeEntry$.id](this.id)
                    : (_patchMap[ModelChangeEntry$.id] is Patch)
                    ? _patchMap[ModelChangeEntry$.id].applyTo(this.id)
                    : _patchMap[ModelChangeEntry$.id])
                as String
          : this.id,
      parentId: _patchMap.containsKey(ModelChangeEntry$.parentId)
          ? ((_patchMap[ModelChangeEntry$.parentId] is Function)
                    ? _patchMap[ModelChangeEntry$.parentId](this.parentId)
                    : (_patchMap[ModelChangeEntry$.parentId] is Patch)
                    ? _patchMap[ModelChangeEntry$.parentId].applyTo(
                        this.parentId,
                      )
                    : _patchMap[ModelChangeEntry$.parentId])
                as String?
          : this.parentId,
      timestamp: _patchMap.containsKey(ModelChangeEntry$.timestamp)
          ? ((_patchMap[ModelChangeEntry$.timestamp] is Function)
                    ? _patchMap[ModelChangeEntry$.timestamp](this.timestamp)
                    : (_patchMap[ModelChangeEntry$.timestamp] is Patch)
                    ? _patchMap[ModelChangeEntry$.timestamp].applyTo(
                        this.timestamp,
                      )
                    : _patchMap[ModelChangeEntry$.timestamp])
                as DateTime
          : this.timestamp,
      modelId: _patchMap.containsKey(ModelChangeEntry$.modelId)
          ? ((_patchMap[ModelChangeEntry$.modelId] is Function)
                    ? _patchMap[ModelChangeEntry$.modelId](this.modelId)
                    : (_patchMap[ModelChangeEntry$.modelId] is Patch)
                    ? _patchMap[ModelChangeEntry$.modelId].applyTo(this.modelId)
                    : _patchMap[ModelChangeEntry$.modelId])
                as String
          : this.modelId,
      provider: _patchMap.containsKey(ModelChangeEntry$.provider)
          ? ((_patchMap[ModelChangeEntry$.provider] is Function)
                    ? _patchMap[ModelChangeEntry$.provider](this.provider)
                    : (_patchMap[ModelChangeEntry$.provider] is Patch)
                    ? _patchMap[ModelChangeEntry$.provider].applyTo(
                        this.provider,
                      )
                    : _patchMap[ModelChangeEntry$.provider])
                as String
          : this.provider,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelChangeEntry &&
        id == other.id &&
        parentId == other.parentId &&
        timestamp == other.timestamp &&
        modelId == other.modelId &&
        provider == other.provider;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.parentId,
      this.timestamp,
      this.modelId,
      this.provider,
    );
  }

  @override
  String toString() {
    return 'ModelChangeEntry(' +
        'id: ${id}' +
        ', ' +
        'parentId: ${parentId}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'modelId: ${modelId}' +
        ', ' +
        'provider: ${provider})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ModelChangeEntryToJson(this);
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

extension ModelChangeEntryPropertyHelpers on ModelChangeEntry {
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

  bool get hasModelId {
    return this.modelId.isNotEmpty;
  }

  bool get noModelId {
    return this.modelId.isEmpty;
  }

  bool get hasProvider {
    return this.provider.isNotEmpty;
  }

  bool get noProvider {
    return this.provider.isEmpty;
  }
}

extension ModelChangeEntrySerialization on ModelChangeEntry {
  Map<String, dynamic> toJson() {
    return _$ModelChangeEntryToJson(this);
  }
}

enum ModelChangeEntry$ { id, parentId, timestamp, modelId, provider }

class ModelChangeEntryPatch
    extends PatchBase<ModelChangeEntry, ModelChangeEntry$> {
  ModelChangeEntry applyTo(ModelChangeEntry entity) {
    return entity.patchWithModelChangeEntry(this);
  }

  ModelChangeEntryPatch withId(String? value) {
    patchMap[ModelChangeEntry$.id] = value;
    return this;
  }

  ModelChangeEntryPatch withParentId(String? value) {
    patchMap[ModelChangeEntry$.parentId] = value;
    return this;
  }

  ModelChangeEntryPatch withTimestamp(DateTime? value) {
    patchMap[ModelChangeEntry$.timestamp] = value;
    return this;
  }

  ModelChangeEntryPatch withModelId(String? value) {
    patchMap[ModelChangeEntry$.modelId] = value;
    return this;
  }

  ModelChangeEntryPatch withProvider(String? value) {
    patchMap[ModelChangeEntry$.provider] = value;
    return this;
  }
}

/// Field descriptors for [ModelChangeEntry] query construction
abstract final class ModelChangeEntryFields {
  static const id = Field<ModelChangeEntry, String>('id', _$id);

  static const parentId = Field<ModelChangeEntry, String?>(
    'parentId',
    _$parentId,
  );

  static const timestamp = Field<ModelChangeEntry, DateTime>(
    'timestamp',
    _$timestamp,
  );

  static const modelId = Field<ModelChangeEntry, String>('modelId', _$modelId);

  static const provider = Field<ModelChangeEntry, String>(
    'provider',
    _$provider,
  );

  static String _$id(ModelChangeEntry e) {
    return e.id;
  }

  static String? _$parentId(ModelChangeEntry e) {
    return e.parentId;
  }

  static DateTime _$timestamp(ModelChangeEntry e) {
    return e.timestamp;
  }

  static String _$modelId(ModelChangeEntry e) {
    return e.modelId;
  }

  static String _$provider(ModelChangeEntry e) {
    return e.provider;
  }
}

extension ModelChangeEntryCompareE on ModelChangeEntry {
  Map<String, dynamic> compareToModelChangeEntry(ModelChangeEntry other) {
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

    if (modelId != other.modelId) {
      diff['modelId'] = () => other.modelId;
    }

    if (provider != other.provider) {
      diff['provider'] = () => other.provider;
    }
    return diff;
  }
}
