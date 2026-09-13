// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).
//
// Grader — the common interface every eval grader implements (exact-match,
// regex, json-path, llm-judge; UI schema/snapshot graders may join later).
// Golden missions bind graders by id through the GraderRegistry.

/// The verdict one grader produces for one output.
class GraderResult {
  final bool passed;

  /// Optional normalized score (e.g. judge confidence); null when the
  /// grader is purely binary.
  final double? score;

  /// Human-readable explanation — on failure this names what was expected
  /// and what was actually seen.
  final String reason;

  const GraderResult({required this.passed, this.score, required this.reason});

  const GraderResult.pass(String reason) : this(passed: true, reason: reason);

  const GraderResult.fail(String reason) : this(passed: false, reason: reason);

  @override
  bool operator ==(Object other) =>
      other is GraderResult &&
      other.passed == passed &&
      other.score == score &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(passed, score, reason);

  @override
  String toString() =>
      'GraderResult(${passed ? "PASS" : "FAIL"}, score: $score, reason: $reason)';
}

/// A grader evaluates one mission output and returns a [GraderResult].
///
/// `grade` is async so the llm-judge grader implements it directly;
/// deterministic graders complete synchronously within the returned
/// future.
abstract interface class Grader {
  /// Stable identifier used by golden-mission grader bindings.
  String get id;

  Future<GraderResult> grade(String output);
}
