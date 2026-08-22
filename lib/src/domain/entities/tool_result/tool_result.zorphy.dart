// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'tool_result.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ToolResult {
  ToolResult({
    required String this.content,
    Map<String, dynamic>? this.structuredPayload,
    ArtifactRef? this.artifactRef,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);

  final String content;

  final Map<String, dynamic>? structuredPayload;

  final ArtifactRef? artifactRef;

  ToolResult copyWith({
    String? content,
    Map<String, dynamic>? structuredPayload,
    ArtifactRef? artifactRef,
  }) {
    return ToolResult(
      content: content ?? this.content,
      structuredPayload: structuredPayload ?? this.structuredPayload,
      artifactRef: artifactRef ?? this.artifactRef,
    );
  }

  ToolResult copyWithToolResult({
    String? content,
    Map<String, dynamic>? structuredPayload,
    ArtifactRef? artifactRef,
  }) {
    return copyWith(
      content: content,
      structuredPayload: structuredPayload,
      artifactRef: artifactRef,
    );
  }

  ToolResult patchWithToolResult([ToolResultPatch? patchInput]) {
    final _patcher = patchInput ?? ToolResultPatch();
    final _patchMap = _patcher.patchMap;
    return ToolResult(
      content: _patchMap.containsKey(ToolResult$.content)
          ? ((_patchMap[ToolResult$.content] is Function)
                    ? _patchMap[ToolResult$.content](this.content)
                    : (_patchMap[ToolResult$.content] is Patch)
                    ? _patchMap[ToolResult$.content].applyTo(this.content)
                    : _patchMap[ToolResult$.content])
                as String
          : this.content,
      structuredPayload: _patchMap.containsKey(ToolResult$.structuredPayload)
          ? ((_patchMap[ToolResult$.structuredPayload] is Function)
                    ? _patchMap[ToolResult$.structuredPayload](
                        this.structuredPayload,
                      )
                    : (_patchMap[ToolResult$.structuredPayload] is Patch)
                    ? _patchMap[ToolResult$.structuredPayload].applyTo(
                        this.structuredPayload,
                      )
                    : _patchMap[ToolResult$.structuredPayload])
                as Map<String, dynamic>?
          : this.structuredPayload,
      artifactRef: _patchMap.containsKey(ToolResult$.artifactRef)
          ? ((_patchMap[ToolResult$.artifactRef] is Function)
                    ? _patchMap[ToolResult$.artifactRef](this.artifactRef)
                    : (_patchMap[ToolResult$.artifactRef] is Patch)
                    ? _patchMap[ToolResult$.artifactRef].applyTo(
                        this.artifactRef,
                      )
                    : _patchMap[ToolResult$.artifactRef])
                as ArtifactRef?
          : this.artifactRef,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolResult &&
        content == other.content &&
        structuredPayload == other.structuredPayload &&
        artifactRef == other.artifactRef;
  }

  @override
  int get hashCode {
    return Object.hash(this.content, this.structuredPayload, this.artifactRef);
  }

  @override
  String toString() {
    return 'ToolResult(' +
        'content: ${content}' +
        ', ' +
        'structuredPayload: ${structuredPayload}' +
        ', ' +
        'artifactRef: ${artifactRef})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolResultToJson(this);
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

extension ToolResultPropertyHelpers on ToolResult {
  bool get hasContent {
    return this.content.isNotEmpty;
  }

  bool get noContent {
    return this.content.isEmpty;
  }

  Map<String, dynamic> get structuredPayloadRequired {
    return this.structuredPayload ??
        (throw StateError('structuredPayload is required but was null'));
  }

  bool get hasStructuredPayload {
    return this.structuredPayload?.isNotEmpty ?? false;
  }

  bool get noStructuredPayload {
    return this.structuredPayload?.isEmpty ?? true;
  }

  bool get hasArtifactRef {
    return this.artifactRef != null;
  }

  bool get noArtifactRef {
    return this.artifactRef == null;
  }

  ArtifactRef get artifactRefRequired {
    return this.artifactRef ??
        (throw StateError('artifactRef is required but was null'));
  }
}

extension ToolResultSerialization on ToolResult {
  Map<String, dynamic> toJson() {
    return _$ToolResultToJson(this);
  }
}

enum ToolResult$ { content, structuredPayload, artifactRef }

class ToolResultPatch extends PatchBase<ToolResult, ToolResult$> {
  ToolResult applyTo(ToolResult entity) {
    return entity.patchWithToolResult(this);
  }

  ToolResultPatch withContent(String? value) {
    patchMap[ToolResult$.content] = value;
    return this;
  }

  ToolResultPatch withStructuredPayload(Map<String, dynamic>? value) {
    patchMap[ToolResult$.structuredPayload] = value;
    return this;
  }

  ToolResultPatch withArtifactRef(ArtifactRef? value) {
    patchMap[ToolResult$.artifactRef] = value;
    return this;
  }

  ToolResultPatch withArtifactRefPatch(ArtifactRefPatch patch) {
    patchMap[ToolResult$.artifactRef] = patch;
    return this;
  }

  ToolResultPatch withArtifactRefPatchFunc(
    ArtifactRefPatch Function(ArtifactRefPatch) patch,
  ) {
    patchMap[ToolResult$.artifactRef] = (dynamic current) {
      var currentPatch = ArtifactRefPatch();
      return patch(currentPatch).applyTo(current as ArtifactRef);
    };
    return this;
  }
}

/// Field descriptors for [ToolResult] query construction
abstract final class ToolResultFields {
  static const content = Field<ToolResult, String>('content', _$content);

  static const structuredPayload = Field<ToolResult, Map<String, dynamic>?>(
    'structuredPayload',
    _$structuredPayload,
  );

  static const artifactRef = Field<ToolResult, ArtifactRef?>(
    'artifactRef',
    _$artifactRef,
  );

  static String _$content(ToolResult e) {
    return e.content;
  }

  static Map<String, dynamic>? _$structuredPayload(ToolResult e) {
    return e.structuredPayload;
  }

  static ArtifactRef? _$artifactRef(ToolResult e) {
    return e.artifactRef;
  }
}

extension ToolResultCompareE on ToolResult {
  Map<String, dynamic> compareToToolResult(ToolResult other) {
    final Map<String, dynamic> diff = {};

    if (content != other.content) {
      diff['content'] = () => other.content;
    }

    if (structuredPayload != other.structuredPayload) {
      diff['structuredPayload'] = () => other.structuredPayload;
    }

    if (artifactRef != other.artifactRef) {
      diff['artifactRef'] = () => other.artifactRef;
    }
    return diff;
  }
}
