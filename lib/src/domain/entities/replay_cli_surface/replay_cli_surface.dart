// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// ReplayCliSurface (zfa agent replay) value object - spec-exact from epic #1 §R6 (issue #7).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// ReplayCliSurface (zfa agent replay) value object.
///
/// zfa agent replay CLI surface — declarative replay invocation (mission id, recorded traffic, grader matrix) (epic #6 §R6.4, issue #7 US4).
class ReplayCliSurface {
  final String id;
  final String missionId;
  final String graderMatrixId;
  final String verbosity;

  const ReplayCliSurface({
    required this.id,
    required this.missionId,
    required this.graderMatrixId,
    required this.verbosity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplayCliSurface &&
          runtimeType == other.runtimeType && id == other.id && missionId == other.missionId && graderMatrixId == other.graderMatrixId && verbosity == other.verbosity);

  @override
  int get hashCode => Object.hash(id, missionId, graderMatrixId, verbosity);

  @override
  String toString() =>
      'ReplayCliSurface(id: $id, missionId: $missionId, graderMatrixId: $graderMatrixId)';
}
