// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'artifact_ref.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ArtifactRef {
  ArtifactRef({
    required String this.id,
    required String this.mimeType,
    required int this.sizeBytes,
    required DateTime this.createdAt,
  });

  factory ArtifactRef.fromJson(Map<String, dynamic> json) =>
      _$ArtifactRefFromJson(json);

  final String id;

  final String mimeType;

  final int sizeBytes;

  final DateTime createdAt;

  ArtifactRef copyWith({
    String? id,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return ArtifactRef(
      id: id ?? this.id,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  ArtifactRef copyWithArtifactRef({
    String? id,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return copyWith(
      id: id,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
    );
  }

  ArtifactRef patchWithArtifactRef([ArtifactRefPatch? patchInput]) {
    final _patcher = patchInput ?? ArtifactRefPatch();
    final _patchMap = _patcher.patchMap;
    return ArtifactRef(
      id: _patchMap.containsKey(ArtifactRef$.id)
          ? ((_patchMap[ArtifactRef$.id] is Function)
                    ? _patchMap[ArtifactRef$.id](this.id)
                    : (_patchMap[ArtifactRef$.id] is Patch)
                    ? _patchMap[ArtifactRef$.id].applyTo(this.id)
                    : _patchMap[ArtifactRef$.id])
                as String
          : this.id,
      mimeType: _patchMap.containsKey(ArtifactRef$.mimeType)
          ? ((_patchMap[ArtifactRef$.mimeType] is Function)
                    ? _patchMap[ArtifactRef$.mimeType](this.mimeType)
                    : (_patchMap[ArtifactRef$.mimeType] is Patch)
                    ? _patchMap[ArtifactRef$.mimeType].applyTo(this.mimeType)
                    : _patchMap[ArtifactRef$.mimeType])
                as String
          : this.mimeType,
      sizeBytes: _patchMap.containsKey(ArtifactRef$.sizeBytes)
          ? ((_patchMap[ArtifactRef$.sizeBytes] is Function)
                    ? _patchMap[ArtifactRef$.sizeBytes](this.sizeBytes)
                    : (_patchMap[ArtifactRef$.sizeBytes] is Patch)
                    ? _patchMap[ArtifactRef$.sizeBytes].applyTo(this.sizeBytes)
                    : _patchMap[ArtifactRef$.sizeBytes])
                as int
          : this.sizeBytes,
      createdAt: _patchMap.containsKey(ArtifactRef$.createdAt)
          ? ((_patchMap[ArtifactRef$.createdAt] is Function)
                    ? _patchMap[ArtifactRef$.createdAt](this.createdAt)
                    : (_patchMap[ArtifactRef$.createdAt] is Patch)
                    ? _patchMap[ArtifactRef$.createdAt].applyTo(this.createdAt)
                    : _patchMap[ArtifactRef$.createdAt])
                as DateTime
          : this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtifactRef &&
        id == other.id &&
        mimeType == other.mimeType &&
        sizeBytes == other.sizeBytes &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.mimeType, this.sizeBytes, this.createdAt);
  }

  @override
  String toString() {
    return 'ArtifactRef(' +
        'id: ${id}' +
        ', ' +
        'mimeType: ${mimeType}' +
        ', ' +
        'sizeBytes: ${sizeBytes}' +
        ', ' +
        'createdAt: ${createdAt})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ArtifactRefToJson(this);
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

extension ArtifactRefPropertyHelpers on ArtifactRef {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasMimeType {
    return this.mimeType.isNotEmpty;
  }

  bool get noMimeType {
    return this.mimeType.isEmpty;
  }
}

extension ArtifactRefSerialization on ArtifactRef {
  Map<String, dynamic> toJson() {
    return _$ArtifactRefToJson(this);
  }
}

enum ArtifactRef$ { id, mimeType, sizeBytes, createdAt }

class ArtifactRefPatch extends PatchBase<ArtifactRef, ArtifactRef$> {
  ArtifactRef applyTo(ArtifactRef entity) {
    return entity.patchWithArtifactRef(this);
  }

  ArtifactRefPatch withId(String? value) {
    patchMap[ArtifactRef$.id] = value;
    return this;
  }

  ArtifactRefPatch withMimeType(String? value) {
    patchMap[ArtifactRef$.mimeType] = value;
    return this;
  }

  ArtifactRefPatch withSizeBytes(int? value) {
    patchMap[ArtifactRef$.sizeBytes] = value;
    return this;
  }

  ArtifactRefPatch withCreatedAt(DateTime? value) {
    patchMap[ArtifactRef$.createdAt] = value;
    return this;
  }
}

/// Field descriptors for [ArtifactRef] query construction
abstract final class ArtifactRefFields {
  static const id = Field<ArtifactRef, String>('id', _$id);

  static const mimeType = Field<ArtifactRef, String>('mimeType', _$mimeType);

  static const sizeBytes = Field<ArtifactRef, int>('sizeBytes', _$sizeBytes);

  static const createdAt = Field<ArtifactRef, DateTime>(
    'createdAt',
    _$createdAt,
  );

  static String _$id(ArtifactRef e) {
    return e.id;
  }

  static String _$mimeType(ArtifactRef e) {
    return e.mimeType;
  }

  static int _$sizeBytes(ArtifactRef e) {
    return e.sizeBytes;
  }

  static DateTime _$createdAt(ArtifactRef e) {
    return e.createdAt;
  }
}

extension ArtifactRefCompareE on ArtifactRef {
  Map<String, dynamic> compareToArtifactRef(ArtifactRef other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (mimeType != other.mimeType) {
      diff['mimeType'] = () => other.mimeType;
    }

    if (sizeBytes != other.sizeBytes) {
      diff['sizeBytes'] = () => other.sizeBytes;
    }

    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    return diff;
  }
}
