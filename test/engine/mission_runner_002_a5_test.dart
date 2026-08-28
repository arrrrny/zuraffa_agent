// Spec 002 — acceptance behavior A5: in a multi-turn mission, prior turns'
// thinking blocks are present when turn N+1's context is assembled.
//
// A4 proved the assistant message *carries* the block. A5 is the stronger
// claim: the block is still there in the message list the executor is handed
// for the NEXT turn — nothing strips it between turns (FR-002). The client
// records the context it received on each turn and the test asserts against
// turn 2's context, not against the final transcript.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

const kThinkingTurn1 = 'Turn one reasoning: I must look up the forecast first.';
const kThinkingTurn2 = 'Turn two reasoning: the forecast is in, I can answer.';

/// Records the context handed to it on every turn.
class RecordingThinkingClient extends LlmClientProvider {
  RecordingThinkingClient()
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
    final turn = contexts.length;
    return ChatCompletion(
      content: turn == 1 ? 'looking it up' : 'it will be sunny',
      reasoning: turn == 1 ? kThinkingTurn1 : kThinkingTurn2,
      finishReason: turn == 1 ? 'tool_calls' : 'stop',
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );
  }
}

class OkToolDispatcher implements ToolDispatcher {
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

class ToolCallsPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async =>
      completion.finishReason == 'tool_calls'
          ? const [
              ToolCall(
                toolName: 'forecast',
                arguments: {'city': 'lisbon'},
                executionMode: 'sequential',
              )
            ]
          : const [];
}

void main() {
  test("A5: turn 2's assembled context still carries turn 1's thinking block",
      () async {
    const loop = EngineLoop(
      id: 'loop-5',
      sessionId: 's5',
      maxTurns: 4,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 10,
    );
    const policy = StopPolicy(
      id: 'cap5',
      maxTurns: 4,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 10,
    );

    final client = RecordingThinkingClient();
    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, client),
      toolDispatcher: OkToolDispatcher(),
      stopPolicy: policy,
      onEvent: (_) {},
    );

    await runner.run(
      missionId: 'm5',
      messages: const [ChatMessage(role: 'user', content: 'forecast?')],
      planner: ToolCallsPlanner(),
    );

    expect(client.contexts.length, 2, reason: 'the mission ran two turns');

    // Turn 1 saw only the user message — no thinking to preserve yet.
    expect(client.contexts.first.map((m) => m.thinking), everyElement(isNull));

    // Turn 2's context: the prior turn's assistant message is present AND
    // still carries its thinking block.
    final turn2 = client.contexts[1];
    final priorAssistant =
        turn2.where((m) => m.role == 'assistant').single;
    expect(priorAssistant.thinking, kThinkingTurn1);

    // And the wire form the gateway receives keeps it too.
    expect(priorAssistant.toJson()['thinking'], kThinkingTurn1);
  });
}
