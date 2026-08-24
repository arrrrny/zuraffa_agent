// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// DispatchTool (built-in) value object - spec-exact from epic #1 §R5 (issue #6).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// DispatchTool (built-in) value object.
///
/// Built-in dispatch tool — the model calls dispatch(subAgentType='X', mission='…') and the engine spawns an isolated sub-agent (epic #5 §R5.4, issue #6 US4).
class DispatchTool {
  final String id;
  final String toolName;
  final String subAgentSpecId;
  final String riskTier;

  const DispatchTool({
    required this.id,
    required this.toolName,
    required this.subAgentSpecId,
    required this.riskTier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DispatchTool &&
          runtimeType == other.runtimeType && id == other.id && toolName == other.toolName && subAgentSpecId == other.subAgentSpecId && riskTier == other.riskTier);

  @override
  int get hashCode => Object.hash(id, toolName, subAgentSpecId, riskTier);

  @override
  String toString() =>
      'DispatchTool(id: $id, toolName: $toolName, subAgentSpecId: $subAgentSpecId)';
}
