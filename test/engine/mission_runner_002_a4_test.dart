// Spec 002 — acceptance behavior A4: given a provider streaming thinking
// deltas, when a turn completes, the assistant message carries thinking blocks
// next to tool calls.
//
// The provider returns a completion whose `reasoning` holds the thinking text.
// At turn completion the transcript's assistant message must carry that
// thinking alongside the turn's tool-role result — not drop it (FR-002).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

const kThinking = 'The user wants the weather; I should call the search tool.';

class ThinkingLlmClient extends LlmClientProvider {
  ThinkingLlmClient()
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

  int calls = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    calls++;
    return ChatCompletion(
      content: calls == 1 ? 'calling a tool' : 'done',
      reasoning: calls == 1 ? kThinking : null,
      finishReason: calls == 1 ? 'tool_calls' : 'stop',
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
        result: 'sunny',
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

class OneShotPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async =>
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
  test('A4: a completed turn leaves the assistant message carrying its thinking '
      'block next to the tool result', () async {
    const loop = EngineLoop(
      id: 'loop-4',
      sessionId: 's4',
      maxTurns: 4,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 10,
    );
    const policy = StopPolicy(
      id: 'cap4',
      maxTurns: 4,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 10,
    );

    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, ThinkingLlmClient()),
      toolDispatcher: OkToolDispatcher(),
      stopPolicy: policy,
      onEvent: (_) {},
    );

    final result = await runner.run(
      missionId: 'm4',
      messages: const [ChatMessage(role: 'user', content: 'weather?')],
      planner: OneShotPlanner(),
    );

    final assistantMessages =
        result.transcript.where((m) => m.role == 'assistant').toList();
    expect(assistantMessages.first.thinking, kThinking);

    // "next to tool calls": the thinking-bearing assistant message is
    // immediately followed by the tool-role result of that same turn.
    final index = result.transcript.indexOf(assistantMessages.first);
    expect(result.transcript[index + 1].role, 'tool');

    // A turn without reasoning carries no thinking block.
    expect(assistantMessages.last.thinking, isNull);
  });
}
