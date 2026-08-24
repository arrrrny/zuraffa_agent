// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// ReplayDiff (input drift detection) value object - spec-exact from epic #1 §R6 (issue #7).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// ReplayDiff (input drift detection) value object.
///
/// Replay diff — detects input drift between record and replay (same inputs, different bytes -> flagged) (epic #6 §R6.1, issue #7 US1).
class ReplayDiff {
  final String id;
  final String missionId;
  final bool driftDetected;
  final String? diffSummary;

  const ReplayDiff({
    required this.id,
    required this.missionId,
    required this.driftDetected,
    this.diffSummary,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplayDiff &&
          runtimeType == other.runtimeType && id == other.id && missionId == other.missionId && driftDetected == other.driftDetected && diffSummary == other.diffSummary);

  @override
  int get hashCode => Object.hash(id, missionId, driftDetected, diffSummary);

  @override
  String toString() =>
      'ReplayDiff(id: $id, missionId: $missionId, driftDetected: $driftDetected)';
}
