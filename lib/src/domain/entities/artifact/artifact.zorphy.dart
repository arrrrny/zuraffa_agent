// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'artifact.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Artifact {
  Artifact({required String this.refId, required List<int> this.data});

  factory Artifact.fromJson(Map<String, dynamic> json) =>
      _$ArtifactFromJson(json);

  final String refId;

  final List<int> data;

  Artifact copyWith({String? refId, List<int>? data}) {
    return Artifact(refId: refId ?? this.refId, data: data ?? this.data);
  }

  Artifact copyWithArtifact({String? refId, List<int>? data}) {
    return copyWith(refId: refId, data: data);
  }

  Artifact patchWithArtifact([ArtifactPatch? patchInput]) {
    final _patcher = patchInput ?? ArtifactPatch();
    final _patchMap = _patcher.patchMap;
    return Artifact(
      refId: _patchMap.containsKey(Artifact$.refId)
          ? ((_patchMap[Artifact$.refId] is Function)
                    ? _patchMap[Artifact$.refId](this.refId)
                    : (_patchMap[Artifact$.refId] is Patch)
                    ? _patchMap[Artifact$.refId].applyTo(this.refId)
                    : _patchMap[Artifact$.refId])
                as String
          : this.refId,
      data: _patchMap.containsKey(Artifact$.data)
          ? ((_patchMap[Artifact$.data] is Function)
                    ? _patchMap[Artifact$.data](this.data)
                    : (_patchMap[Artifact$.data] is Patch)
                    ? _patchMap[Artifact$.data].applyTo(this.data)
                    : _patchMap[Artifact$.data])
                as List<int>
          : this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artifact && refId == other.refId && data == other.data;
  }

  @override
  int get hashCode {
    return Object.hash(this.refId, this.data);
  }

  @override
  String toString() {
    return 'Artifact(' + 'refId: ${refId}' + ', ' + 'data: ${data})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ArtifactToJson(this);
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

extension ArtifactPropertyHelpers on Artifact {
  bool get hasRefId {
    return this.refId.isNotEmpty;
  }

  bool get noRefId {
    return this.refId.isEmpty;
  }

  bool get hasData {
    return this.data.isNotEmpty;
  }

  bool get noData {
    return this.data.isEmpty;
  }
}

extension ArtifactSerialization on Artifact {
  Map<String, dynamic> toJson() {
    return _$ArtifactToJson(this);
  }
}

enum Artifact$ { refId, data }

class ArtifactPatch extends PatchBase<Artifact, Artifact$> {
  Artifact applyTo(Artifact entity) {
    return entity.patchWithArtifact(this);
  }

  ArtifactPatch withRefId(String? value) {
    patchMap[Artifact$.refId] = value;
    return this;
  }

  ArtifactPatch withData(List<int>? value) {
    patchMap[Artifact$.data] = value;
    return this;
  }
}

/// Field descriptors for [Artifact] query construction
abstract final class ArtifactFields {
  static const refId = Field<Artifact, String>('refId', _$refId);

  static const data = Field<Artifact, List<int>>('data', _$data);

  static String _$refId(Artifact e) {
    return e.refId;
  }

  static List<int> _$data(Artifact e) {
    return e.data;
  }
}

extension ArtifactCompareE on Artifact {
  Map<String, dynamic> compareToArtifact(Artifact other) {
    final Map<String, dynamic> diff = {};

    if (refId != other.refId) {
      diff['refId'] = () => other.refId;
    }

    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    return diff;
  }
}
