// HAND-CURATED — spec 111 (issue arrrrny/zuraffa_agent#125).
//
// LlmJudgeGrader — for outputs with no deterministic rule: send the judge
// prompt plus the mission output through an INJECTED completion seam
// (scriptable in tests, provider-backed in evals), then parse a strict
// verdict: the response must start with PASS or FAIL, optionally followed
// by a separator and the reason. An unparsable response FAILS with the raw
// response quoted in the reason.

import '../../domain/entities/llm_client/chat_completion.dart';
import '../../domain/entities/llm_client/chat_message.dart';
import 'grader.dart';

/// The completion seam the judge uses (house injectable-collaborator
/// pattern — no provider constructor coupling).
typedef LlmComplete =
    Future<ChatCompletion> Function(List<ChatMessage> messages);

class LlmJudgeGrader implements Grader {
  final String judgePrompt;
  final LlmComplete complete;

  const LlmJudgeGrader({required this.judgePrompt, required this.complete});

  @override
  String get id => 'llm-judge';

  @override
  Future<GraderResult> grade(String output) async {
    final response = await complete([
      ChatMessage(
        role: 'user',
        content:
            '$judgePrompt\n\nMission output to grade:\n$output\n\n'
            'Respond starting with PASS or FAIL, then " — " and the reason.',
      ),
    ]);
    return _parse(response.content);
  }

  GraderResult _parse(String response) {
    final trimmed = response.trim();
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('PASS')) {
      return GraderResult.pass(_reasonOf(trimmed) ?? trimmed);
    }
    if (upper.startsWith('FAIL')) {
      return GraderResult.fail(_reasonOf(trimmed) ?? trimmed);
    }
    return GraderResult.fail(
      'unparsable judge response — expected PASS/FAIL prefix, got: '
      '"$trimmed"',
    );
  }

  String? _reasonOf(String response) {
    final separator = response.indexOf(RegExp(r'\s+—\s+|\s+--\s+|:\s+'));
    if (separator == -1) return null;
    return response.substring(separator).trim();
  }
}
