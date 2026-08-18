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
    required String this.kind,
    required String this.id,
    String? this.uri,
  });

  factory ArtifactRef.fromJson(Map<String, dynamic> json) =>
      _$ArtifactRefFromJson(json);

  final String kind;

  final String id;

  final String? uri;

  ArtifactRef copyWith({String? kind, String? id, String? uri}) {
    return ArtifactRef(
      kind: kind ?? this.kind,
      id: id ?? this.id,
      uri: uri ?? this.uri,
    );
  }

  ArtifactRef copyWithArtifactRef({String? kind, String? id, String? uri}) {
    return copyWith(kind: kind, id: id, uri: uri);
  }

  ArtifactRef patchWithArtifactRef([ArtifactRefPatch? patchInput]) {
    final _patcher = patchInput ?? ArtifactRefPatch();
    final _patchMap = _patcher.patchMap;
    return ArtifactRef(
      kind: _patchMap.containsKey(ArtifactRef$.kind)
          ? ((_patchMap[ArtifactRef$.kind] is Function)
                    ? _patchMap[ArtifactRef$.kind](this.kind)
                    : (_patchMap[ArtifactRef$.kind] is Patch)
                    ? _patchMap[ArtifactRef$.kind].applyTo(this.kind)
                    : _patchMap[ArtifactRef$.kind])
                as String
          : this.kind,
      id: _patchMap.containsKey(ArtifactRef$.id)
          ? ((_patchMap[ArtifactRef$.id] is Function)
                    ? _patchMap[ArtifactRef$.id](this.id)
                    : (_patchMap[ArtifactRef$.id] is Patch)
                    ? _patchMap[ArtifactRef$.id].applyTo(this.id)
                    : _patchMap[ArtifactRef$.id])
                as String
          : this.id,
      uri: _patchMap.containsKey(ArtifactRef$.uri)
          ? ((_patchMap[ArtifactRef$.uri] is Function)
                    ? _patchMap[ArtifactRef$.uri](this.uri)
                    : (_patchMap[ArtifactRef$.uri] is Patch)
                    ? _patchMap[ArtifactRef$.uri].applyTo(this.uri)
                    : _patchMap[ArtifactRef$.uri])
                as String?
          : this.uri,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtifactRef &&
        kind == other.kind &&
        id == other.id &&
        uri == other.uri;
  }

  @override
  int get hashCode {
    return Object.hash(this.kind, this.id, this.uri);
  }

  @override
  String toString() {
    return 'ArtifactRef(' +
        'kind: ${kind}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'uri: ${uri})';
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
  bool get hasKind {
    return this.kind.isNotEmpty;
  }

  bool get noKind {
    return this.kind.isEmpty;
  }

  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasUri {
    return this.uri?.isNotEmpty == true;
  }

  bool get noUri {
    return this.uri?.isEmpty ?? true;
  }

  String get uriRequired {
    return this.uri ?? (throw StateError('uri is required but was null'));
  }
}

extension ArtifactRefSerialization on ArtifactRef {
  Map<String, dynamic> toJson() {
    return _$ArtifactRefToJson(this);
  }
}

enum ArtifactRef$ { kind, id, uri }

class ArtifactRefPatch extends PatchBase<ArtifactRef, ArtifactRef$> {
  ArtifactRef applyTo(ArtifactRef entity) {
    return entity.patchWithArtifactRef(this);
  }

  ArtifactRefPatch withKind(String? value) {
    patchMap[ArtifactRef$.kind] = value;
    return this;
  }

  ArtifactRefPatch withId(String? value) {
    patchMap[ArtifactRef$.id] = value;
    return this;
  }

  ArtifactRefPatch withUri(String? value) {
    patchMap[ArtifactRef$.uri] = value;
    return this;
  }
}

/// Field descriptors for [ArtifactRef] query construction
abstract final class ArtifactRefFields {
  static const kind = Field<ArtifactRef, String>('kind', _$kind);

  static const id = Field<ArtifactRef, String>('id', _$id);

  static const uri = Field<ArtifactRef, String?>('uri', _$uri);

  static String _$kind(ArtifactRef e) {
    return e.kind;
  }

  static String _$id(ArtifactRef e) {
    return e.id;
  }

  static String? _$uri(ArtifactRef e) {
    return e.uri;
  }
}

extension ArtifactRefCompareE on ArtifactRef {
  Map<String, dynamic> compareToArtifactRef(ArtifactRef other) {
    final Map<String, dynamic> diff = {};

    if (kind != other.kind) {
      diff['kind'] = () => other.kind;
    }

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (uri != other.uri) {
      diff['uri'] = () => other.uri;
    }
    return diff;
  }
}
