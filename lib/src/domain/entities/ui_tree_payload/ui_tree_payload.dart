// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (UI/tree+json payloads).
//
// The UiTreePayload value object — spec-exact from epic #1 §8.1
// (issue #8 body: "Payload typing: tool results and final mission
// outputs accept a structured content type ui/tree+json (tree +
// schemaVersion + vocabularyId); stored as ToolInvocation /
// TurnRecord payloads in the session tree (spec 002 entities) —
// replayable").
//
// The repo already ships ToolResult (PR #49) and the TurnRecord /
// ToolInvocation entities; this file is the structured payload type
// that gets embedded in ToolResult.structuredPayload (or as a final
// mission output) — a typed UI tree the plugin/app renders later.
//
// The engine stays UI-framework-agnostic (per issue #8: "Engine core
// imports no Flutter/UI packages"). This value object carries the tree
// as a plain JSON-compatible Map — the plugin resolves the vocabulary
// and renders the nodes.
//
// Pattern: plain Dart value object (no @Zorphy annotation) so the file
// compiles without running build_runner, same as AgentSession (PR #50),
// ToolResult (PR #49), AgentTool (PR #52), CircuitBreaker (PR #53),
// SubAgentSpec (PR #54), and PassAtK (PR #55).

/// UiTreePayload value object — the `ui/tree+json` structured content
/// type.
///
/// Carries a typed UI tree the plugin/app renders later. The engine
/// stays UI-framework-agnostic: this value object carries the tree as
/// a plain JSON-compatible [tree] Map plus its [vocabularyId] (which
/// vocabulary the tree uses, e.g. `"shadcn-ui@1.0.0"`) and
/// [schemaVersion] (which version of the tree schema).
///
/// The [depth] and [nodeCount] fields are precomputed at construction
/// (via [computeDepth] / [computeNodeCount]) so budget checks (§8.3 —
/// tree size/depth caps) are O(1) lookups, not tree walks.
class UiTreePayload {
  /// MIME type constant for ui/tree+json payloads. Always
  /// `"ui/tree+json"`. Used for explicit content-type tagging when
  /// payloads cross process boundaries (e.g. MCP tool results).
  static const String mimeType = 'ui/tree+json';

  /// Vocabulary id pinning this tree to a specific component vocabulary
  /// (e.g. `"shadcn-ui@1.0.0"`). The plugin resolves the vocabulary
  /// and renders nodes from it. Spec `ui:` section (§8.2) may narrow
  /// the allowed vocabularies; the engine rejects trees outside the
  /// pin with typed errors.
  final String vocabularyId;

  /// Version of the tree schema itself (e.g. `"1.0.0"`). Independent
  /// of [vocabularyId] — the schema describes the tree-shape contract
  /// (node fields, children-key name, etc.).
  final String schemaVersion;

  /// The tree root node — a plain JSON-compatible Map. The engine
  /// does not interpret the tree; it carries, versions, records, and
  /// gates it. The plugin is responsible for resolving the vocabulary
  /// and rendering the nodes.
  final Map<String, dynamic> tree;

  /// Precomputed tree depth (max depth of any path from root to leaf).
  /// A leaf node (no children) has depth 1. Used by budget caps (§8.3)
  /// for O(1) lookup.
  final int depth;

  /// Precomputed node count (total nodes in the tree, root included).
  /// Used by budget caps (§8.3) for O(1) lookup.
  final int nodeCount;

  UiTreePayload({
    required this.vocabularyId,
    required this.schemaVersion,
    required this.tree,
  })  : depth = computeDepth(tree),
        nodeCount = computeNodeCount(tree) {
    if (vocabularyId.isEmpty) {
      throw ArgumentError.value(vocabularyId, 'vocabularyId', 'must not be empty');
    }
    if (schemaVersion.isEmpty) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion', 'must not be empty');
    }
  }

  /// Compute the max depth of a tree node. A leaf node (no `children`
  /// key or empty children list) has depth 1. The recursive walk uses
  /// the conventional `children` key (a `List` of `Map<String, dynamic>`).
  static int computeDepth(Map<String, dynamic> tree) {
    final children = tree['children'];
    if (children is! List || children.isEmpty) {
      return 1;
    }
    var maxChildDepth = 0;
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final d = computeDepth(child);
        if (d > maxChildDepth) maxChildDepth = d;
      }
    }
    return maxChildDepth == 0 ? 1 : 1 + maxChildDepth;
  }

  /// Compute the total node count of a tree (root included). The
  /// recursive walk uses the conventional `children` key.
  static int computeNodeCount(Map<String, dynamic> tree) {
    final children = tree['children'];
    if (children is! List || children.isEmpty) {
      return 1;
    }
    var count = 1;
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        count += computeNodeCount(child);
      }
    }
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiTreePayload &&
          runtimeType == other.runtimeType &&
          vocabularyId == other.vocabularyId &&
          schemaVersion == other.schemaVersion &&
          _mapEq(tree, other.tree) &&
          depth == other.depth &&
          nodeCount == other.nodeCount);

  static bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
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
      return _mapEq(a as Map<String, dynamic>, b as Map<String, dynamic>);
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

  // Note: tree is excluded from hashCode — deep hashing a JSON Map is
  // non-trivial and collisions on the scalar fields (vocabularyId +
  // schemaVersion + depth + nodeCount) are acceptable per Dart's
  // hashCode contract. Equality still works correctly via the deep
  // _mapEq above; this just means hash-based data structures may have
  // more collisions, which is fine for an immutable value object.
  @override
  int get hashCode =>
      Object.hash(vocabularyId, schemaVersion, depth, nodeCount);

  @override
  String toString() =>
      'UiTreePayload(vocabularyId: $vocabularyId, schemaVersion: $schemaVersion, '
      'depth: $depth, nodeCount: $nodeCount, mimeType: $mimeType)';
}
