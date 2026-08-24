// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Grader sealed (exact/schema/model-judge) value object - spec-exact from epic #1 §R6 (issue #7).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// Grader sealed (exact/schema/model-judge) value object.
///
/// Sealed grader — ExactGrader, SchemaGrader, ModelJudgeGrader (recorded) (epic #6 §R6.3, issue #7 US3). One grade(output, expected) method per subtype.
class GraderSealed {
  final String id;
  final String graderType;
  final String? expectedHash;
  final String? schemaId;

  const GraderSealed({
    required this.id,
    required this.graderType,
    this.expectedHash,
    this.schemaId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraderSealed &&
          runtimeType == other.runtimeType && id == other.id && graderType == other.graderType && expectedHash == other.expectedHash && schemaId == other.schemaId);

  @override
  int get hashCode => Object.hash(id, graderType, expectedHash, schemaId);

  @override
  String toString() =>
      'GraderSealed(id: $id, graderType: $graderType, expectedHash: $expectedHash)';
}
