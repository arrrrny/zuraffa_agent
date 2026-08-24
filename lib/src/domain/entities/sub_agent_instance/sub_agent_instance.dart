// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// SubAgentInstance (resumable) value object - spec-exact from epic #1 §R5 (issue #6).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// SubAgentInstance (resumable) value object.
///
/// Resumable sub-agent instance — persists across engine restarts, can be resumed by id (epic #5 §R5.2, issue #6 US2). Tracks last-run outcome, total runs, parent reference.
class SubAgentInstance {
  final String id;
  final String subAgentSpecId;
  final String parentSessionId;
  final int totalRuns;
  final String? lastRunOutcome;

  const SubAgentInstance({
    required this.id,
    required this.subAgentSpecId,
    required this.parentSessionId,
    required this.totalRuns,
    this.lastRunOutcome,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubAgentInstance &&
          runtimeType == other.runtimeType && id == other.id && subAgentSpecId == other.subAgentSpecId && parentSessionId == other.parentSessionId && totalRuns == other.totalRuns && lastRunOutcome == other.lastRunOutcome);

  @override
  int get hashCode => Object.hash(id, subAgentSpecId, parentSessionId, totalRuns, lastRunOutcome);

  @override
  String toString() =>
      'SubAgentInstance(id: $id, subAgentSpecId: $subAgentSpecId, parentSessionId: $parentSessionId)';
}
