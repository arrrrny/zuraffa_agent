// Tests for SuiteRunner (issue #115).

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/eval/suite_runner.dart';

class MockMissionRunner extends Mock implements MissionRunner {}

class MockToolDispatcher extends Mock implements ToolDispatcher {}

void main() {
  group('SuiteRunner', () {
    late MockMissionRunner mockRunner;
    late MockToolDispatcher mockDispatcher;
    late SuiteRunner runner;

    setUp(() {
      mockRunner = MockMissionRunner();
      mockDispatcher = MockToolDispatcher();
      runner = SuiteRunner(
        missionRunner: mockRunner,
        toolDispatcher: mockDispatcher,
      );
    });

    group('runK', () {
      test('runs mission k times and collects outcomes', () async {
        final mission = GoldenMission(
          id: 'GM-1',
          name: 'Test Mission',
          cassette: {'completions': [], 'eventOrder': []},
          taskDefinition: 'test',
          graderBindings: const ['exact'],
        );

        final mockResult = MissionResult(
          missionId: 'GM-1',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'correct answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final result = await runner.runK(
          mission,
          3,
          grader: (output) async => true,
        );

        expect(result.missionId, 'GM-1');
        expect(result.k, 3);
        expect(result.outcomes, [true, true, true]);
        expect(result.correctCount, 3);
        expect(result.passK, 1.0);
        expect(result.passAtK, closeTo(1.0, 1e-9));

        verify(() => mockRunner.run(
          missionId: 'GM-1',
          messages: const [],
        )).called(3);
      });

      test('handles mixed pass/fail outcomes', () async {
        final mission = GoldenMission(
          id: 'GM-2',
          name: 'Test Mission 2',
          cassette: {'completions': [], 'eventOrder': []},
          taskDefinition: 'test',
          graderBindings: const ['exact'],
        );

        final mockResult = MissionResult(
          missionId: 'GM-2',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        var callCount = 0;
        final result = await runner.runK(
          mission,
          4,
          grader: (output) async {
            callCount++;
            return callCount % 2 == 1;
          },
        );

        expect(result.outcomes, [true, false, true, false]);
        expect(result.correctCount, 2);
        expect(result.passK, 0.5);
      });

      test('handles all failing outcomes', () async {
        final mission = GoldenMission(
          id: 'GM-3',
          name: 'Failing Mission',
          cassette: {'completions': [], 'eventOrder': []},
          taskDefinition: 'test',
          graderBindings: const ['exact'],
        );

        final mockResult = MissionResult(
          missionId: 'GM-3',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'wrong answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final result = await runner.runK(
          mission,
          2,
          grader: (output) async => false,
        );

        expect(result.outcomes, [false, false]);
        expect(result.correctCount, 0);
        expect(result.passK, 0.0);
        expect(result.passAtK, 0.0);
      });
    });

    group('runSuite', () {
      test('runs all tasks in suite and collects results', () async {
        final suite = Suite(
          id: 'test-suite',
          name: 'Test Suite',
          tasks: const ['GM-1', 'GM-2'],
          k: 2,
          gateThreshold: 0.8,
        );

        final mockResult = MissionResult(
          missionId: 'test',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final result = await runner.runSuite(
          suite,
          loadMission: (taskId) => GoldenMission(
            id: taskId,
            name: 'Mission $taskId',
            cassette: {'completions': [], 'eventOrder': []},
            taskDefinition: 'test',
            graderBindings: const ['exact'],
          ),
          resolveGrader: (output, mission) async => true,
        );

        expect(result.suite.id, 'test-suite');
        expect(result.missionResults.keys, containsAll(['GM-1', 'GM-2']));
        expect(result.decision.passed, isTrue);
        expect(result.decision.exitCode, 0);
        expect(result.passKByTask['GM-1'], 1.0);
        expect(result.passKByTask['GM-2'], 1.0);
      });

      test('fails gate when tasks fall below threshold', () async {
        final suite = Suite(
          id: 'failing-suite',
          name: 'Failing Suite',
          tasks: const ['GM-1', 'GM-2'],
          k: 2,
          gateThreshold: 0.8,
        );

        final mockResult = MissionResult(
          missionId: 'test',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final result = await runner.runSuite(
          suite,
          loadMission: (taskId) => GoldenMission(
            id: taskId,
            name: 'Mission $taskId',
            cassette: {'completions': [], 'eventOrder': []},
            taskDefinition: 'test',
            graderBindings: const ['exact'],
          ),
          resolveGrader: (output, mission) async => mission.id == 'GM-1',
        );

        expect(result.decision.passed, isFalse);
        expect(result.decision.exitCode, 1);
        expect(result.passKByTask['GM-1'], 1.0);
        expect(result.passKByTask['GM-2'], 0.0);
      });
    });

    group('runSuiteAndExit', () {
      test('returns exit code 0 when suite passes', () async {
        final suite = Suite(
          id: 'passing-suite',
          name: 'Passing Suite',
          tasks: const ['GM-1'],
          k: 2,
          gateThreshold: 0.5,
        );

        final mockResult = MissionResult(
          missionId: 'test',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final exitCode = await runner.runSuiteAndExit(
          suite,
          loadMission: (taskId) => GoldenMission(
            id: taskId,
            name: 'Mission $taskId',
            cassette: {'completions': [], 'eventOrder': []},
            taskDefinition: 'test',
            graderBindings: const ['exact'],
          ),
          resolveGrader: (output, mission) async => true,
        );

        expect(exitCode, 0);
      });

      test('returns exit code 1 when suite fails', () async {
        final suite = Suite(
          id: 'failing-suite',
          name: 'Failing Suite',
          tasks: const ['GM-1'],
          k: 2,
          gateThreshold: 1.0,
        );

        final mockResult = MissionResult(
          missionId: 'test',
          status: MissionStatus.completed,
          turnsUsed: 1,
          transcript: const [],
          summary: 'answer',
        );

        when(() => mockRunner.run(
          missionId: any(named: 'missionId'),
          messages: any(named: 'messages'),
        )).thenAnswer((_) async => mockResult);

        final exitCode = await runner.runSuiteAndExit(
          suite,
          loadMission: (taskId) => GoldenMission(
            id: taskId,
            name: 'Mission $taskId',
            cassette: {'completions': [], 'eventOrder': []},
            taskDefinition: 'test',
            graderBindings: const ['exact'],
          ),
          resolveGrader: (output, mission) async => false,
        );

        expect(exitCode, 1);
      });
    });
  });
}
