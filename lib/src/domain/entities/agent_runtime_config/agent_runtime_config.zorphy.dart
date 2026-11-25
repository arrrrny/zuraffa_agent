// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_runtime_config.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentRuntimeConfig {
  AgentRuntimeConfig({
    required String this.modelProvider,
    required String this.modelId,
    String? this.systemPrompt,
    String? this.thinkingLevel,
    required List<String> this.toolNames,
  });

  factory AgentRuntimeConfig.fromJson(Map<String, dynamic> json) =>
      _$AgentRuntimeConfigFromJson(json);

  final String modelProvider;

  final String modelId;

  final String? systemPrompt;

  final String? thinkingLevel;

  final List<String> toolNames;

  AgentRuntimeConfig copyWith({
    String? modelProvider,
    String? modelId,
    String? systemPrompt,
    String? thinkingLevel,
    List<String>? toolNames,
  }) {
    return AgentRuntimeConfig(
      modelProvider: modelProvider ?? this.modelProvider,
      modelId: modelId ?? this.modelId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      thinkingLevel: thinkingLevel ?? this.thinkingLevel,
      toolNames: toolNames ?? this.toolNames,
    );
  }

  /// Returns a copy of this entity with [field] set to [value].
  ///
  /// Delegates to [copyWith]: the receiver is never mutated and a
  /// null [value] keeps the current field value.
  AgentRuntimeConfig copyWithField<T>(
    Field<AgentRuntimeConfig, T> field,
    T value,
  ) {
    switch (field.name) {
      case 'modelProvider':
        return copyWith(modelProvider: value as String);
      case 'modelId':
        return copyWith(modelId: value as String);
      case 'systemPrompt':
        return copyWith(systemPrompt: value as String?);
      case 'thinkingLevel':
        return copyWith(thinkingLevel: value as String?);
      case 'toolNames':
        return copyWith(toolNames: value as List<String>);
      default:
        throw ArgumentError.value(
          field.name,
          'field',
          'AgentRuntimeConfig has no settable field with this name',
        );
    }
  }

  AgentRuntimeConfig copyWithAgentRuntimeConfig({
    String? modelProvider,
    String? modelId,
    String? systemPrompt,
    String? thinkingLevel,
    List<String>? toolNames,
  }) {
    return copyWith(
      modelProvider: modelProvider,
      modelId: modelId,
      systemPrompt: systemPrompt,
      thinkingLevel: thinkingLevel,
      toolNames: toolNames,
    );
  }

  AgentRuntimeConfig patchWithAgentRuntimeConfig([
    AgentRuntimeConfigPatch? patchInput,
  ]) {
    final _patcher = patchInput ?? AgentRuntimeConfigPatch();
    final _patchMap = _patcher.patchMap;
    return AgentRuntimeConfig(
      modelProvider: _patchMap.containsKey(AgentRuntimeConfig$.modelProvider)
          ? ((_patchMap[AgentRuntimeConfig$.modelProvider] is Function)
                    ? _patchMap[AgentRuntimeConfig$.modelProvider](
                        this.modelProvider,
                      )
                    : (_patchMap[AgentRuntimeConfig$.modelProvider] is Patch)
                    ? _patchMap[AgentRuntimeConfig$.modelProvider].applyTo(
                        this.modelProvider,
                      )
                    : _patchMap[AgentRuntimeConfig$.modelProvider])
                as String
          : this.modelProvider,
      modelId: _patchMap.containsKey(AgentRuntimeConfig$.modelId)
          ? ((_patchMap[AgentRuntimeConfig$.modelId] is Function)
                    ? _patchMap[AgentRuntimeConfig$.modelId](this.modelId)
                    : (_patchMap[AgentRuntimeConfig$.modelId] is Patch)
                    ? _patchMap[AgentRuntimeConfig$.modelId].applyTo(
                        this.modelId,
                      )
                    : _patchMap[AgentRuntimeConfig$.modelId])
                as String
          : this.modelId,
      systemPrompt: _patchMap.containsKey(AgentRuntimeConfig$.systemPrompt)
          ? ((_patchMap[AgentRuntimeConfig$.systemPrompt] is Function)
                    ? _patchMap[AgentRuntimeConfig$.systemPrompt](
                        this.systemPrompt,
                      )
                    : (_patchMap[AgentRuntimeConfig$.systemPrompt] is Patch)
                    ? _patchMap[AgentRuntimeConfig$.systemPrompt].applyTo(
                        this.systemPrompt,
                      )
                    : _patchMap[AgentRuntimeConfig$.systemPrompt])
                as String?
          : this.systemPrompt,
      thinkingLevel: _patchMap.containsKey(AgentRuntimeConfig$.thinkingLevel)
          ? ((_patchMap[AgentRuntimeConfig$.thinkingLevel] is Function)
                    ? _patchMap[AgentRuntimeConfig$.thinkingLevel](
                        this.thinkingLevel,
                      )
                    : (_patchMap[AgentRuntimeConfig$.thinkingLevel] is Patch)
                    ? _patchMap[AgentRuntimeConfig$.thinkingLevel].applyTo(
                        this.thinkingLevel,
                      )
                    : _patchMap[AgentRuntimeConfig$.thinkingLevel])
                as String?
          : this.thinkingLevel,
      toolNames: _patchMap.containsKey(AgentRuntimeConfig$.toolNames)
          ? ((_patchMap[AgentRuntimeConfig$.toolNames] is Function)
                    ? _patchMap[AgentRuntimeConfig$.toolNames](this.toolNames)
                    : (_patchMap[AgentRuntimeConfig$.toolNames] is Patch)
                    ? _patchMap[AgentRuntimeConfig$.toolNames].applyTo(
                        this.toolNames,
                      )
                    : _patchMap[AgentRuntimeConfig$.toolNames])
                as List<String>
          : this.toolNames,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentRuntimeConfig &&
        modelProvider == other.modelProvider &&
        modelId == other.modelId &&
        systemPrompt == other.systemPrompt &&
        thinkingLevel == other.thinkingLevel &&
        toolNames == other.toolNames;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.modelProvider,
      this.modelId,
      this.systemPrompt,
      this.thinkingLevel,
      this.toolNames,
    );
  }

  @override
  String toString() {
    return 'AgentRuntimeConfig(' +
        'modelProvider: ${modelProvider}' +
        ', ' +
        'modelId: ${modelId}' +
        ', ' +
        'systemPrompt: ${systemPrompt}' +
        ', ' +
        'thinkingLevel: ${thinkingLevel}' +
        ', ' +
        'toolNames: ${toolNames})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentRuntimeConfigToJson(this);
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

extension AgentRuntimeConfigPropertyHelpers on AgentRuntimeConfig {
  bool get hasModelProvider {
    return this.modelProvider.isNotEmpty;
  }

  bool get noModelProvider {
    return this.modelProvider.isEmpty;
  }

  bool get hasModelId {
    return this.modelId.isNotEmpty;
  }

  bool get noModelId {
    return this.modelId.isEmpty;
  }

  bool get hasSystemPrompt {
    return this.systemPrompt?.isNotEmpty == true;
  }

  bool get noSystemPrompt {
    return this.systemPrompt?.isEmpty ?? true;
  }

  String get systemPromptRequired {
    return this.systemPrompt ??
        (throw StateError('systemPrompt is required but was null'));
  }

  bool get hasThinkingLevel {
    return this.thinkingLevel?.isNotEmpty == true;
  }

  bool get noThinkingLevel {
    return this.thinkingLevel?.isEmpty ?? true;
  }

  String get thinkingLevelRequired {
    return this.thinkingLevel ??
        (throw StateError('thinkingLevel is required but was null'));
  }

  bool get hasToolNames {
    return this.toolNames.isNotEmpty;
  }

  bool get noToolNames {
    return this.toolNames.isEmpty;
  }
}

extension AgentRuntimeConfigSerialization on AgentRuntimeConfig {
  Map<String, dynamic> toJson() {
    return _$AgentRuntimeConfigToJson(this);
  }
}

enum AgentRuntimeConfig$ {
  modelProvider,
  modelId,
  systemPrompt,
  thinkingLevel,
  toolNames,
}

class AgentRuntimeConfigPatch
    extends PatchBase<AgentRuntimeConfig, AgentRuntimeConfig$> {
  AgentRuntimeConfig applyTo(AgentRuntimeConfig entity) {
    return entity.patchWithAgentRuntimeConfig(this);
  }

  AgentRuntimeConfigPatch withModelProvider(String? value) {
    patchMap[AgentRuntimeConfig$.modelProvider] = value;
    return this;
  }

  AgentRuntimeConfigPatch withModelId(String? value) {
    patchMap[AgentRuntimeConfig$.modelId] = value;
    return this;
  }

  AgentRuntimeConfigPatch withSystemPrompt(String? value) {
    patchMap[AgentRuntimeConfig$.systemPrompt] = value;
    return this;
  }

  AgentRuntimeConfigPatch withThinkingLevel(String? value) {
    patchMap[AgentRuntimeConfig$.thinkingLevel] = value;
    return this;
  }

  AgentRuntimeConfigPatch withToolNames(List<String>? value) {
    patchMap[AgentRuntimeConfig$.toolNames] = value;
    return this;
  }
}

/// Field descriptors for [AgentRuntimeConfig] query construction
abstract final class AgentRuntimeConfigFields {
  static const modelProvider = Field<AgentRuntimeConfig, String>(
    'modelProvider',
    _$modelProvider,
  );

  static const modelId = Field<AgentRuntimeConfig, String>(
    'modelId',
    _$modelId,
  );

  static const systemPrompt = Field<AgentRuntimeConfig, String?>(
    'systemPrompt',
    _$systemPrompt,
  );

  static const thinkingLevel = Field<AgentRuntimeConfig, String?>(
    'thinkingLevel',
    _$thinkingLevel,
  );

  static const toolNames = Field<AgentRuntimeConfig, List<String>>(
    'toolNames',
    _$toolNames,
  );

  static String _$modelProvider(AgentRuntimeConfig e) {
    return e.modelProvider;
  }

  static String _$modelId(AgentRuntimeConfig e) {
    return e.modelId;
  }

  static String? _$systemPrompt(AgentRuntimeConfig e) {
    return e.systemPrompt;
  }

  static String? _$thinkingLevel(AgentRuntimeConfig e) {
    return e.thinkingLevel;
  }

  static List<String> _$toolNames(AgentRuntimeConfig e) {
    return e.toolNames;
  }
}

extension AgentRuntimeConfigCompareE on AgentRuntimeConfig {
  Map<String, dynamic> compareToAgentRuntimeConfig(AgentRuntimeConfig other) {
    final Map<String, dynamic> diff = {};

    if (modelProvider != other.modelProvider) {
      diff['modelProvider'] = () => other.modelProvider;
    }

    if (modelId != other.modelId) {
      diff['modelId'] = () => other.modelId;
    }

    if (systemPrompt != other.systemPrompt) {
      diff['systemPrompt'] = () => other.systemPrompt;
    }

    if (thinkingLevel != other.thinkingLevel) {
      diff['thinkingLevel'] = () => other.thinkingLevel;
    }

    if (toolNames != other.toolNames) {
      diff['toolNames'] = () => other.toolNames;
    }
    return diff;
  }
}
