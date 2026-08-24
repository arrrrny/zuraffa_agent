// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// EngineLoop (while-loop executor) value object - spec-exact from epic #1 §R2 (issue #2).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// EngineLoop (while-loop executor) value object.
///
/// The turn-based while-loop executor advancing on LLM finish-reason (epic #2 §R1.1, issue #2). No FSM — the model drives; the loop dispatches tool calls, feeds results back, drains the steering queue between turns, emits typed events.
class EngineLoop {
  final String id;
  final String sessionId;
  final int maxTurns;
  final int wallClockTimeoutMs;
  final int repetitionThreshold;

  const EngineLoop({
    required this.id,
    required this.sessionId,
    required this.maxTurns,
    required this.wallClockTimeoutMs,
    required this.repetitionThreshold,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EngineLoop &&
          runtimeType == other.runtimeType && id == other.id && sessionId == other.sessionId && maxTurns == other.maxTurns && wallClockTimeoutMs == other.wallClockTimeoutMs && repetitionThreshold == other.repetitionThreshold);

  @override
  int get hashCode => Object.hash(id, sessionId, maxTurns, wallClockTimeoutMs, repetitionThreshold);

  @override
  String toString() =>
      'EngineLoop(id: $id, sessionId: $sessionId, maxTurns: $maxTurns)';
}
