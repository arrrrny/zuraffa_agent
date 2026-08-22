// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'tool_call_signature.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ToolCallSignature {
  ToolCallSignature({
    String? id,
    required String this.toolName,
    required String this.normalizedArgs,
  }) : this.id = id ?? const Uuid().v4();

  factory ToolCallSignature.fromJson(Map<String, dynamic> json) =>
      _$ToolCallSignatureFromJson(json);

  final String id;

  final String toolName;

  final String normalizedArgs;

  ToolCallSignature copyWith({
    String? id,
    String? toolName,
    String? normalizedArgs,
  }) {
    return ToolCallSignature(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      normalizedArgs: normalizedArgs ?? this.normalizedArgs,
    );
  }

  ToolCallSignature copyWithToolCallSignature({
    String? id,
    String? toolName,
    String? normalizedArgs,
  }) {
    return copyWith(id: id, toolName: toolName, normalizedArgs: normalizedArgs);
  }

  ToolCallSignature patchWithToolCallSignature([
    ToolCallSignaturePatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ToolCallSignaturePatch();
    final _patchMap = _patcher.patchMap;
    return ToolCallSignature(
      id: _patchMap.containsKey(ToolCallSignature$.id)
          ? ((_patchMap[ToolCallSignature$.id] is Function)
                    ? _patchMap[ToolCallSignature$.id](this.id)
                    : (_patchMap[ToolCallSignature$.id] is Patch)
                    ? _patchMap[ToolCallSignature$.id].applyTo(this.id)
                    : _patchMap[ToolCallSignature$.id])
                as String
          : this.id,
      toolName: _patchMap.containsKey(ToolCallSignature$.toolName)
          ? ((_patchMap[ToolCallSignature$.toolName] is Function)
                    ? _patchMap[ToolCallSignature$.toolName](this.toolName)
                    : (_patchMap[ToolCallSignature$.toolName] is Patch)
                    ? _patchMap[ToolCallSignature$.toolName].applyTo(
                        this.toolName,
                      )
                    : _patchMap[ToolCallSignature$.toolName])
                as String
          : this.toolName,
      normalizedArgs: _patchMap.containsKey(ToolCallSignature$.normalizedArgs)
          ? ((_patchMap[ToolCallSignature$.normalizedArgs] is Function)
                    ? _patchMap[ToolCallSignature$.normalizedArgs](
                        this.normalizedArgs,
                      )
                    : (_patchMap[ToolCallSignature$.normalizedArgs] is Patch)
                    ? _patchMap[ToolCallSignature$.normalizedArgs].applyTo(
                        this.normalizedArgs,
                      )
                    : _patchMap[ToolCallSignature$.normalizedArgs])
                as String
          : this.normalizedArgs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCallSignature &&
        id == other.id &&
        toolName == other.toolName &&
        normalizedArgs == other.normalizedArgs;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.toolName, this.normalizedArgs);
  }

  @override
  String toString() {
    return 'ToolCallSignature(' +
        'id: ${id}' +
        ', ' +
        'toolName: ${toolName}' +
        ', ' +
        'normalizedArgs: ${normalizedArgs})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolCallSignatureToJson(this);
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

extension ToolCallSignaturePropertyHelpers on ToolCallSignature {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasToolName {
    return this.toolName.isNotEmpty;
  }

  bool get noToolName {
    return this.toolName.isEmpty;
  }

  bool get hasNormalizedArgs {
    return this.normalizedArgs.isNotEmpty;
  }

  bool get noNormalizedArgs {
    return this.normalizedArgs.isEmpty;
  }
}

extension ToolCallSignatureSerialization on ToolCallSignature {
  Map<String, dynamic> toJson() {
    return _$ToolCallSignatureToJson(this);
  }
}

enum ToolCallSignature$ { id, toolName, normalizedArgs }

class ToolCallSignaturePatch
    extends PatchBase<ToolCallSignature, ToolCallSignature$> {
  ToolCallSignature applyTo(ToolCallSignature entity) {
    return entity.patchWithToolCallSignature(this);
  }

  ToolCallSignaturePatch withId(String? value) {
    patchMap[ToolCallSignature$.id] = value;
    return this;
  }

  ToolCallSignaturePatch withToolName(String? value) {
    patchMap[ToolCallSignature$.toolName] = value;
    return this;
  }

  ToolCallSignaturePatch withNormalizedArgs(String? value) {
    patchMap[ToolCallSignature$.normalizedArgs] = value;
    return this;
  }
}

/// Field descriptors for [ToolCallSignature] query construction
abstract final class ToolCallSignatureFields {
  static const id = Field<ToolCallSignature, String>('id', _$id);

  static const toolName = Field<ToolCallSignature, String>(
    'toolName',
    _$toolName,
  );

  static const normalizedArgs = Field<ToolCallSignature, String>(
    'normalizedArgs',
    _$normalizedArgs,
  );

  static String _$id(ToolCallSignature e) {
    return e.id;
  }

  static String _$toolName(ToolCallSignature e) {
    return e.toolName;
  }

  static String _$normalizedArgs(ToolCallSignature e) {
    return e.normalizedArgs;
  }
}

extension ToolCallSignatureCompareE on ToolCallSignature {
  Map<String, dynamic> compareToToolCallSignature(ToolCallSignature other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (toolName != other.toolName) {
      diff['toolName'] = () => other.toolName;
    }

    if (normalizedArgs != other.normalizedArgs) {
      diff['normalizedArgs'] = () => other.normalizedArgs;
    }
    return diff;
  }
}
