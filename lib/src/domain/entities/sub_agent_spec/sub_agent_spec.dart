// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 — sub-agents & specs).
//
// The SubAgentSpec value object — spec-exact from epic #1 §R5.2
// (issue #6 body: "Declarative agent specs (YAML, `extends` inheritance):
// tools, sub-agents, budgets, system prompt, risk tier — specs are
// data"). Reuses RiskTier from PR #52 (AgentTool + RiskTier +
// ExecutionMode).
//
// The repo already ships AgentTool (PR #52, the static tool declaration)
// and the RiskTier enum (safe/confirm/admin). This file is the
// declarative spec for a sub-agent — the data structure that captures
// name + description + systemPrompt + extends + tools allowlist +
// subAgents + riskTier + budgets. The spec loader (YAML parser +
// extends resolution) and the dispatch (Kimi LaborMarket pattern,
// isolated context windows) are downstream concerns that build on
// this surface.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), AgentTool (PR #52), and CircuitBreaker (PR #53).

import '../agent_tool/agent_tool.dart' show RiskTier;

/// SubAgentSpec value object (declarative).
///
/// Captures a sub-agent's declarative spec: its unique [name] (e.g.
/// `"explore"` / `"compose"` / `"verify"`, per R5.1 "named agent types"),
/// its [systemPrompt], the [extends] parent spec name for inheritance
/// (R5.2 "extends"), the [tools] allowlist of tool ids (R5.1 "own tool
/// allowlists"), the [subAgents] allowlist of sub-agent spec names this
/// agent may dispatch (R5.1 "isolated-context dispatch"), the [riskTier]
/// (reuses RiskTier from PR #52), and the budgets [maxTurns] /
/// [wallClockTimeout] / [contextWindowTokens] (R5.1 "isolated context
/// windows").
class SubAgentSpec {
  /// Unique spec name (e.g. "explore", "compose", "verify"). The loader
  /// keys specs by this name; `extends` references it.
  final String name;

  /// Human-readable description of what the sub-agent does. Used in
  /// tool-selection prompts and in spec-debugging UI.
  final String description;

  /// System prompt fed to the LLM as the system role when the sub-agent
  /// runs. May reference template variables the loader substitutes at
  /// dispatch time.
  final String systemPrompt;

  /// Optional parent spec name for inheritance (R5.2 "extends"). Null
  /// for a root spec. The loader resolves inheritance by walking
  /// `extends` chains and merging tools/subAgents/budgets (child
  /// overrides parent).
  final String? extendsSpec;

  /// Allowlist of tool ids the sub-agent may dispatch (R5.1 "own tool
  /// allowlists"). May be empty — the agent has no tool access. The
  /// engine refuses to dispatch a tool not in this list (unless the
  /// parent spec's allowlist applies via `extends`).
  final List<String> tools;

  /// Allowlist of sub-agent spec names this agent may dispatch (R5.1
  /// "isolated-context dispatch"). Empty for a leaf agent (cannot
  /// dispatch sub-agents).
  final List<String> subAgents;

  /// Risk tier for the spec (reuses RiskTier from PR #52). Defaults to
  /// [RiskTier.safe]. The engine refuses to dispatch admin-risk sub-agents
  /// without an admin grant in the active mission's policy.
  final RiskTier riskTier;

  /// Turn budget — max engine turns the sub-agent may run before being
  /// auto-stopped. Null means inherit from parent spec (or no limit if
  /// the spec is a root with no budget).
  final int? maxTurns;

  /// Wall-clock budget — max elapsed time the sub-agent may run before
  /// being auto-stopped. Null means inherit from parent spec (or no
  /// limit). `Duration.zero` means no wall-clock limit (only maxTurns
  /// applies, if set).
  final Duration? wallClockTimeout;

  /// Context window size in tokens (R5.1 "isolated context windows").
  /// Null means inherit from parent spec (or use the engine default).
  final int? contextWindowTokens;

  SubAgentSpec({
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.extendsSpec,
    this.tools = const [],
    this.subAgents = const [],
    this.riskTier = RiskTier.safe,
    this.maxTurns,
    this.wallClockTimeout,
    this.contextWindowTokens,
  }) {
    // Construction-time validation (spec 036, FR-001): identity fields
    // must be non-empty. Invalid specs fail fast at load time instead of
    // misbehaving at dispatch time.
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (description.isEmpty) {
      throw ArgumentError.value(description, 'description', 'must not be empty');
    }
    if (systemPrompt.isEmpty) {
      throw ArgumentError.value(
          systemPrompt, 'systemPrompt', 'must not be empty');
    }
    // FR-002 (spec 036): allowlist ids must be non-blank — a blank id in a
    // YAML-loaded allowlist is loader drift that would silently widen or
    // corrupt dispatch checks.
    if (tools.any((id) => id.isEmpty)) {
      throw ArgumentError.value(tools, 'tools',
          'must not contain blank tool ids');
    }
    if (subAgents.any((id) => id.isEmpty)) {
      throw ArgumentError.value(subAgents, 'subAgents',
          'must not contain blank sub-agent ids');
    }
  }

  /// True for a leaf agent — cannot dispatch sub-agents ([subAgents]
  /// is empty).
  bool get isLeaf => subAgents.isEmpty;

  /// True for a root spec — not inheriting from any parent
  /// ([extendsSpec] is null).
  bool get isRoot => extendsSpec == null;

  /// True when the spec defines at least one budget (maxTurns,
  /// wallClockTimeout, or contextWindowTokens). Useful for validation:
  /// a non-root spec with no budgets and no parent budgets is
  /// ill-formed.
  bool get hasBudgets =>
      maxTurns != null || wallClockTimeout != null || contextWindowTokens != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubAgentSpec &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          systemPrompt == other.systemPrompt &&
          extendsSpec == other.extendsSpec &&
          _listEq(tools, other.tools) &&
          _listEq(subAgents, other.subAgents) &&
          riskTier == other.riskTier &&
          maxTurns == other.maxTurns &&
          wallClockTimeout == other.wallClockTimeout &&
          contextWindowTokens == other.contextWindowTokens);

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        systemPrompt,
        extendsSpec,
        Object.hashAll(tools),
        Object.hashAll(subAgents),
        riskTier,
        maxTurns,
        wallClockTimeout,
        contextWindowTokens,
      );

  @override
  String toString() =>
      'SubAgentSpec(name: $name, extendsSpec: $extendsSpec, '
      'tools: ${tools.length}, subAgents: ${subAgents.length}, '
      'riskTier: $riskTier, maxTurns: $maxTurns, '
      'wallClockTimeout: $wallClockTimeout, '
      'contextWindowTokens: $contextWindowTokens)';
}
