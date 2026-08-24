// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// RecordedTraffic (LLM + tool capture) value object - spec-exact from epic #1 §R6 (issue #7).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// RecordedTraffic (LLM + tool capture) value object.
///
/// LLM + tool traffic recording — every LLM call and tool dispatch captured as a typed entry (epic #6 §R6.1, issue #7 US1). The replay source-of-truth.
class RecordedTraffic {
  final String id;
  final String missionId;
  final int llmCallCount;
  final int toolCallCount;
  final int recordedAt;

  const RecordedTraffic({
    required this.id,
    required this.missionId,
    required this.llmCallCount,
    required this.toolCallCount,
    required this.recordedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordedTraffic &&
          runtimeType == other.runtimeType && id == other.id && missionId == other.missionId && llmCallCount == other.llmCallCount && toolCallCount == other.toolCallCount && recordedAt == other.recordedAt);

  @override
  int get hashCode => Object.hash(id, missionId, llmCallCount, toolCallCount, recordedAt);

  @override
  String toString() =>
      'RecordedTraffic(id: $id, missionId: $missionId, llmCallCount: $llmCallCount)';
}
