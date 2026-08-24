// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// LoopSafetyRails typed outcomes value object - spec-exact from epic #1 §R2 (issue #2).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// LoopSafetyRails typed outcomes value object.
///
/// Typed stop outcomes — MaxTurnsExceeded, WallClockTimeout, LoopDetected — emitted by the loop's safety rails (epic #2 §R1.4, issue #2 US4).
class LoopSafetyRails {
  final String outcomeType;
  final int turnNumber;
  final String reason;
  final int emittedAt;

  const LoopSafetyRails({
    required this.outcomeType,
    required this.turnNumber,
    required this.reason,
    required this.emittedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoopSafetyRails &&
          runtimeType == other.runtimeType && outcomeType == other.outcomeType && turnNumber == other.turnNumber && reason == other.reason && emittedAt == other.emittedAt);

  @override
  int get hashCode => Object.hash(outcomeType, turnNumber, reason, emittedAt);

  @override
  String toString() =>
      'LoopSafetyRails(outcomeType: $outcomeType, turnNumber: $turnNumber, reason: $reason)';
}
