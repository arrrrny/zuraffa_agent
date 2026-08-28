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

  /// Serialize to the ui/tree+json contract map (spec 038 FR-001): exactly
  /// `mimeType`, `vocabularyId`, `schemaVersion`, `tree`. Callers own
  /// jsonEncode when crossing a string wire.
  Map<String, dynamic> toJson() => {
        'mimeType': mimeType,
        'vocabularyId': vocabularyId,
        'schemaVersion': schemaVersion,
        'tree': tree,
      };

  /// Parse a ui/tree+json contract map (spec 038 FR-002). The mimeType is
  /// part of the contract, not a hint: absent or different throws
  /// [ArgumentError] naming `mimeType`. Empty pinning fields and a non-map
  /// tree throw naming the offending field. Unknown top-level keys are
  /// ignored (forward compatibility). Constructs through the standard
  /// constructor so validation and depth/nodeCount precomputation apply —
  /// `fromJson(toJson(p)) == p`.
  factory UiTreePayload.fromJson(Map<String, dynamic> json) {
    final parsedMime = json['mimeType'];
    if (parsedMime is! String || parsedMime != mimeType) {
      throw ArgumentError.value(parsedMime, 'mimeType',
          'must be present and equal to "$mimeType"');
    }
    final parsedVocab = json['vocabularyId'];
    if (parsedVocab is! String) {
      throw ArgumentError.value(
          parsedVocab, 'vocabularyId', 'must be a non-empty string');
    }
    final parsedSchema = json['schemaVersion'];
    if (parsedSchema is! String) {
      throw ArgumentError.value(
          parsedSchema, 'schemaVersion', 'must be a non-empty string');
    }
    final parsedTree = json['tree'];
    if (parsedTree is! Map<String, dynamic>) {
      throw ArgumentError.value(
          parsedTree, 'tree', 'must be a Map<String, dynamic>');
    }
    return UiTreePayload(
      vocabularyId: parsedVocab,
      schemaVersion: parsedSchema,
      tree: parsedTree,
    );
  }

  /// Structural diff against [other] (spec 038 FR-003): a path-keyed delta
  /// plus pinning-drift flags. Children are compared POSITIONALLY (child-list
  /// index paths like `root/0/1`); a node difference at a shared path is a
  /// change, not an add+remove pair. See [UiTreeDiff].
  UiTreeDiff diff(UiTreePayload other) {
    final added = <String>[];
    final removed = <String>[];
    final changed = <String>[];
    _diffNodes('root', tree, other.tree, added, removed, changed);
    // Emit lexically-sorted path lists so diffs are deterministic and stable
    // for replay artifacts (per UiTreePayload/UiTreeDiff contract), independent
    // of the positional traversal order produced by _diffNodes.
    added.sort();
    removed.sort();
    changed.sort();
    return UiTreeDiff(
      addedPaths: added,
      removedPaths: removed,
      changedPaths: changed,
      vocabularyChanged: vocabularyId != other.vocabularyId,
      schemaChanged: schemaVersion != other.schemaVersion,
    );
  }

  static void _diffNodes(
    String path,
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
    List<String> added,
    List<String> removed,
    List<String> changed,
  ) {
    if (a == null && b == null) return;
    if (a == null) {
      added.add(path);
      _collectPaths(path, b!, added);
      return;
    }
    if (b == null) {
      removed.add(path);
      _collectPaths(path, a, removed);
      return;
    }
    // Minimal-anchor semantics: a node is "changed" only when its OWN
    // payload (everything except the `children` key) differs. Descendant
    // changes are reported at their own paths and never bubble up to
    // ancestors — the diff's path set stays the smallest set of anchors
    // that explains the whole delta.
    if (!_ownPayloadEq(a, b)) {
      changed.add(path);
    }
    final childrenA = _childrenOf(a);
    final childrenB = _childrenOf(b);
    final max =
        childrenA.length > childrenB.length ? childrenA.length : childrenB.length;
    for (var i = 0; i < max; i++) {
      final childA = i < childrenA.length ? childrenA[i] : null;
      final childB = i < childrenB.length ? childrenB[i] : null;
      if (childA == null && childB == null) continue;
      _diffNodes('$path/$i', childA, childB, added, removed, changed);
    }
  }

  static List<Map<String, dynamic>> _childrenOf(Map<String, dynamic> node) {
    final children = node['children'];
    if (children is! List) return const [];
    return [
      for (final child in children)
        if (child is Map<String, dynamic>) child
    ];
  }

  /// Deep equality of a node's own payload — every key except `children`.
  static bool _ownPayloadEq(Map<String, dynamic> a, Map<String, dynamic> b) {
    final keysA = [
      for (final k in a.keys)
        if (k != 'children') k
    ]..sort();
    final keysB = [
      for (final k in b.keys)
        if (k != 'children') k
    ]..sort();
    if (keysA.length != keysB.length) return false;
    for (var i = 0; i < keysA.length; i++) {
      final key = keysA[i];
      if (key != keysB[i]) return false;
      if (!_deepEq(a[key], b[key])) return false;
    }
    return true;
  }

  static void _collectPaths(
    String path,
    Map<String, dynamic> node,
    List<String> into,
  ) {
    final children = _childrenOf(node);
    for (var i = 0; i < children.length; i++) {
      final childPath = '$path/$i';
      into.add(childPath);
      _collectPaths(childPath, children[i], into);
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

/// Path-keyed structural delta between two [UiTreePayload]s (spec 038
/// FR-004). Produced by [UiTreePayload.diff]; never constructed by hand
/// outside tests.
///
/// Paths are child-index chains: `'root'` for the tree root, `'root/0/1'`
/// for the second child of the first child. Children are compared
/// positionally — an add at the end of a child list shifts nothing, but an
/// insert in the middle surfaces as a run of changed paths (recorded here
/// as changes, not add/remove pairs; a future keyed-by-id diff can build
/// on the same walk if node ids enter the vocabulary contract).
class UiTreeDiff {
  /// Paths present in the other payload's tree, absent in this one.
  final List<String> addedPaths;

  /// Paths present in this payload's tree, absent in the other one.
  final List<String> removedPaths;

  /// Paths present in both trees whose node maps are deep-unequal.
  final List<String> changedPaths;

  /// True when the two payloads pin different vocabularies.
  final bool vocabularyChanged;

  /// True when the two payloads carry different schema versions.
  final bool schemaChanged;

  const UiTreeDiff({
    required this.addedPaths,
    required this.removedPaths,
    required this.changedPaths,
    required this.vocabularyChanged,
    required this.schemaChanged,
  });

  /// Any structural or pinning difference at all.
  bool get hasChanges =>
      addedPaths.isNotEmpty ||
      removedPaths.isNotEmpty ||
      changedPaths.isNotEmpty ||
      vocabularyChanged ||
      schemaChanged;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiTreeDiff &&
          runtimeType == other.runtimeType &&
          _listEq(addedPaths, other.addedPaths) &&
          _listEq(removedPaths, other.removedPaths) &&
          _listEq(changedPaths, other.changedPaths) &&
          vocabularyChanged == other.vocabularyChanged &&
          schemaChanged == other.schemaChanged);

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
        Object.hashAll(addedPaths),
        Object.hashAll(removedPaths),
        Object.hashAll(changedPaths),
        vocabularyChanged,
        schemaChanged,
      );

  @override
  String toString() =>
      'UiTreeDiff(+${addedPaths.length}, -${removedPaths.length}, '
      '~${changedPaths.length}, vocab: $vocabularyChanged, '
      'schema: $schemaChanged)';
}
