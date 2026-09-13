// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).

import 'grader.dart';

/// String-equality grader against a pinned expected value.
class ExactMatchGrader implements Grader {
  final String expected;
  final bool trim;

  const ExactMatchGrader({required this.expected, this.trim = true});

  @override
  String get id => 'exact-match';

  @override
  Future<GraderResult> grade(String output) async {
    final actual = trim ? output.trim() : output;
    final target = trim ? expected.trim() : expected;
    if (actual == target) {
      return GraderResult.pass('exact match');
    }
    return GraderResult.fail(
      'exact match failed — expected: "$target", actual: "$actual"',
    );
  }
}
