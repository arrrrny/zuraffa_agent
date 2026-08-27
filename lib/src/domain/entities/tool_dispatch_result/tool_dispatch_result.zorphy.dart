// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'tool_dispatch_result.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ToolDispatchResult {
  ToolDispatchResult({
    required bool this.success,
    required String this.result,
    required String this.error,
    required List<String> this.artifactRefs,
  });

  factory ToolDispatchResult.fromJson(Map<String, dynamic> json) =>
      _$ToolDispatchResultFromJson(json);

  final bool success;

  final String result;

  final String error;

  final List<String> artifactRefs;

  ToolDispatchResult copyWith({
    bool? success,
    String? result,
    String? error,
    List<String>? artifactRefs,
  }) {
    return ToolDispatchResult(
      success: success ?? this.success,
      result: result ?? this.result,
      error: error ?? this.error,
      artifactRefs: artifactRefs ?? this.artifactRefs,
    );
  }

  ToolDispatchResult copyWithToolDispatchResult({
    bool? success,
    String? result,
    String? error,
    List<String>? artifactRefs,
  }) {
    return copyWith(
      success: success,
      result: result,
      error: error,
      artifactRefs: artifactRefs,
    );
  }

  ToolDispatchResult patchWithToolDispatchResult([
    ToolDispatchResultPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? ToolDispatchResultPatch();
    final _patchMap = _patcher.patchMap;
    return ToolDispatchResult(
      success: _patchMap.containsKey(ToolDispatchResult$.success)
          ? ((_patchMap[ToolDispatchResult$.success] is Function)
                    ? _patchMap[ToolDispatchResult$.success](this.success)
                    : (_patchMap[ToolDispatchResult$.success] is Patch)
                    ? _patchMap[ToolDispatchResult$.success].applyTo(
                        this.success,
                      )
                    : _patchMap[ToolDispatchResult$.success])
                as bool
          : this.success,
      result: _patchMap.containsKey(ToolDispatchResult$.result)
          ? ((_patchMap[ToolDispatchResult$.result] is Function)
                    ? _patchMap[ToolDispatchResult$.result](this.result)
                    : (_patchMap[ToolDispatchResult$.result] is Patch)
                    ? _patchMap[ToolDispatchResult$.result].applyTo(this.result)
                    : _patchMap[ToolDispatchResult$.result])
                as String
          : this.result,
      error: _patchMap.containsKey(ToolDispatchResult$.error)
          ? ((_patchMap[ToolDispatchResult$.error] is Function)
                    ? _patchMap[ToolDispatchResult$.error](this.error)
                    : (_patchMap[ToolDispatchResult$.error] is Patch)
                    ? _patchMap[ToolDispatchResult$.error].applyTo(this.error)
                    : _patchMap[ToolDispatchResult$.error])
                as String
          : this.error,
      artifactRefs: _patchMap.containsKey(ToolDispatchResult$.artifactRefs)
          ? ((_patchMap[ToolDispatchResult$.artifactRefs] is Function)
                    ? _patchMap[ToolDispatchResult$.artifactRefs](
                        this.artifactRefs,
                      )
                    : (_patchMap[ToolDispatchResult$.artifactRefs] is Patch)
                    ? _patchMap[ToolDispatchResult$.artifactRefs].applyTo(
                        this.artifactRefs,
                      )
                    : _patchMap[ToolDispatchResult$.artifactRefs])
                as List<String>
          : this.artifactRefs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolDispatchResult &&
        success == other.success &&
        result == other.result &&
        error == other.error &&
        artifactRefs == other.artifactRefs;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.success,
      this.result,
      this.error,
      this.artifactRefs,
    );
  }

  @override
  String toString() {
    return 'ToolDispatchResult(' +
        'success: ${success}' +
        ', ' +
        'result: ${result}' +
        ', ' +
        'error: ${error}' +
        ', ' +
        'artifactRefs: ${artifactRefs})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ToolDispatchResultToJson(this);
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

extension ToolDispatchResultPropertyHelpers on ToolDispatchResult {
  bool get hasResult {
    return this.result.isNotEmpty;
  }

  bool get noResult {
    return this.result.isEmpty;
  }

  bool get hasError {
    return this.error.isNotEmpty;
  }

  bool get noError {
    return this.error.isEmpty;
  }

  bool get hasArtifactRefs {
    return this.artifactRefs.isNotEmpty;
  }

  bool get noArtifactRefs {
    return this.artifactRefs.isEmpty;
  }
}

extension ToolDispatchResultSerialization on ToolDispatchResult {
  Map<String, dynamic> toJson() {
    return _$ToolDispatchResultToJson(this);
  }
}

enum ToolDispatchResult$ { success, result, error, artifactRefs }

class ToolDispatchResultPatch
    extends PatchBase<ToolDispatchResult, ToolDispatchResult$> {
  ToolDispatchResult applyTo(ToolDispatchResult entity) {
    return entity.patchWithToolDispatchResult(this);
  }

  ToolDispatchResultPatch withSuccess(bool? value) {
    patchMap[ToolDispatchResult$.success] = value;
    return this;
  }

  ToolDispatchResultPatch withResult(String? value) {
    patchMap[ToolDispatchResult$.result] = value;
    return this;
  }

  ToolDispatchResultPatch withError(String? value) {
    patchMap[ToolDispatchResult$.error] = value;
    return this;
  }

  ToolDispatchResultPatch withArtifactRefs(List<String>? value) {
    patchMap[ToolDispatchResult$.artifactRefs] = value;
    return this;
  }
}

/// Field descriptors for [ToolDispatchResult] query construction
abstract final class ToolDispatchResultFields {
  static const success = Field<ToolDispatchResult, bool>('success', _$success);

  static const result = Field<ToolDispatchResult, String>('result', _$result);

  static const error = Field<ToolDispatchResult, String>('error', _$error);

  static const artifactRefs = Field<ToolDispatchResult, List<String>>(
    'artifactRefs',
    _$artifactRefs,
  );

  static bool _$success(ToolDispatchResult e) {
    return e.success;
  }

  static String _$result(ToolDispatchResult e) {
    return e.result;
  }

  static String _$error(ToolDispatchResult e) {
    return e.error;
  }

  static List<String> _$artifactRefs(ToolDispatchResult e) {
    return e.artifactRefs;
  }
}

extension ToolDispatchResultCompareE on ToolDispatchResult {
  Map<String, dynamic> compareToToolDispatchResult(ToolDispatchResult other) {
    final Map<String, dynamic> diff = {};

    if (success != other.success) {
      diff['success'] = () => other.success;
    }

    if (result != other.result) {
      diff['result'] = () => other.result;
    }

    if (error != other.error) {
      diff['error'] = () => other.error;
    }

    if (artifactRefs != other.artifactRefs) {
      diff['artifactRefs'] = () => other.artifactRefs;
    }
    return diff;
  }
}
