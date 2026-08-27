// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'agent_spec.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AgentSpec {
  AgentSpec({
    required String this.id,
    required List<String> this.tools,
    required List<String> this.subagents,
    required String this.budget,
    required String this.systemPrompt,
    required String this.riskTier,
    required String this.extendsSpec,
  });

  factory AgentSpec.fromJson(Map<String, dynamic> json) =>
      _$AgentSpecFromJson(json);

  final String id;

  final List<String> tools;

  final List<String> subagents;

  final String budget;

  final String systemPrompt;

  final String riskTier;

  final String extendsSpec;

  AgentSpec copyWith({
    String? id,
    List<String>? tools,
    List<String>? subagents,
    String? budget,
    String? systemPrompt,
    String? riskTier,
    String? extendsSpec,
  }) {
    return AgentSpec(
      id: id ?? this.id,
      tools: tools ?? this.tools,
      subagents: subagents ?? this.subagents,
      budget: budget ?? this.budget,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      riskTier: riskTier ?? this.riskTier,
      extendsSpec: extendsSpec ?? this.extendsSpec,
    );
  }

  AgentSpec copyWithAgentSpec({
    String? id,
    List<String>? tools,
    List<String>? subagents,
    String? budget,
    String? systemPrompt,
    String? riskTier,
    String? extendsSpec,
  }) {
    return copyWith(
      id: id,
      tools: tools,
      subagents: subagents,
      budget: budget,
      systemPrompt: systemPrompt,
      riskTier: riskTier,
      extendsSpec: extendsSpec,
    );
  }

  AgentSpec patchWithAgentSpec([AgentSpecPatch? patchInput]) {
    final _patcher = patchInput ?? AgentSpecPatch();
    final _patchMap = _patcher.patchMap;
    return AgentSpec(
      id: _patchMap.containsKey(AgentSpec$.id)
          ? ((_patchMap[AgentSpec$.id] is Function)
                    ? _patchMap[AgentSpec$.id](this.id)
                    : (_patchMap[AgentSpec$.id] is Patch)
                    ? _patchMap[AgentSpec$.id].applyTo(this.id)
                    : _patchMap[AgentSpec$.id])
                as String
          : this.id,
      tools: _patchMap.containsKey(AgentSpec$.tools)
          ? ((_patchMap[AgentSpec$.tools] is Function)
                    ? _patchMap[AgentSpec$.tools](this.tools)
                    : (_patchMap[AgentSpec$.tools] is Patch)
                    ? _patchMap[AgentSpec$.tools].applyTo(this.tools)
                    : _patchMap[AgentSpec$.tools])
                as List<String>
          : this.tools,
      subagents: _patchMap.containsKey(AgentSpec$.subagents)
          ? ((_patchMap[AgentSpec$.subagents] is Function)
                    ? _patchMap[AgentSpec$.subagents](this.subagents)
                    : (_patchMap[AgentSpec$.subagents] is Patch)
                    ? _patchMap[AgentSpec$.subagents].applyTo(this.subagents)
                    : _patchMap[AgentSpec$.subagents])
                as List<String>
          : this.subagents,
      budget: _patchMap.containsKey(AgentSpec$.budget)
          ? ((_patchMap[AgentSpec$.budget] is Function)
                    ? _patchMap[AgentSpec$.budget](this.budget)
                    : (_patchMap[AgentSpec$.budget] is Patch)
                    ? _patchMap[AgentSpec$.budget].applyTo(this.budget)
                    : _patchMap[AgentSpec$.budget])
                as String
          : this.budget,
      systemPrompt: _patchMap.containsKey(AgentSpec$.systemPrompt)
          ? ((_patchMap[AgentSpec$.systemPrompt] is Function)
                    ? _patchMap[AgentSpec$.systemPrompt](this.systemPrompt)
                    : (_patchMap[AgentSpec$.systemPrompt] is Patch)
                    ? _patchMap[AgentSpec$.systemPrompt].applyTo(
                        this.systemPrompt,
                      )
                    : _patchMap[AgentSpec$.systemPrompt])
                as String
          : this.systemPrompt,
      riskTier: _patchMap.containsKey(AgentSpec$.riskTier)
          ? ((_patchMap[AgentSpec$.riskTier] is Function)
                    ? _patchMap[AgentSpec$.riskTier](this.riskTier)
                    : (_patchMap[AgentSpec$.riskTier] is Patch)
                    ? _patchMap[AgentSpec$.riskTier].applyTo(this.riskTier)
                    : _patchMap[AgentSpec$.riskTier])
                as String
          : this.riskTier,
      extendsSpec: _patchMap.containsKey(AgentSpec$.extendsSpec)
          ? ((_patchMap[AgentSpec$.extendsSpec] is Function)
                    ? _patchMap[AgentSpec$.extendsSpec](this.extendsSpec)
                    : (_patchMap[AgentSpec$.extendsSpec] is Patch)
                    ? _patchMap[AgentSpec$.extendsSpec].applyTo(
                        this.extendsSpec,
                      )
                    : _patchMap[AgentSpec$.extendsSpec])
                as String
          : this.extendsSpec,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentSpec &&
        id == other.id &&
        tools == other.tools &&
        subagents == other.subagents &&
        budget == other.budget &&
        systemPrompt == other.systemPrompt &&
        riskTier == other.riskTier &&
        extendsSpec == other.extendsSpec;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.tools,
      this.subagents,
      this.budget,
      this.systemPrompt,
      this.riskTier,
      this.extendsSpec,
    );
  }

  @override
  String toString() {
    return 'AgentSpec(' +
        'id: ${id}' +
        ', ' +
        'tools: ${tools}' +
        ', ' +
        'subagents: ${subagents}' +
        ', ' +
        'budget: ${budget}' +
        ', ' +
        'systemPrompt: ${systemPrompt}' +
        ', ' +
        'riskTier: ${riskTier}' +
        ', ' +
        'extendsSpec: ${extendsSpec})';
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AgentSpecToJson(this);
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

extension AgentSpecPropertyHelpers on AgentSpec {
  bool get hasId {
    return this.id.isNotEmpty;
  }

  bool get noId {
    return this.id.isEmpty;
  }

  bool get hasTools {
    return this.tools.isNotEmpty;
  }

  bool get noTools {
    return this.tools.isEmpty;
  }

  bool get hasSubagents {
    return this.subagents.isNotEmpty;
  }

  bool get noSubagents {
    return this.subagents.isEmpty;
  }

  bool get hasBudget {
    return this.budget.isNotEmpty;
  }

  bool get noBudget {
    return this.budget.isEmpty;
  }

  bool get hasSystemPrompt {
    return this.systemPrompt.isNotEmpty;
  }

  bool get noSystemPrompt {
    return this.systemPrompt.isEmpty;
  }

  bool get hasRiskTier {
    return this.riskTier.isNotEmpty;
  }

  bool get noRiskTier {
    return this.riskTier.isEmpty;
  }

  bool get hasExtendsSpec {
    return this.extendsSpec.isNotEmpty;
  }

  bool get noExtendsSpec {
    return this.extendsSpec.isEmpty;
  }
}

extension AgentSpecSerialization on AgentSpec {
  Map<String, dynamic> toJson() {
    return _$AgentSpecToJson(this);
  }
}

enum AgentSpec$ {
  id,
  tools,
  subagents,
  budget,
  systemPrompt,
  riskTier,
  extendsSpec,
}

class AgentSpecPatch extends PatchBase<AgentSpec, AgentSpec$> {
  AgentSpec applyTo(AgentSpec entity) {
    return entity.patchWithAgentSpec(this);
  }

  AgentSpecPatch withId(String? value) {
    patchMap[AgentSpec$.id] = value;
    return this;
  }

  AgentSpecPatch withTools(List<String>? value) {
    patchMap[AgentSpec$.tools] = value;
    return this;
  }

  AgentSpecPatch withSubagents(List<String>? value) {
    patchMap[AgentSpec$.subagents] = value;
    return this;
  }

  AgentSpecPatch withBudget(String? value) {
    patchMap[AgentSpec$.budget] = value;
    return this;
  }

  AgentSpecPatch withSystemPrompt(String? value) {
    patchMap[AgentSpec$.systemPrompt] = value;
    return this;
  }

  AgentSpecPatch withRiskTier(String? value) {
    patchMap[AgentSpec$.riskTier] = value;
    return this;
  }

  AgentSpecPatch withExtendsSpec(String? value) {
    patchMap[AgentSpec$.extendsSpec] = value;
    return this;
  }
}

/// Field descriptors for [AgentSpec] query construction
abstract final class AgentSpecFields {
  static const id = Field<AgentSpec, String>('id', _$id);

  static const tools = Field<AgentSpec, List<String>>('tools', _$tools);

  static const subagents = Field<AgentSpec, List<String>>(
    'subagents',
    _$subagents,
  );

  static const budget = Field<AgentSpec, String>('budget', _$budget);

  static const systemPrompt = Field<AgentSpec, String>(
    'systemPrompt',
    _$systemPrompt,
  );

  static const riskTier = Field<AgentSpec, String>('riskTier', _$riskTier);

  static const extendsSpec = Field<AgentSpec, String>(
    'extendsSpec',
    _$extendsSpec,
  );

  static String _$id(AgentSpec e) {
    return e.id;
  }

  static List<String> _$tools(AgentSpec e) {
    return e.tools;
  }

  static List<String> _$subagents(AgentSpec e) {
    return e.subagents;
  }

  static String _$budget(AgentSpec e) {
    return e.budget;
  }

  static String _$systemPrompt(AgentSpec e) {
    return e.systemPrompt;
  }

  static String _$riskTier(AgentSpec e) {
    return e.riskTier;
  }

  static String _$extendsSpec(AgentSpec e) {
    return e.extendsSpec;
  }
}

extension AgentSpecCompareE on AgentSpec {
  Map<String, dynamic> compareToAgentSpec(AgentSpec other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }

    if (tools != other.tools) {
      diff['tools'] = () => other.tools;
    }

    if (subagents != other.subagents) {
      diff['subagents'] = () => other.subagents;
    }

    if (budget != other.budget) {
      diff['budget'] = () => other.budget;
    }

    if (systemPrompt != other.systemPrompt) {
      diff['systemPrompt'] = () => other.systemPrompt;
    }

    if (riskTier != other.riskTier) {
      diff['riskTier'] = () => other.riskTier;
    }

    if (extendsSpec != other.extendsSpec) {
      diff['extendsSpec'] = () => other.extendsSpec;
    }
    return diff;
  }
}
