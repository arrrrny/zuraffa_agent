// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).

import 'grader.dart';

/// Pattern-match grader over the mission output.
class RegexGrader implements Grader {
  final RegExp pattern;

  const RegexGrader({required this.pattern});

  @override
  String get id => 'regex';

  @override
  Future<GraderResult> grade(String output) async {
    if (pattern.hasMatch(output)) {
      return GraderResult.pass('matched /${pattern.pattern}/');
    }
    return GraderResult.fail(
      'regex did not match — pattern: /${pattern.pattern}/',
    );
  }
}
