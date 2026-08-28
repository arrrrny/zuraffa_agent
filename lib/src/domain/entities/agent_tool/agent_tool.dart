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
//
// Refined under specs/034-agent-tool-risk-tier (TDD): the classification +
// registry semantics the task names — RiskTier.fromString / ExecutionMode.
// fromString (exact-match parse with typed ArgumentError: an unknown tier
// never silently becomes safe — under-classification is the failure mode
// the approval layer exists to prevent), toJson/fromJson (tier/mode as
// names, deep schema copy, absent-never-fabricated optionals), and the
// hashCode contract fix: the scaffold passed paramsSchema through
// Object.hash, which hashes the Map by identity, so equal tools with
// distinct-but-equal schema instances hashed differently (probe-verified
// live violation); the refinement folds the schema recursively and
// order-independently (commutative sum over map entries; arrays folded
// order-sensitively — JSON-Schema arrays are ordered).

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

  /// Parses a tier from its declaration string ('safe' / 'confirm' /
  /// 'admin' — exact match, case-significant). Throws [ArgumentError]
  /// carrying [value] for anything else: an unknown tier is a typed
  /// failure, never a silent [RiskTier.safe] fallback that would
  /// under-classify a dangerous tool.
  static RiskTier fromString(String value) => switch (value) {
        'safe' => RiskTier.safe,
        'confirm' => RiskTier.confirm,
        'admin' => RiskTier.admin,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown RiskTier — expected safe, confirm or admin'),
      };
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

  /// Parses a mode from its declaration string ('sequential' /
  /// 'parallel' — exact match). Throws [ArgumentError] for anything
  /// else — same typed-failure discipline as [RiskTier.fromString].
  static ExecutionMode fromString(String value) => switch (value) {
        'sequential' => ExecutionMode.sequential,
        'parallel' => ExecutionMode.parallel,
        _ => throw ArgumentError.value(
            value, 'value', 'unknown ExecutionMode — expected sequential or parallel'),
      };
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

  /// Serializes the declaration to a JSON map (registry persistence
  /// contract): `id`, `description`, `riskTier` (tier name),
  /// `executionMode` (mode name) always; `paramsSchema` only when
  /// present (absent-never-fabricated).
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'description': description,
      'riskTier': riskTier.name,
      'executionMode': executionMode.name,
    };
    if (paramsSchema != null) json['paramsSchema'] = paramsSchema;
    return json;
  }

  /// Parses an [AgentTool] from its JSON shape (see [toJson]).
  /// Round-trips all five fields — the tier and mode route through
  /// [RiskTier.fromString] / [ExecutionMode.fromString] (single source
  /// of truth: an unknown tier in JSON fails exactly like an unknown
  /// tier in a declaration), and the schema is deep-copied. Throws
  /// [ArgumentError] naming the field on missing required keys, unknown
  /// tier/mode strings, or a non-map schema — never a silent default.
  factory AgentTool.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String) {
      throw ArgumentError.value(idRaw, 'id', 'AgentTool.id must be a non-null string');
    }
    final descriptionRaw = json['description'];
    if (descriptionRaw is! String) {
      throw ArgumentError.value(descriptionRaw, 'description', 'AgentTool.description must be a non-null string');
    }
    RiskTier tier;
    final tierRaw = json['riskTier'] ?? 'safe';
    if (tierRaw is! String) {
      throw ArgumentError.value(tierRaw, 'riskTier', 'AgentTool.riskTier must be a tier-name string');
    }
    try {
      tier = RiskTier.fromString(tierRaw);
    } on ArgumentError catch (e) {
      throw ArgumentError.value(e.invalidValue, 'riskTier', 'AgentTool.riskTier: ${e.message}');
    }
    ExecutionMode mode;
    final modeRaw = json['executionMode'] ?? 'sequential';
    if (modeRaw is! String) {
      throw ArgumentError.value(modeRaw, 'executionMode', 'AgentTool.executionMode must be a mode-name string');
    }
    try {
      mode = ExecutionMode.fromString(modeRaw);
    } on ArgumentError catch (e) {
      throw ArgumentError.value(e.invalidValue, 'executionMode', 'AgentTool.executionMode: ${e.message}');
    }
    Map<String, dynamic>? schema;
    final schemaRaw = json['paramsSchema'];
    if (schemaRaw != null) {
      if (schemaRaw is! Map) {
        throw ArgumentError.value(schemaRaw, 'paramsSchema', 'AgentTool.paramsSchema must be a JSON object when present');
      }
      schema = Map<String, dynamic>.from(schemaRaw);
    }
    return AgentTool(
      id: idRaw,
      description: descriptionRaw,
      riskTier: tier,
      executionMode: mode,
      paramsSchema: schema,
    );
  }

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

  /// Hash consistent with [==] (which deep-compares the schema through
  /// `_mapEq`): `Object.hash` over the scalar fields plus a recursive,
  /// order-independent fold over the params schema. The scaffold passed
  /// the schema Map through `Object.hash`, which hashes Maps by identity —
  /// equal tools with distinct-but-equal schema instances hashed
  /// differently (a live ==/hashCode contract violation, probe-verified).
  /// Map entries fold through a commutative sum (insertion order cannot
  /// change the result); nested maps recurse; arrays fold entry-wise and
  /// order-sensitively (JSON-Schema arrays are ordered).
  @override
  int get hashCode => Object.hash(
        id,
        description,
        riskTier,
        executionMode,
        _foldHash(paramsSchema),
      );

  /// Order-independent hash of a (possibly nested) schema value: maps
  /// fold as a commutative sum of per-entry hashes, lists fold
  /// entry-wise in order, scalars hash directly, null folds to 0.
  static int _foldHash(Object? value) {
    if (value == null) return 0;
    if (value is Map) {
      var sum = 0;
      for (final entry in value.entries) {
        // Sum is commutative: insertion order cannot change the result.
        sum += Object.hash(entry.key, _foldHash(entry.value));
      }
      return sum;
    }
    if (value is List) {
      var sum = 0;
      for (var i = 0; i < value.length; i++) {
        // Order-sensitive: JSON-Schema arrays are ordered.
        sum += Object.hash(i, _foldHash(value[i]));
      }
      return sum;
    }
    return value.hashCode;
  }

  @override
  String toString() =>
      'AgentTool(id: $id, description: ${description.length > 40 ? "${description.substring(0, 40)}…" : description}, riskTier: $riskTier, executionMode: $executionMode, paramsSchema: ${paramsSchema == null ? "null" : "present"})';
}
