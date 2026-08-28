// Spec 002 — acceptance behavior A7: follow-up messages queued at mission end
// cause the loop to continue with them instead of exiting.
//
// The model stops naturally on every turn (`finishReason == 'stop'`, no tool
// calls), so the loop's only continuation reason is the follow-up queue. A
// caller enqueues one follow-up when the first turn completes — exactly the
// "queued at mission end" race — and the loop must run a second turn with that
// message injected instead of terminating (FR-003).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_message/steering_message.dart';
import 'package:zuraffa_agent/src/domain/entities/steering_queue/steering_queue.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

const kFollowUp = 'actually, also tell me about tomorrow';

class AlwaysStopsClient extends LlmClientProvider {
  AlwaysStopsClient()
      : super(
          config: const ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'https://example.invalid/v1',
            models: ['tencent/hy3:free'],
            timeoutMs: 1,
          ),
          apiKey: 'test-key',
        );

  final List<List<ChatMessage>> contexts = [];

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    contexts.add(List<ChatMessage>.unmodifiable(messages));
    return ChatCompletion(
      content: 'answer ${contexts.length}',
      finishReason: 'stop',
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );
  }
}

class NoToolDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      ToolDispatchResult(
        success: true,
        result: '',
        error: '',
        artifactRefs: const [],
      );

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async =>
      const [];

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

void main() {
  test('A7: a follow-up queued as the turn completes continues the loop instead '
      'of ending the mission', () async {
    const loop = EngineLoop(
      id: 'loop-7',
      sessionId: 's7',
      maxTurns: 5,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 10,
    );
    const policy = StopPolicy(
      id: 'cap7',
      maxTurns: 5,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 10,
    );

    final client = AlwaysStopsClient();
    final events = <EngineEvent>[];
    late final MissionRunner runner;
    var enqueued = false;

    runner = MissionRunner(
      executor: EngineLoopExecutor(loop, client),
      toolDispatcher: NoToolDispatcher(),
      stopPolicy: policy,
      steeringQueue: SteeringQueue(id: 'q7', pending: const [], processedCount: 0),
      onEvent: (event) {
        events.add(event);
        if (event is TurnCompleted && !enqueued) {
          enqueued = true;
          runner.enqueue(SteeringMessage(
            id: 'follow-1',
            content: kFollowUp,
            injectedAt: DateTime.utc(2026, 1, 1),
          ));
        }
      },
    );

    final result = await runner.run(
      missionId: 'm7',
      messages: const [ChatMessage(role: 'user', content: 'weather?')],
    );

    // The loop continued: two LLM turns, not one.
    expect(result.turnsUsed, 2);
    expect(client.contexts.length, 2);

    // The follow-up was injected, and turn 2 actually saw it.
    expect(
      events.whereType<SteeringInjected>().map((e) => e.content),
      [kFollowUp],
    );
    expect(
      client.contexts[1].map((m) => m.content),
      contains(kFollowUp),
    );

    // With the queue drained, the mission ends naturally on turn 2.
    expect(result.status, MissionStatus.completed);
    expect(result.summary, 'answer 2');
  });
}
