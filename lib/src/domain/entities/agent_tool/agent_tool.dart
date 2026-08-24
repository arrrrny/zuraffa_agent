// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 — tools & MCP client).
//
// The AgentTool value object + RiskTier / ExecutionMode enums — spec-exact
// from epic #1 §R3.1 + §R3.2 (issue #4 body):
//   R3.1 "Tool model seeded from pi_agent (typed params, JSON-Schema
//        validation at dispatch, sequential/parallel execution modes) —
//        registry-backed"
//   R3.2 "Risk metadata first-class on AgentTool: safe|confirm|admin
//        (supersedes arrrrny/dart_agent_core#3)."
//
// The repo already ships ToolResult (PR #49, the runtime result of a
// dispatch) and ToolCallSignature (PR #44/#46, the call-site signature).
// This file is the **declaration** — the static, registered tool metadata
// (id + description + risk tier + params schema) the registry holds and
// the engine dispatches against.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), and StopPolicy (PR #47).

/// Risk classification for an [AgentTool] — supersedes
/// arrrrny/dart_agent_core#3 (R3.2).
///
/// - [safe] — read-only / idempotent; the engine dispatches without
///   confirmation.
/// - [confirm] — requires a user approval callback before dispatch
///   (e.g. destructive fs writes, sending email).
/// - [admin] — operator-only; requires an admin grant in the active
///   mission's policy. The engine refuses to dispatch admin tools
///   when no admin grant is present.
enum RiskTier {
  safe,
  confirm,
  admin;

  /// Numeric severity ordering: 0 (safe) < 1 (confirm) < 2 (admin).
  /// Useful for sorting tool lists by risk and for policy comparisons.
  int get severity => switch (this) {
        RiskTier.safe => 0,
        RiskTier.confirm => 1,
        RiskTier.admin => 2,
      };

  /// True for [confirm] and [admin] — the engine must pause dispatch
  /// and request an approval callback before running the tool.
  bool get requiresConfirmation => this != RiskTier.safe;

  /// True only for [admin] — the engine refuses to dispatch without an
  /// admin grant.
  bool get isAdmin => this == RiskTier.admin;
}

/// Execution mode for an [AgentTool] — R3.1 "sequential/parallel execution
/// modes".
///
/// - [sequential] — the engine dispatches one tool call at a time; the
///   result is appended to the running turn before the next call.
/// - [parallel] — the engine may batch-dispatch this tool alongside other
///   parallel tools in the same turn (e.g. web crawl with N fetchers).
enum ExecutionMode {
  sequential,
  parallel;
}

/// AgentTool value object (declaration).
///
/// The static registration of a tool in the registry: its unique [id],
/// human-readable [description] (surfaces in tool-selection prompts to
/// the model), risk classification [riskTier], execution mode
/// [executionMode], and optional JSON Schema [paramsSchema] for typed
/// params validation at dispatch (R3.1).
///
/// The registry holds `AgentTool` instances; the engine dispatches against
/// them by id. Dispatch-time validation: the params passed in the
/// `ToolCallSignature` are validated against [paramsSchema] before the
/// tool runs (R3.1); risk-tier policy is enforced by the dispatcher (R3.2
/// — `confirm` tools defer to the approval callback, `admin` tools require
/// an admin grant).
class AgentTool {
  /// Unique tool identifier (e.g. `"fs.read"`, `"web.fetch"`,
  /// `"fs.write"`). The registry namespaces in-proc tools, plugin tools,
  /// and remote MCP tools into one namespace (R3.1) — collisions are
  /// rejected at registration time.
  final String id;

  /// Human-readable description of what the tool does. The engine
  /// surfaces this in tool-selection prompts to the model.
  final String description;

  /// Risk classification — controls dispatch policy (R3.2). Defaults
  /// to [RiskTier.safe] when the producer doesn't specify.
  final RiskTier riskTier;

  /// Execution mode — controls whether the engine may batch-dispatch
  /// this tool with others in the same turn (R3.1). Defaults to
  /// [ExecutionMode.sequential].
  final ExecutionMode executionMode;

  /// Optional JSON Schema for typed-params validation at dispatch
  /// (R3.1). Null when the tool takes no params. When non-null, the
  /// dispatcher validates the call-site params against this schema
  /// before the tool runs; mismatches produce typed errors and never
  /// reach the tool implementation.
  final Map<String, dynamic>? paramsSchema;

  const AgentTool({
    required this.id,
    required this.description,
    this.riskTier = RiskTier.safe,
    this.executionMode = ExecutionMode.sequential,
    this.paramsSchema,
  });

  /// True when this tool requires a user approval callback before
  /// dispatch — delegates to [RiskTier.requiresConfirmation].
  bool get requiresConfirmation => riskTier.requiresConfirmation;

  /// True when this tool is admin-only — delegates to
  /// [RiskTier.isAdmin].
  bool get isAdmin => riskTier.isAdmin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentTool &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          riskTier == other.riskTier &&
          executionMode == other.executionMode &&
          _mapEq(paramsSchema, other.paramsSchema));

  static bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEq(a[key], b[key])) return false;
    }
    return true;
  }

  static bool _deepEq(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      return _mapEq(a as Map<String, dynamic>?, b as Map<String, dynamic>?);
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEq(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(id, description, riskTier, executionMode, paramsSchema);

  @override
  String toString() =>
      'AgentTool(id: $id, description: ${description.length > 40 ? "${description.substring(0, 40)}…" : description}, riskTier: $riskTier, executionMode: $executionMode, paramsSchema: ${paramsSchema == null ? "null" : "present"})';
}
