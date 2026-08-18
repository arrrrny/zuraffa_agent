// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package).
// Source licensed BSD-3-Clause (ZikZak AI); modifications licensed MIT under
// zuraffa_agent. See NOTICE.
/// Selective structured context compaction.
///
/// Phase-002 scope: the structured summary value types consumed by the
/// session entity layer (`CompactionEntry`, `ToolInvocationRecord`).
/// The estimator, cut-point search, summarizer injection, and compaction
/// core live here as well — see the members below.
library;

/// Reference to material moved out of the live context by compaction.
///
/// Opaque by design: the `kind`/`id` pair is resolved through an
/// [ArtifactResolver] implemented by the artifact store (spec 003).
class ArtifactRef {
  /// Artifact category, e.g. 'tool-output' or 'file'.
  final String kind;

  /// Artifact store key.
  final String id;

  /// Creates an artifact reference.
  const ArtifactRef({required this.kind, required this.id});

  @override
  bool operator ==(Object other) =>
      other is ArtifactRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'ArtifactRef($kind/$id)';
}

/// Structured compaction summary replacing pi_agent's placeholder string.
///
/// Retained categories survive compaction as typed fields; discarded
/// material is represented by resolvable [ArtifactRef]s.
class CompactionSummary {
  /// Decisions retained from the compacted conversation.
  final List<String> decisions;

  /// Names of tools invoked in the compacted conversation.
  final List<String> toolNames;

  /// Key results retained from the compacted conversation.
  final List<String> keyResults;

  /// Mission plan state at compaction time, if any.
  final String? planState;

  /// References to discarded material, resolvable via [ArtifactResolver].
  final List<ArtifactRef> artifacts;

  /// Optional narrative summary (e.g. LLM-written).
  final String? prose;

  /// Creates a structured compaction summary.
  const CompactionSummary({
    this.decisions = const [],
    this.toolNames = const [],
    this.keyResults = const [],
    this.planState,
    this.artifacts = const [],
    this.prose,
  });

  @override
  bool operator ==(Object other) =>
      other is CompactionSummary &&
      _listEq(other.decisions, decisions) &&
      _listEq(other.toolNames, toolNames) &&
      _listEq(other.keyResults, keyResults) &&
      other.planState == planState &&
      _listEq(other.artifacts, artifacts) &&
      other.prose == prose;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(decisions),
        Object.hashAll(toolNames),
        Object.hashAll(keyResults),
        planState,
        Object.hashAll(artifacts),
        prose,
      );

  @override
  String toString() =>
      'CompactionSummary(decisions: $decisions, toolNames: $toolNames, '
      'keyResults: $keyResults, planState: $planState, '
      'artifacts: $artifacts)';
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
