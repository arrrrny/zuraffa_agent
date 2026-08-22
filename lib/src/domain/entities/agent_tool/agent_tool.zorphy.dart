// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_tool.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentTool {
  AgentTool({
    String? id,
    required String this.name,
    required String this.description,
    required Map<String, dynamic> this.inputSchema,
    required RiskTier this.riskTier,
    required ExecutionMode this.executionMode,
    required ToolSource this.source,
    String? this.transportBinding,
  }) : this.id = id ?? const Uuid().v4();

  factory AgentTool.fromJson(Map<String, dynamic> json) =>
      _$AgentToolFromJson(json);

  final String id;

  final String name;

  final String description;

  final Map<String, dynamic> inputSchema;

  final RiskTier riskTier;

  final ExecutionMode executionMode;

  final ToolSource source;

  final String? transportBinding;

  AgentTool copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? inputSchema,
    RiskTier? riskTier,
    ExecutionMode? executionMode,
    ToolSource? source,
    String? transportBinding,
  }) {
    return AgentTool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      inputSchema: inputSchema ?? this.inputSchema,
      riskTier: riskTier ?? this.riskTier,
      executionMode: executionMode ?? this.executionMode,
      source: source ?? this.source,
      transportBinding: transportBinding ?? this.transportBinding,
    );
  }

  AgentTool copyWithAgentTool({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? inputSchema,
    RiskTier? riskTier,
    ExecutionMode? executionMode,
    ToolSource? source,
    String? transportBinding,
  }) {
    return copyWith(
      id: id,
      name: name,
      description: description,
      inputSchema: inputSchema,
      riskTier: riskTier,
      executionMode: executionMode,
      source: source,
      transportBinding: transportBinding,
    );
  }

  AgentTool patchWithAgentTool([AgentToolPatch? patchInput]) {
    final _patcher = patchInput ?? AgentToolPatch();
    final _patchMap = _patcher.patchMap;
    return AgentTool(
      id: _patchMap.containsKey(AgentTool$.id)
          ? ((_patchMap[AgentTool$.id] is Function)
                    ? _patchMap[AgentTool$.id](this.id)
                    : (_patchMap[AgentTool$.id] is Patch)
                    ? _patchMap[AgentTool$.id].applyTo(this.id)
                    : _patchMap[AgentTool$.id])
                as String
          : this.id,
      name: _patchMap.containsKey(AgentTool$.name_)
          ? ((_patchMap[AgentTool$.name_] is Function)
                    ? _patchMap[AgentTool$.name_](this.name)
                    : (_patchMap[AgentTool$.name_] is Patch)
                    ? _patchMap[AgentTool$.name_].applyTo(this.name)
                    : _patchMap[AgentTool$.name_])
                as String
          : this.name,
      description: _patchMap.containsKey(AgentTool$.description)
          ? ((_patchMap[AgentTool$.description] is Function)
                    ? _patchMap[AgentTool$.description](this.description)
                    : (_patchMap[AgentTool$.description] is Patch)
                    ? _patchMap[AgentTool$.description].applyTo(
                        this.description,
                      )
                    : _patchMap[AgentTool$.description])
                as String
          : this.description,
      inputSchema: _patchMap.containsKey(AgentTool$.inputSchema)
          ? ((_patchMap[AgentTool$.inputSchema] is Function)
                    ? _patchMap[AgentTool$.inputSchema](this.inputSchema)
                    : (_patchMap[AgentTool$.inputSchema] is Patch)
                    ? _patchMap[AgentTool$.inputSchema].applyTo(
                        this.inputSchema,
                      )
                    : _patchMap[AgentTool$.inputSchema])
                as Map<String, dynamic>
          : this.inputSchema,
      riskTier: _patchMap.containsKey(AgentTool$.riskTier)
          ? ((_patchMap[AgentTool$.riskTier] is Function)
                    ? _patchMap[AgentTool$.riskTier](this.riskTier)
                    : (_patchMap[AgentTool$.riskTier] is Patch)
                    ? _patchMap[AgentTool$.riskTier].applyTo(this.riskTier)
                    : _patchMap[AgentTool$.riskTier])
                as RiskTier
          : this.riskTier,
      executionMode: _patchMap.containsKey(AgentTool$.executionMode)
          ? ((_patchMap[AgentTool$.executionMode] is Function)
                    ? _patchMap[AgentTool$.executionMode](this.executionMode)
                    : (_patchMap[AgentTool$.executionMode] is Patch)
                    ? _patchMap[AgentTool$.executionMode].applyTo(
                        this.executionMode,
                      )
                    : _patchMap[AgentTool$.executionMode])
                as ExecutionMode
          : this.executionMode,
      source: _patchMap.containsKey(AgentTool$.source)
          ? ((_patchMap[AgentTool$.source] is Function)
                    ? _patchMap[AgentTool$.source](this.source)
                    : (_patchMap[AgentTool$.source] is Patch)
                    ? _patchMap[AgentTool$.source].applyTo(this.source)
                    : _patchMap[AgentTool$.source])
                as ToolSource
          : this.source,
      transportBinding: _patchMap.containsKey(AgentTool$.transportBinding)
          ? ((_patchMap[AgentTool$.transportBinding] is Function)
                    ? _patchMap[AgentTool$.transportBinding](
                        this.transportBinding,
                      )
                    : (_patchMap[AgentTool$.transportBinding] is Patch)
                    ? _patchMap[AgentTool$.transportBinding].applyTo(
                        this.transportBinding,
                      )
                    : _patchMap[AgentTool$.transportBinding])
                as String?
          : this.transportBinding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentTool &&
        id == other.id &&
        name == other.name &&
        description == other.description &&
        inputSchema == other.inputSchema &&
        riskTier == other.riskTier &&
        executionMode == other.executionMode &&
        source == other.source &&
        transportBinding == other.transportBinding;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.name,
      this.description,
      this.inputSchema,
      this.riskTier,
      this.executionMode,
      this.source,
      this.transportBinding,
    );
  }

  @override
  String toString() {
    return 'AgentTool(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'description: ${description}' +
        ', ' +
        'inputSchema: ${inputSchema}' +
        ', ' +
        'riskTier: ${riskTier}' +
        ', ' +
        'executionMode: ${executionMode}' +
        ', ' +
        'source: ${source}' +
        ', ' +
        'transportBinding: ${transportBinding})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentToolToJson(this);
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

extension AgentToolPropertyHelpers on AgentTool {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasName {
    return this.name.isNotEmpty;
  }

  bool get noName {
    return this.name.isEmpty;
  }

  bool get hasDescription {
    return this.description.isNotEmpty;
  }

  bool get noDescription {
    return this.description.isEmpty;
  }

  bool get hasInputSchema {
    return this.inputSchema.isNotEmpty;
  }

  bool get noInputSchema {
    return this.inputSchema.isEmpty;
  }

  bool get isRiskTierSafe {
    return this.riskTier == RiskTier.safe;
  }

  bool get isRiskTierConfirm {
    return this.riskTier == RiskTier.confirm;
  }

  bool get isRiskTierAdmin {
    return this.riskTier == RiskTier.admin;
  }

  bool get isExecutionModeSequential {
    return this.executionMode == ExecutionMode.sequential;
  }

  bool get isExecutionModeParallel {
    return this.executionMode == ExecutionMode.parallel;
  }

  bool get isSourceDda {
    return this.source == ToolSource.dda;
  }

  bool get isSourceGenerated {
    return this.source == ToolSource.generated;
  }

  bool get isSourceMcp {
    return this.source == ToolSource.mcp;
  }

  bool get hasTransportBinding {
    return this.transportBinding?.isNotEmpty == true;
  }

  bool get noTransportBinding {
    return this.transportBinding?.isEmpty ?? true;
  }

  String get transportBindingRequired {
    return this.transportBinding ??
        (throw StateError('transportBinding is required but was null'));
  }
}

extension AgentToolSerialization on AgentTool {
  Map<String, dynamic> toJson() {
    return _$AgentToolToJson(this);
  }
}

enum AgentTool$ {
  id,
  name_,
  description,
  inputSchema,
  riskTier,
  executionMode,
  source,
  transportBinding,
}

class AgentToolPatch extends PatchBase<AgentTool, AgentTool$> {
  AgentTool applyTo(AgentTool entity) {
    return entity.patchWithAgentTool(this);
  }

  AgentToolPatch withId(String? value) {
    patchMap[AgentTool$.id] = value;
    return this;
  }

  AgentToolPatch withName(String? value) {
    patchMap[AgentTool$.name_] = value;
    return this;
  }

  AgentToolPatch withDescription(String? value) {
    patchMap[AgentTool$.description] = value;
    return this;
  }

  AgentToolPatch withInputSchema(Map<String, dynamic>? value) {
    patchMap[AgentTool$.inputSchema] = value;
    return this;
  }

  AgentToolPatch withRiskTier(RiskTier? value) {
    patchMap[AgentTool$.riskTier] = value;
    return this;
  }

  AgentToolPatch withExecutionMode(ExecutionMode? value) {
    patchMap[AgentTool$.executionMode] = value;
    return this;
  }

  AgentToolPatch withSource(ToolSource? value) {
    patchMap[AgentTool$.source] = value;
    return this;
  }

  AgentToolPatch withTransportBinding(String? value) {
    patchMap[AgentTool$.transportBinding] = value;
    return this;
  }
}

/// Field descriptors for [AgentTool] query construction
abstract final class AgentToolFields {
  static const id = Field<AgentTool, String>('id', _$id);

  static const name = Field<AgentTool, String>('name', _$name);

  static const description = Field<AgentTool, String>(
    'description',
    _$description,
  );

  static const inputSchema = Field<AgentTool, Map<String, dynamic>>(
    'inputSchema',
    _$inputSchema,
  );

  static const riskTier = Field<AgentTool, RiskTier>('riskTier', _$riskTier);

  static const executionMode = Field<AgentTool, ExecutionMode>(
    'executionMode',
    _$executionMode,
  );

  static const source = Field<AgentTool, ToolSource>('source', _$source);

  static const transportBinding = Field<AgentTool, String?>(
    'transportBinding',
    _$transportBinding,
  );

  static String _$id(AgentTool e) {
    return e.id;
  }

  static String _$name(AgentTool e) {
    return e.name;
  }

  static String _$description(AgentTool e) {
    return e.description;
  }

  static Map<String, dynamic> _$inputSchema(AgentTool e) {
    return e.inputSchema;
  }

  static RiskTier _$riskTier(AgentTool e) {
    return e.riskTier;
  }

  static ExecutionMode _$executionMode(AgentTool e) {
    return e.executionMode;
  }

  static ToolSource _$source(AgentTool e) {
    return e.source;
  }

  static String? _$transportBinding(AgentTool e) {
    return e.transportBinding;
  }
}

extension AgentToolCompareE on AgentTool {
  Map<String, dynamic> compareToAgentTool(AgentTool other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (name != other.name) {
      diff['name'] = () => other.name;
    }

    if (description != other.description) {
      diff['description'] = () => other.description;
    }

    if (inputSchema != other.inputSchema) {
      diff['inputSchema'] = () => other.inputSchema;
    }

    if (riskTier != other.riskTier) {
      diff['riskTier'] = () => other.riskTier;
    }

    if (executionMode != other.executionMode) {
      diff['executionMode'] = () => other.executionMode;
    }

    if (source != other.source) {
      diff['source'] = () => other.source;
    }

    if (transportBinding != other.transportBinding) {
      diff['transportBinding'] = () => other.transportBinding;
    }
    return diff;
  }
}
