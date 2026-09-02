// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI).
//
// UiSpec value object — the `ui:` section of an agent spec (issue #8 §2:
// "Vocabulary pinning in specs"). Plain Dart value object, no @Zorphy
// codegen, compiles without build_runner — same pattern as YamlAgentSpec,
// UiTreePayload, and the other hand-curated value objects in this repo.
//
// The engine stays UI-framework-agnostic (issue #8 §6 + AC-5): this value
// object carries the spec-side pin only. The plugin resolves the
// vocabulary, renders the nodes, and enforces the pin against emitted
// trees (the engine rejects trees outside the pin with typed errors per
// AC-2 — see [UiVocabularyPinError] and [UiSpec.validatePayload]).

import '../ui_tree_payload/ui_tree_payload.dart';

/// UI tree shape caps — issue #8 §2: `caps?: {depth, nodes}`.
///
/// Both fields are nullable so an agent spec can pin only one dimension
/// (e.g. depth but not node count). A `null` cap means "no cap on this
/// dimension"; the enforcer skips the check for that dimension.
class UiCaps {
  /// Maximum tree depth (root inclusive; a leaf has depth 1).
  final int? depth;

  /// Maximum total node count (root inclusive).
  final int? nodes;

  const UiCaps({this.depth, this.nodes});

  /// Returns `true` when at least one dimension is capped.
  bool get hasAnyCap => depth != null || nodes != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiCaps &&
          runtimeType == other.runtimeType &&
          depth == other.depth &&
          nodes == other.nodes);

  @override
  int get hashCode => Object.hash(depth, nodes);

  @override
  String toString() => 'UiCaps(depth: $depth, nodes: $nodes)';
}

/// The `ui:` section of an agent spec — issue #8 §2.
///
/// Pins the vocabulary a mission may emit (`vocabulary`), optionally
/// narrows the allowed components (`allowedComponents`), and optionally
/// caps tree shape (`caps`). The engine rejects [UiTreePayload]s that
/// fall outside the pin with typed [UiVocabularyPinError]s (see
/// [validatePayload]).
class UiSpec {
  /// Vocabulary id pinning the mission to a specific component vocabulary,
  /// e.g. `"shadcn-ui@1.0.0"`. Matched against [UiTreePayload.vocabularyId].
  final String vocabulary;

  /// Optional allowlist of component `type` values the mission may emit.
  /// When empty/null, any component type is allowed (the vocabulary alone
  /// governs). When non-empty, a tree whose node `type` is not in the list
  /// is rejected.
  final List<String>? allowedComponents;

  /// Optional tree shape caps. See [UiCaps].
  final UiCaps? caps;

  UiSpec({required this.vocabulary, this.allowedComponents, this.caps}) {
    if (vocabulary.isEmpty) {
      throw ArgumentError.value(vocabulary, 'vocabulary', 'must not be empty');
    }
  }

