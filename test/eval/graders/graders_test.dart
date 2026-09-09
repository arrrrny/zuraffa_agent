// spec 111 (issue #125) — grader diversity: exact-match, regex, json-path,
// llm-judge graders + the bind-by-id registry. All fixtures are synthetic.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/eval/graders/exact_match_grader.dart';
import 'package:zuraffa_agent/src/eval/graders/grader.dart';
import 'package:zuraffa_agent/src/eval/graders/grader_registry.dart';
import 'package:zuraffa_agent/src/eval/graders/json_path_grader.dart';
import 'package:zuraffa_agent/src/eval/graders/llm_judge_grader.dart';
import 'package:zuraffa_agent/src/eval/graders/regex_grader.dart';

ChatCompletion completionOf(String content) => ChatCompletion(
  content: content,
  finishReason: 'stop',
  usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
);

const missionOutput = 'The capital of France is Paris.';

void main() {
  group('spec 111 — ExactMatchGrader', () {
    test(
      'U1: passes on equality (trim honored); fails with expected+actual',
      () async {
        const grader = ExactMatchGrader(expected: missionOutput);
        final pass = await grader.grade(missionOutput);
        expect(pass.passed, isTrue);
        expect(pass.reason, isNotEmpty);

        final trimmed = ExactMatchGrader(expected: '  $missionOutput  ');
        expect((await trimmed.grade(missionOutput)).passed, isTrue);

        final fail = await grader.grade('The capital of France is Lyon.');
        expect(fail.passed, isFalse);
        expect(fail.reason, contains(missionOutput));
        expect(fail.reason, contains('Lyon'));
      },
    );

    test('U2: RegexGrader passes on match; fails naming the pattern', () async {
      final grader = RegexGrader(pattern: RegExp(r'capital of France is \w+'));
      expect((await grader.grade(missionOutput)).passed, isTrue);

      final fail = await grader.grade('no match here');
      expect(fail.passed, isFalse);
      expect(fail.reason, contains(r'\w+'));
    });
  });

  group('spec 111 — JsonPathGrader', () {
    const payload = '''
{
  "steps": [
    {"status": "ok", "detail": "search"},
    {"status": "ok", "detail": "read"},
    {"status": "failed", "detail": "write"}
  ],
  "summary": {"total": 3, "failed": 1}
}
''';

    test(
      'U3: resolves a documented-subset path and passes on equality',
      () async {
        final grader = JsonPathGrader(
          path: r'$.steps[2].status',
          expected: 'failed',
        );
        final verdict = await grader.grade(payload);
        expect(verdict.passed, isTrue);
      },
    );

    test(
      'U4: missing path / mismatch / malformed JSON fail with reasons',
      () async {
        final missing = await JsonPathGrader(
          path: r'$.no.such[3].key',
          expected: 'x',
        ).grade(payload);
        expect(missing.passed, isFalse);
        expect(missing.reason, contains('no.such'));

        final mismatch = await JsonPathGrader(
          path: r'$.summary.total',
          expected: 9,
        ).grade(payload);
        expect(mismatch.passed, isFalse);
        expect(mismatch.reason, contains(r'$.summary.total'));

        final malformed = await JsonPathGrader(
          path: r'$.a',
          expected: 1,
        ).grade('not json {');
        expect(malformed.passed, isFalse);
        expect(malformed.reason, contains('JSON'));
      },
    );
  });

  group('spec 111 — LlmJudgeGrader', () {
    test('U5: a PASS-prefixed response passes, carrying the reason; the '
        'judge message contains the prompt and the output', () async {
      String? seenLastUserMessage;
      final grader = LlmJudgeGrader(
        judgePrompt: 'Grade the mission output for correctness.',
        complete: (messages) async {
          final user = messages.last;
          seenLastUserMessage = user.content;
          return completionOf(
            'PASS — the output correctly states the capital.',
          );
        },
      );
      final verdict = await grader.grade(missionOutput);
      expect(verdict.passed, isTrue);
      expect(verdict.reason, contains('capital'));
      expect(seenLastUserMessage, contains('Grade the mission output'));
      expect(seenLastUserMessage, contains(missionOutput));
    });

    test('U6: a FAIL-prefixed response fails with its reason', () async {
      final grader = LlmJudgeGrader(
        judgePrompt: 'grade it',
        complete: (messages) async =>
            completionOf('FAIL — the output names the wrong capital'),
      );
      final verdict = await grader.grade(missionOutput);
      expect(verdict.passed, isFalse);
      expect(verdict.reason, contains('wrong capital'));
    });

    test(
      'U7: an unparsable response fails, quoting the raw response',
      () async {
        final grader = LlmJudgeGrader(
          judgePrompt: 'grade it',
          complete: (messages) async => completionOf('looks kinda fine??'),
        );
        final verdict = await grader.grade(missionOutput);
        expect(verdict.passed, isFalse);
        expect(verdict.reason, contains('looks kinda fine??'));
      },
    );
  });

  group('spec 111 — GraderRegistry', () {
    test('U8: register + resolve by id; unknown id fails typed', () async {
      final registry = GraderRegistry()
        ..register(const ExactMatchGrader(expected: 'x'), id: 'exact-main');
      expect(registry.resolve('exact-main'), isA<ExactMatchGrader>());
      expect(
        () => registry.resolve('nope'),
        throwsA(
          predicate(
            (Object e) => e is StateError && e.message.contains('nope'),
          ),
        ),
      );
    });

    test('U9: evaluate-in-bulk returns one verdict per binding id', () async {
      final registry = GraderRegistry()
        ..register(RegexGrader(pattern: RegExp('Paris')), id: 'paris')
        ..register(const ExactMatchGrader(expected: 'wrong'), id: 'exact');
      final verdicts = await registry.evaluateAll({
        'paris': missionOutput,
        'exact': missionOutput,
      });
      expect(verdicts, hasLength(2));
      expect(verdicts['paris']!.passed, isTrue);
      expect(verdicts['exact']!.passed, isFalse);
    });
  });

  group('spec 111 — composed multi-grader acceptance (SC-005)', () {
    test(
      'A1: four grader families resolve by id and grade one fixture',
      () async {
        final registry = GraderRegistry()
          ..register(
            const ExactMatchGrader(expected: missionOutput),
            id: 'exact',
          )
          ..register(RegexGrader(pattern: RegExp(r'\bParis\b')), id: 'regex')
          ..register(
            JsonPathGrader(path: r'$.answer.place', expected: 'Paris'),
            id: 'json',
          )
          ..register(
            LlmJudgeGrader(
              judgePrompt: 'Is this about Paris?',
              complete: (messages) async =>
                  completionOf('PASS — correct subject'),
            ),
            id: 'judge',
          );

        final jsonPayload = jsonEncode({
          'answer': {'place': 'Paris'},
        });

        final verdicts = <String, GraderResult>{};
        for (final id in ['exact', 'regex', 'json', 'judge']) {
          final grader = registry.resolve(id);
          verdicts[id] = await grader.grade(
            id == 'json' ? jsonPayload : missionOutput,
          );
        }

        expect(verdicts['exact']!.passed, isTrue);
        expect(verdicts['regex']!.passed, isTrue);
        expect(verdicts['json']!.passed, isTrue);
        expect(verdicts['judge']!.passed, isTrue);
      },
    );
  });
}
