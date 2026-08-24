// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// OversizedResultPolicy (summarize+artifactRef) value object - spec-exact from epic #1 §R3 (issue #4).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// OversizedResultPolicy (summarize+artifactRef) value object.
///
/// Policy for oversized tool results — summarize + artifactRef before entering model context (epic #3 §R3.4, issue #4 US4). Keeps the context budget under control without losing the data.
class OversizedResultPolicy {
  final String id;
  final int thresholdBytes;
  final int summaryMaxChars;
  final String artifactStore;

  const OversizedResultPolicy({
    required this.id,
    required this.thresholdBytes,
    required this.summaryMaxChars,
    required this.artifactStore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OversizedResultPolicy &&
          runtimeType == other.runtimeType && id == other.id && thresholdBytes == other.thresholdBytes && summaryMaxChars == other.summaryMaxChars && artifactStore == other.artifactStore);

  @override
  int get hashCode => Object.hash(id, thresholdBytes, summaryMaxChars, artifactStore);

  @override
  String toString() =>
      'OversizedResultPolicy(id: $id, thresholdBytes: $thresholdBytes, summaryMaxChars: $summaryMaxChars)';
}
