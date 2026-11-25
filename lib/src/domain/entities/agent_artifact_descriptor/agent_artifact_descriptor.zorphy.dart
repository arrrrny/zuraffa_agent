// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_artifact_descriptor.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentArtifactDescriptor {
  AgentArtifactDescriptor({
    required String this.id,
    required String this.kind,
    required int this.byteCount,
  });

  factory AgentArtifactDescriptor.fromJson(Map<String, dynamic> json) =>
      _$AgentArtifactDescriptorFromJson(json);

  final String id;

  final String kind;

  final int byteCount;

  AgentArtifactDescriptor copyWith({String? id, String? kind, int? byteCount}) {
    return AgentArtifactDescriptor(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      byteCount: byteCount ?? this.byteCount,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  AgentArtifactDescriptor copyWithField<T>(
    Field<AgentArtifactDescriptor, T> field,
    T value,
  ) {
    switch (field.name) {
      case 'id':
        return copyWith(id: value as String);
      case 'kind':
        return copyWith(kind: value as String);
      case 'byteCount':
        return copyWith(byteCount: value as int);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'AgentArtifactDescriptor has no settable field with this name',
        );
    }
  }

  AgentArtifactDescriptor copyWithAgentArtifactDescriptor({
    String? id,
    String? kind,
    int? byteCount,
  }) {
    return copyWith(id: id, kind: kind, byteCount: byteCount);
  }

  AgentArtifactDescriptor patchWithAgentArtifactDescriptor([
    AgentArtifactDescriptorPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? AgentArtifactDescriptorPatch();
    final _patchMap = _patcher.patchMap;
    return AgentArtifactDescriptor(
      id: _patchMap.containsKey(AgentArtifactDescriptor$.id)
          ? ((_patchMap[AgentArtifactDescriptor$.id] is Function)
                    ? _patchMap[AgentArtifactDescriptor$.id](this.id)
                    : (_patchMap[AgentArtifactDescriptor$.id] is Patch)
                    ? _patchMap[AgentArtifactDescriptor$.id].applyTo(this.id)
                    : _patchMap[AgentArtifactDescriptor$.id])
                as String
          : this.id,
      kind: _patchMap.containsKey(AgentArtifactDescriptor$.kind)
          ? ((_patchMap[AgentArtifactDescriptor$.kind] is Function)
                    ? _patchMap[AgentArtifactDescriptor$.kind](this.kind)
                    : (_patchMap[AgentArtifactDescriptor$.kind] is Patch)
                    ? _patchMap[AgentArtifactDescriptor$.kind].applyTo(
                        this.kind,
                      )
                    : _patchMap[AgentArtifactDescriptor$.kind])
                as String
          : this.kind,
      byteCount: _patchMap.containsKey(AgentArtifactDescriptor$.byteCount)
          ? ((_patchMap[AgentArtifactDescriptor$.byteCount] is Function)
                    ? _patchMap[AgentArtifactDescriptor$.byteCount](
                        this.byteCount,
                      )
                    : (_patchMap[AgentArtifactDescriptor$.byteCount] is Patch)
                    ? _patchMap[AgentArtifactDescriptor$.byteCount].applyTo(
                        this.byteCount,
                      )
                    : _patchMap[AgentArtifactDescriptor$.byteCount])
                as int
          : this.byteCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentArtifactDescriptor &&
        id == other.id &&
        kind == other.kind &&
        byteCount == other.byteCount;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.kind, this.byteCount);
  }

  @override
  String toString() {
    return 'AgentArtifactDescriptor(' +
        'id: ${id}' +
        ', ' +
        'kind: ${kind}' +
        ', ' +
        'byteCount: ${byteCount})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentArtifactDescriptorToJson(this);
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

extension AgentArtifactDescriptorPropertyHelpers on AgentArtifactDescriptor {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasKind {
    return this.kind.isNotEmpty;
  }

  bool get noKind {
    return this.kind.isEmpty;
  }
}

extension AgentArtifactDescriptorSerialization on AgentArtifactDescriptor {
  Map<String, dynamic> toJson() {
    return _$AgentArtifactDescriptorToJson(this);
  }
}

enum AgentArtifactDescriptor$ { id, kind, byteCount }

class AgentArtifactDescriptorPatch
    extends PatchBase<AgentArtifactDescriptor, AgentArtifactDescriptor$> {
  AgentArtifactDescriptor applyTo(AgentArtifactDescriptor entity) {
    return entity.patchWithAgentArtifactDescriptor(this);
  }

  AgentArtifactDescriptorPatch withId(String? value) {
    patchMap[AgentArtifactDescriptor$.id] = value;
    return this;
  }

  AgentArtifactDescriptorPatch withKind(String? value) {
    patchMap[AgentArtifactDescriptor$.kind] = value;
    return this;
  }

  AgentArtifactDescriptorPatch withByteCount(int? value) {
    patchMap[AgentArtifactDescriptor$.byteCount] = value;
    return this;
  }
}

/// Field descriptors for [AgentArtifactDescriptor] query construction
abstract final class AgentArtifactDescriptorFields {
  static const id = Field<AgentArtifactDescriptor, String>('id', _$id);

  static const kind = Field<AgentArtifactDescriptor, String>('kind', _$kind);

  static const byteCount = Field<AgentArtifactDescriptor, int>(
    'byteCount',
    _$byteCount,
  );

  static String _$id(AgentArtifactDescriptor e) {
    return e.id;
  }

  static String _$kind(AgentArtifactDescriptor e) {
    return e.kind;
  }

  static int _$byteCount(AgentArtifactDescriptor e) {
    return e.byteCount;
  }
}

extension AgentArtifactDescriptorCompareE on AgentArtifactDescriptor {
  Map<String, dynamic> compareToAgentArtifactDescriptor(
    AgentArtifactDescriptor other,
  ) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (kind != other.kind) {
      diff['kind'] = () => other.kind;
    }

    if (byteCount != other.byteCount) {
      diff['byteCount'] = () => other.byteCount;
    }
    return diff;
  }
}
