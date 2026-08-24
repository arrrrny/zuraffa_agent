// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// PassKEmpirical (pass^k metric) value object - spec-exact from epic #1 §R6 (issue #7).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// PassKEmpirical (pass^k metric) value object.
///
/// pass^k empirical metric — fraction of k independent runs that succeeded (epic #6 §R6.2, issue #7 US2). Complements the existing pass@k unbiased estimator (spec 037).
class PassKEmpirical {
  final String id;
  final String taskId;
  final int k;
  final int successCount;
  final double empiricalRate;

  const PassKEmpirical({
    required this.id,
    required this.taskId,
    required this.k,
    required this.successCount,
    required this.empiricalRate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassKEmpirical &&
          runtimeType == other.runtimeType && id == other.id && taskId == other.taskId && k == other.k && successCount == other.successCount && empiricalRate == other.empiricalRate);

  @override
  int get hashCode => Object.hash(id, taskId, k, successCount, empiricalRate);

  @override
  String toString() =>
      'PassKEmpirical(id: $id, taskId: $taskId, k: $k)';
}
