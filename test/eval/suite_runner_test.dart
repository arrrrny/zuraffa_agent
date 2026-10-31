// Tests for SuiteRunner (issue #115).
//
// SuiteRunner replays each k sample through the real engine stack
// (MissionReplayRunner), so these tests drive real cassette replays: a
// mission's cassette pins its answer, and the grader observes the replayed
// summary.
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/eval/suite_runner.dart';

GoldenMission _mission(String id, String answer) => GoldenMission(
  id: id,
  name: 'Mission $id',
  cassette: {
    'completions': [
      {
        'content': 'thinking about $id',
        'finishReason': 'stop',
        'usage': {
          'prompt_tokens': 1,
          'completion_tokens': 1,
          'total_tokens': 2,
        },
      },
      {
        'content': answer,
        'finishReason': 'stop',
        'usage': {
          'prompt_tokens': 2,
          'completion_tokens': 2,
          'total_tokens': 4,
        },
      },
    ],
  },
  taskDefinition: 'test',
  graderBindings: const ['exact'],
);

void main() {
  group('SuiteRunner', () {
    const runner = SuiteRunner();

    group('runK', () {
      test('runs mission k times and collects outcomes', () async {
        final mission = _mission('GM-1', 'answer one');

        var calls = 0;
        final result = await runner.runK(
          mission,
          3,
          grader: (output) async {
            calls++;
            return output == 'answer one';
          },
        );

        expect(calls, 3, reason: 'the grader sees every replayed summary');
        expect(result.missionId, 'GM-1');
        expect(result.k, 3);
        expect(result.outcomes, [true, true, true]);
        expect(result.correctCount, 3);
        expect(result.passK, 1.0);
        expect(result.passAtK, closeTo(1.0, 1e-9));
      });

      test('handles mixed pass/fail outcomes', () async {
        final mission = _mission('GM-2', 'answer two');

        var callCount = 0;
        final result = await runner.runK(
          mission,
          4,
          grader: (output) async {
            callCount++;
            return callCount.isOdd;
          },
        );

        expect(result.outcomes, [true, false, true, false]);
        expect(result.correctCount, 2);
        expect(result.passK, 0.5);
      });

      test('all-failing outcomes gate at zero', () async {
        final mission = _mission('GM-3', 'real answer');

        final result = await runner.runK(
          mission,
          2,
          grader: (_) async => false,
        );

        expect(result.outcomes, [false, false]);
        expect(result.correctCount, 0);
        expect(result.passK, 0.0);
        expect(result.passAtK, 0.0);
      });

      test('a mission with no completions fails loudly', () async {
        final mission = GoldenMission(
          id: 'GM-empty',
          name: 'empty',
          cassette: const {},
          taskDefinition: 'test',
          graderBindings: const [],
        );

        await expectLater(
          runner.runK(mission, 1, grader: (_) async => true),
          throwsA(isA<StateError>()),
        );
      });

      test('incomplete replays count as failures', () async {
        // A cassette whose final completion signals tool_calls never stops
        // naturally within the replay budget, so the run is incomplete —
        // the runner grades it a failure rather than crashing.
        final mission = GoldenMission(
          id: 'GM-toolloop',
          name: 'tool loop',
          cassette: {
            'completions': List.generate(
              20,
              (i) => {
                'content': 'turn $i',
                'finishReason': 'tool_calls',
                'usage': {
                  'prompt_tokens': 1,
                  'completion_tokens': 1,
                  'total_tokens': 2,
                },
              },
            ),
          },
          taskDefinition: 'test',
          graderBindings: const [],
        );

        final result = await runner.runK(mission, 1, grader: (_) async => true);

        expect(result.outcomes, [false]);
      });

      test('value equality compares outcomes element-wise', () async {
        final a = await runner.runK(
          _mission('X', 'ans'),
          2,
          grader: (_) async => true,
        );
        final b = await runner.runK(
          _mission('X', 'ans'),
          2,
          grader: (_) async => true,
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });
    });

    group('runSuite', () {
      test(
        'runs all tasks and passes the gate when everything replays true',
        () async {
          final suite = Suite(
            id: 'test-suite',
            name: 'Test Suite',
            tasks: const ['GM-1', 'GM-2'],
            k: 2,
            gateThreshold: 0.8,
          );

          final result = await runner.runSuite(
            suite,
            loadMission: (taskId) => _mission(taskId, 'answer-$taskId'),
            resolveGrader: (output, mission) async =>
                output == 'answer-${mission.id}',
          );

          expect(result.suite.id, 'test-suite');
          expect(result.missionResults.keys, containsAll(['GM-1', 'GM-2']));
          expect(result.decision.passed, isTrue);
          expect(result.decision.exitCode, 0);
          expect(result.passKByTask['GM-1'], 1.0);
          expect(result.passKByTask['GM-2'], 1.0);
        },
      );

      test('fails the gate when a task keeps failing its grader', () async {
        final suite = Suite(
          id: 'failing-suite',
          name: 'Failing Suite',
          tasks: const ['GM-1', 'GM-2'],
          k: 2,
          gateThreshold: 0.8,
        );

        final result = await runner.runSuite(
          suite,
          loadMission: (taskId) => _mission(taskId, 'answer-$taskId'),
          resolveGrader: (output, mission) async => mission.id == 'GM-1',
        );

        expect(result.decision.passed, isFalse);
        expect(result.decision.exitCode, 1);
        expect(result.passKByTask['GM-1'], 1.0);
        expect(result.passKByTask['GM-2'], 0.0);
      });
    });

    group('runSuiteAndExit', () {
      test('returns 0 when the suite passes', () async {
        final suite = Suite(
          id: 'passing-suite',
          name: 'Passing',
          tasks: const ['GM-1'],
          k: 2,
          gateThreshold: 0.5,
        );

        final exitCode = await runner.runSuiteAndExit(
          suite,
          loadMission: (taskId) => _mission(taskId, 'answer-$taskId'),
          resolveGrader: (_, _) async => true,
        );

        expect(exitCode, 0);
      });

      test('returns 1 when the suite fails', () async {
        final suite = Suite(
          id: 'failing-suite',
          name: 'Failing',
          tasks: const ['GM-1'],
          k: 2,
          gateThreshold: 1.0,
        );

        final exitCode = await runner.runSuiteAndExit(
          suite,
          loadMission: (taskId) => _mission(taskId, 'answer-$taskId'),
          resolveGrader: (_, _) async => false,
        );

        expect(exitCode, 1);
      });
    });
  });
}
