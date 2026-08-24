// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// SubAgentContext (isolated context) value object - spec-exact from epic #1 §R5 (issue #6).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// SubAgentContext (isolated context) value object.
///
/// Isolated sub-agent execution context — own session, own tool allowlist, own budget; the parent receives result summaries only, never raw context (epic #5 §R5.1, issue #6 US1).
class SubAgentContext {
  final String id;
  final String subAgentSpecId;
  final String sessionId;
  final List<String> toolAllowlist;
  final int budgetTurns;

  const SubAgentContext({
    required this.id,
    required this.subAgentSpecId,
    required this.sessionId,
    required this.toolAllowlist,
    required this.budgetTurns,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubAgentContext &&
          runtimeType == other.runtimeType && id == other.id && subAgentSpecId == other.subAgentSpecId && sessionId == other.sessionId && toolAllowlist == other.toolAllowlist && budgetTurns == other.budgetTurns);

  @override
  int get hashCode => Object.hash(id, subAgentSpecId, sessionId, toolAllowlist, budgetTurns);

  @override
  String toString() =>
      'SubAgentContext(id: $id, subAgentSpecId: $subAgentSpecId, sessionId: $sessionId)';
}
