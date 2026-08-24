// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// ToolDispatchMode (sequential/parallel) value object - spec-exact from epic #1 §R3 (issue #4).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// ToolDispatchMode (sequential/parallel) value object.
///
/// Dispatch policy — sequential (one tool, then re-prompt) or parallel (fan-out, gather, then re-prompt). Maps directly to the LLM's tool-call batch (epic #3 §R3.2, issue #4 FR-002).
class ToolDispatchMode {
  final String id;
  final String mode;
  final int maxParallel;
  final bool failFast;

  const ToolDispatchMode({
    required this.id,
    required this.mode,
    required this.maxParallel,
    required this.failFast,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolDispatchMode &&
          runtimeType == other.runtimeType && id == other.id && mode == other.mode && maxParallel == other.maxParallel && failFast == other.failFast);

  @override
  int get hashCode => Object.hash(id, mode, maxParallel, failFast);

  @override
  String toString() =>
      'ToolDispatchMode(id: $id, mode: $mode, maxParallel: $maxParallel)';
}
