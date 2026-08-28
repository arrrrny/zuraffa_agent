// Spec 006 — acceptance behavior A1: a recorded cassette replayed consumes
// recordings instead of live calls, with identical event order.
//
// The harness runs a real `MissionRunner` against a `CassetteReplayLlmClient`
// built from a `GoldenMission`'s cassette. Three claims, all asserted here:
//   1. the recordings are consumed, in order;
//   2. no live call happens — the live client behind the replay client is never
//      touched, and an exhausted cassette throws rather than falling through to
//      the network;
//   3. the event order the mission emits under replay is identical to the
//      order recorded in the cassette.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/golden_mission/golden_mission.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';
import 'package:zuraffa_agent/src/eval/cassette_replay_llm_client.dart';

/// The recorded cassette: two turns, plus the event order that was observed
/// when the mission was recorded live.
final kCassette = <String, dynamic>{
  'completions': [
    {
      'content': 'looking it up',
      'reasoning': 'I should call the search tool',
      'finishReason': 'tool_calls',
      'usage': {'prompt_tokens': 10, 'completion_tokens': 4, 'total_tokens': 14},
    },
    {
      'content': 'lisbon is sunny',
      'finishReason': 'stop',
      'usage': {'prompt_tokens': 20, 'completion_tokens': 5, 'total_tokens': 25},
    },
  ],
  'eventOrder': [
    'MissionStarted',
    'TurnStarted',
    'ToolCallStarted',
    'ToolCallCompleted',
    'TurnCompleted',
    'TurnStarted',
    'TurnCompleted',
    'MissionCompleted',
  ],
};

class NeverCalledDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      ToolDispatchResult(
        success: true,
        result: 'forecast: sunny',
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

class SearchThenStopPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(completion, transcript) async =>
      completion.finishReason == 'tool_calls'
          ? const [
              ToolCall(
                toolName: 'search',
                arguments: {'q': 'weather'},
                executionMode: 'sequential',
              )
            ]
          : const [];
}

void main() {
  test('A1: replaying a cassette consumes the recordings, never the live '
      'client, and reproduces the recorded event order', () async {
    final mission = GoldenMission(
      id: 'gm-1',
      name: 'weather lookup',
      cassette: kCassette,
      taskDefinition: 'ask for the weather and use the search tool',
      graderBindings: const ['exact'],
    );

    final client = CassetteReplayLlmClient.fromGoldenMission(mission);

    const loop = EngineLoop(
      id: 'loop-a1',
      sessionId: 's-a1',
      maxTurns: 5,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 10,
    );
    const policy = StopPolicy(
      id: 'cap-a1',
      maxTurns: 5,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 10,
    );

    final events = <EngineEvent>[];
    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, client),
      toolDispatcher: NeverCalledDispatcher(),
      stopPolicy: policy,
      onEvent: events.add,
    );

    final result = await runner.run(
      missionId: 'm-a1',
      messages: const [ChatMessage(role: 'user', content: 'weather?')],
      planner: SearchThenStopPlanner(),
    );

    // 1. The recordings were consumed, in order.
    expect(client.consumed, 2);
    expect(client.exhausted, isTrue);
    expect(result.summary, 'lisbon is sunny');

    // 2. No live call was attempted, and an exhausted cassette refuses to fall
    //    through to the network.
    expect(client.liveCallCount, 0);
    await expectLater(
      client.complete(const [ChatMessage(role: 'user', content: 'again?')]),
      throwsA(isA<StateError>()),
    );
    expect(client.liveCallCount, 0);

    // 3. The event order under replay is identical to the recorded order.
    expect(
      events.map((e) => e.runtimeType.toString()).toList(),
      kCassette['eventOrder'],
    );
  });
}
