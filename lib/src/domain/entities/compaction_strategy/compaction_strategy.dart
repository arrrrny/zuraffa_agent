// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// CompactionStrategy (selective retain/summarize) value object - spec-exact from epic #1 §R1 (issue #3).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// CompactionStrategy (selective retain/summarize) value object.
///
/// Selective compaction policy — retain decisions/tool names/key results/plan state verbatim; replace verbose outputs with structured summaries referencing artifacts (epic #1 §R2.3, issue #3 AC1).
class CompactionStrategy {
  final String id;
  final String sessionId;
  final List<String> retainEntryIds;
  final List<String> summarizeEntryIds;
  final List<String> artifactRefs;
  final int compactedAt;

  const CompactionStrategy({
    required this.id,
    required this.sessionId,
    required this.retainEntryIds,
    required this.summarizeEntryIds,
    required this.artifactRefs,
    required this.compactedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompactionStrategy &&
          runtimeType == other.runtimeType && id == other.id && sessionId == other.sessionId && retainEntryIds == other.retainEntryIds && summarizeEntryIds == other.summarizeEntryIds && artifactRefs == other.artifactRefs && compactedAt == other.compactedAt);

  @override
  int get hashCode => Object.hash(id, sessionId, retainEntryIds, summarizeEntryIds, artifactRefs, compactedAt);

  @override
  String toString() =>
      'CompactionStrategy(id: $id, sessionId: $sessionId, retainEntryIds: $retainEntryIds)';
}
