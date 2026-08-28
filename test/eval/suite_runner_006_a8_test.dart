// Spec 006 — acceptance behavior A8: GM-1..GM-5 defined as harness suites run in
// CI and report/gate correctly (FR-004).
//
// The behavior the outer-only plan left BLOCKED was the end-to-end composition:
// a `Suite` of golden-mission tasks is actually *run* through the harness
// (cassette replay + mission runner), each run is *graded*, the per-task sample
// counts feed `SuiteGate`, and the CI exit code comes out right. This test drives
// that whole path for two cohorts:
//   1. a passing cohort — every task clears the threshold → exitCode 0;
//   2. a failing cohort — tasks fall below threshold → exitCode 1, with the
//      per-task breakdown naming which tasks regressed.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/eval/cassette_replay_llm_client.dart';
import 'package:zuraffa_agent/src/eval/suite_gate.dart';

/// Builds a 2-turn cassette whose final turn answers with [finalAnswer].
///
/// Turn 1 signals `tool_calls` so the planner dispatches a tool and the mission
/// takes a second turn; turn 2 finishes naturally with `finalAnswer` as the
/// summary. Replaying it never touches the network.
Map<String, dynamic> _cassette(String finalAnswer) => {
      'completions': [
        {
          'content': 'I will use a tool first',
          'reasoning': 'plan the tool call',
          'finishReason': 'tool_calls',
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 4,
            'total_tokens': 14,
          },
        },
        {
          'content': finalAnswer,
          'finishReason': 'stop',
          'usage': {
            'prompt_tokens': 20,
            'completion_tokens': 5,
            'total_tokens': 25,
          },
        },
      ],
    };

/// A golden mission whose replay answers with [finalAnswer].
GoldenMission _mission(String id, String finalAnswer) => GoldenMission(
      id: id,
      name: id,
      cassette: _cassette(finalAnswer),
      taskDefinition: 'run the mission and answer',
      graderBindings: const ['exact'],
    );

/// A replay client that always reports success, regardless of the tool.
class _OkDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      ToolDispatchResult(
        success: true,
        result: 'ok',
        error: '',
        artifactRefs: const [],
      );

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async =>
      [
        for (final c in calls)
          await dispatch(
            toolName: c.toolName,
            arguments: c.arguments,
            isInternalMission: isInternalMission,
          )
      ];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) =>
      const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) =>
      true;
}

/// Dispatches one search call after any `tool_calls` turn, then stops.
class _SearchThenStopPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async =>
      completion.finishReason == 'tool_calls'
          ? const [
              ToolCall(
                toolName: 'search',
                arguments: {'q': 'x'},
                executionMode: 'sequential',
              )
            ]
          : const [];
}

final _kDispatcher = _OkDispatcher();
final _kPlanner = _SearchThenStopPlanner();

/// Runs [mission] once through the real harness and returns the graded summary.
Future<String> _runOnce(GoldenMission mission) async {
  final client = CassetteReplayLlmClient.fromGoldenMission(mission);
  const loop = EngineLoop(
    id: 'loop-a8',
    sessionId: 's-a8',
    maxTurns: 5,
    wallClockTimeoutMs: 600000,
    repetitionThreshold: 10,
  );
  const policy = StopPolicy(
    id: 'cap-a8',
    maxTurns: 5,
    wallClockTimeout: Duration.zero,
    repetitionThreshold: 10,
  );
  final events = <EngineEvent>[];
  final runner = MissionRunner(
    executor: EngineLoopExecutor(loop, client),
    toolDispatcher: _kDispatcher,
    stopPolicy: policy,
    onEvent: events.add,
  );
  final result = await runner.run(
    missionId: mission.id,
    messages: const [ChatMessage(role: 'user', content: 'go')],
    planner: _kPlanner,
  );
  // A naturally-completed replay yields a non-null summary; a wrong cassette
  // still completes, just with the wrong answer (graded separately).
  return result.summary ?? '';
}

/// Exact-match grader (spec 006 A5): byte/string equality against the expected.
bool _gradeExact(String actual, String expected) => actual == expected;

/// Runs [mission] [n] times, the first [correctCount] of them replaying the
/// correct cassette and the rest replaying a deliberately wrong one, and returns
/// the observed [TaskSamples] (correct runs out of [n]).
Future<TaskSamples> _sampleTask(
  GoldenMission correctMission,
  String expected,
  int n,
  int correctCount,
) async {
  var c = 0;
  for (var i = 0; i < n; i++) {
    final mission =
        i < correctCount ? correctMission : _mission(correctMission.id, 'WRONG-ANSWER');
    final summary = await _runOnce(mission);
    if (_gradeExact(summary, expected)) c++;
  }
  return TaskSamples(n: n, c: c);
}

/// The GM-1..GM-5 suite: k=2 samples per task, gate at 0.8 pass@k.
Suite _suite() => Suite(
      id: 'gm-suite',
      name: 'GM-1..GM-5',
      tasks: const ['GM-1', 'GM-2', 'GM-3', 'GM-4', 'GM-5'],
      k: 2,
      gateThreshold: 0.8,
    );

void main() {
  // k=2, n=5: a task with every sample correct scores pass@k = 1.0.
  test('A8: GM-1..GM-5 suite — all tasks pass the gate → exitCode 0', () async {
    final suite = _suite();
    final samples = <String, TaskSamples>{};
    for (final id in suite.tasks) {
      final expected = 'answer-$id';
      final mission = _mission(id, expected);
      samples[id] = await _sampleTask(mission, expected, 5, 5);
    }

    final decision = SuiteGate.evaluate(suite: suite, samples: samples);

    expect(decision.passed, isTrue);
    expect(decision.exitCode, 0);
    expect(decision.score, 1.0);
    expect(decision.threshold, 0.8);
    for (final row in decision.breakdown) {
      expect(row.passed, isTrue, reason: '${row.taskId} should clear the gate');
      expect(row.passAtK, 1.0);
    }
    expect(decision.report, contains('PASS suite ${suite.id}'));
    for (final id in suite.tasks) {
      expect(decision.report, contains(id));
    }
  });

  // Two tasks pass (1.0) and three fail (0.0): suite mean = 0.4 < 0.8 → fail.
  test('A8: GM-1..GM-5 suite — tasks below threshold fail the gate → exitCode 1',
      () async {
    final suite = _suite();
    final failing = {'GM-3', 'GM-4', 'GM-5'};
    final samples = <String, TaskSamples>{};
    for (final id in suite.tasks) {
      final expected = 'answer-$id';
      final mission = _mission(id, expected);
      final correct = failing.contains(id) ? 0 : 5;
      samples[id] = await _sampleTask(mission, expected, 5, correct);
    }

    final decision = SuiteGate.evaluate(suite: suite, samples: samples);

    expect(decision.passed, isFalse);
    expect(decision.exitCode, 1);
    // (2 passing * 1.0 + 3 failing * 0.0) / 5 tasks = 0.4
    expect(decision.score, 0.4);
    expect(decision.report, contains('FAIL suite ${suite.id}'));
    final byTask = {for (final r in decision.breakdown) r.taskId: r};
    expect(byTask['GM-1']!.passed, isTrue);
    expect(byTask['GM-2']!.passed, isTrue);
    expect(byTask['GM-3']!.passed, isFalse);
    expect(byTask['GM-4']!.passed, isFalse);
    expect(byTask['GM-5']!.passed, isFalse);
  });
}
