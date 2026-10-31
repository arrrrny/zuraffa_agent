// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// DartIoFreeGate (static gate) value object - spec-exact from epic #1 §R6
// (issue #7). Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields, no @Zorphy
// codegen, compiles without build_runner.
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// DartIoFreeGate (static gate) value object.
///
/// Static gate that fails the build if the eval runtime imports the platform IO
/// module (epic #6 §R6.5, issue #7 US5). Keeps the eval harness consumable from
/// web platforms.
class DartIoFreeGate {
  /// The identifier.
  final String id;

  /// The gate name.
  final String gateName;

  /// The enforced paths.
  final List<String> enforcedPaths;

  /// The violation count.
  final int violationCount;

  /// Creates a dart I/O free gate.
  const DartIoFreeGate({
    required this.id,
    required this.gateName,
    required this.enforcedPaths,
    required this.violationCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DartIoFreeGate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          gateName == other.gateName &&
          enforcedPaths == other.enforcedPaths &&
          violationCount == other.violationCount);

  @override
  int get hashCode => Object.hash(id, gateName, enforcedPaths, violationCount);

  @override
  String toString() =>
      'DartIoFreeGate(id: $id, gateName: $gateName, enforcedPaths: '
      '$enforcedPaths)';
}