  /// Validate [payload] against this spec pin (issue #8 AC-2).
  ///
  /// Returns the list of typed errors (empty when the payload is in-pin).
  /// Each error is a [UiVocabularyPinError] carrying the offending field
  /// and a human-readable reason. The engine calls this at the tool-result
  /// boundary; the plugin calls it before rendering.
  ///
  /// Checks (in order):
  /// 1. [UiTreePayload.vocabularyId] must equal [vocabulary] — else
  ///    [UiVocabularyPinErrorKind.vocabularyMismatch].
  /// 2. When [allowedComponents] is non-empty, every node `type` in the
  ///    tree must be in the list — else
  ///    [UiVocabularyPinErrorKind.disallowedComponent].
  /// 3. When [caps] is non-null and a dimension is capped, the payload's
  ///    precomputed [UiTreePayload.depth]/[UiTreePayload.nodeCount] must
  ///    not exceed the cap — else
  ///    [UiVocabularyPinErrorKind.capExceeded].
  ///
  /// The check walks the tree once (collecting disallowed component types)
  /// rather than once per check, so the cost is O(nodeCount) — the same
  /// shape as [UiTreePayload.computeNodeCount].
  List<UiVocabularyPinError> validatePayload(UiTreePayload payload) {
    final errors = <UiVocabularyPinError>[];
    if (payload.vocabularyId != vocabulary) {
      errors.add(
        UiVocabularyPinError(
          kind: UiVocabularyPinErrorKind.vocabularyMismatch,
          field: 'vocabularyId',
          reason:
              "payload vocabulary '${payload.vocabularyId}' does not match "
              "spec pin '$vocabulary'",
        ),
      );
    }
    final allow = allowedComponents;
    if (allow != null && allow.isNotEmpty) {
      final allowSet = allow.toSet();
      final offender = _firstDisallowedComponent(payload.tree, allowSet);
      if (offender != null) {
        errors.add(
          UiVocabularyPinError(
            kind: UiVocabularyPinErrorKind.disallowedComponent,
            field: 'tree.type',
            reason:
                "component type '$offender' is not in the spec's "
                'allowedComponents (${allow.join(', ')})',
          ),
        );
      }
    }
    final c = caps;
    if (c != null && c.hasAnyCap) {
      if (c.depth != null && payload.depth > c.depth!) {
        errors.add(
          UiVocabularyPinError(
            kind: UiVocabularyPinErrorKind.capExceeded,
            field: 'depth',
            reason: 'payload depth ${payload.depth} exceeds cap ${c.depth}',
          ),
        );
      }
      if (c.nodes != null && payload.nodeCount > c.nodes!) {
        errors.add(
          UiVocabularyPinError(
            kind: UiVocabularyPinErrorKind.capExceeded,
            field: 'nodeCount',
            reason:
                'payload nodeCount ${payload.nodeCount} exceeds cap ${c.nodes}',
          ),
        );
      }
    }
    return errors;
  }

  /// Walk the tree and return the first `type` not in [allow], or null.
  static String? _firstDisallowedComponent(
    Map<String, dynamic> node,
    Set<String> allow,
  ) {
    final type = node['type'];
    if (type is String && !allow.contains(type)) {
      return type;
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          final found = _firstDisallowedComponent(child, allow);
          if (found != null) return found;
        }
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiSpec &&
          runtimeType == other.runtimeType &&
          vocabulary == other.vocabulary &&
          _listEq(allowedComponents, other.allowedComponents) &&
          caps == other.caps);

  static bool _listEq(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(vocabulary, allowedComponents, caps);

  @override
  String toString() =>
      'UiSpec(vocabulary: $vocabulary, allowedComponents: $allowedComponents, '
      'caps: $caps)';
}

/// Kind of [UiVocabularyPinError] — issue #8 AC-2 "typed errors".
enum UiVocabularyPinErrorKind {
  /// [UiSpec.vocabulary] != [UiTreePayload.vocabularyId].
  vocabularyMismatch,

  /// A node `type` is not in [UiSpec.allowedComponents].
  disallowedComponent,

  /// [UiTreePayload.depth] or [UiTreePayload.nodeCount] exceeds [UiCaps].
  capExceeded,
}

/// Typed error produced by [UiSpec.validatePayload] when a [UiTreePayload]
/// falls outside the spec pin (issue #8 AC-2). The engine throws a
/// [StateError] aggregating these at the tool-result boundary; the plugin
/// surface keeps the typed list for diagnostics.
class UiVocabularyPinError {
  final UiVocabularyPinErrorKind kind;
  final String field;
  final String reason;

  const UiVocabularyPinError({
    required this.kind,
    required this.field,
    required this.reason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiVocabularyPinError &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          field == other.field &&
          reason == other.reason);

  @override
  int get hashCode => Object.hash(kind, field, reason);

  @override
  String toString() =>
      'UiVocabularyPinError(kind: $kind, field: $field, reason: $reason)';
}
