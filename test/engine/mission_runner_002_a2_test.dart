// Spec 002 — acceptance behavior A2: a scripted 200-call mission completes
// without state corruption or event loss.
//
// Drives MissionRunner (spec 069) end-to-end with a scripted LLM that returns
// `tool_calls` for the first 199 turns then `stop`, and a planner that asks for
// exactly one tool call per turn. Both the loop cap and the stop-policy cap must
// allow >= 200 turns, otherwise the mission would stop early on budget — which
// is exactly what this test pins against.
//
// Fakes mirror test/engine/mission_runner_test.dart (spec 069); kept local so
// this acceptance test for 002 stays isolated from 069's test file. A follow-up
// could extract the shared fakes into a helper.

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

const _turns = 200;

class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient({required this.completions})
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

  final List<ChatCompletion> completions;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    return completions[callCount - 1];
  }
}

class FakeToolDispatcher implements ToolDispatcher {
  final List<({String toolName, Map<String, dynamic> arguments, bool isInternalMission})> calls = [];

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    calls.add((
      toolName: toolName,
      arguments: arguments,
      isInternalMission: isInternalMission,
    ));
    return ToolDispatchResult(
      success: true,
      result: 'ok:$toolName',
      error: '',
      artifactRefs: const [],
    );
  }

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => [for (final c in calls) await dispatch(toolName: c.toolName, arguments: c.arguments, isInternalMission: isInternalMission)];

  @override
  List<String> validateSchema({required Map<String, dynamic> schema, required Map<String, dynamic> arguments}) => const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.perTurn);
  final int perTurn;
  int _count = 0;

  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async {
    _count++;
    // Model only wants tools when it explicitly asked (finishReason == 'tool_calls').
    // On the natural stop turn it returns nothing, which ends the mission.
    if (completion.finishReason != 'tool_calls') return const [];
    return [
      for (var i = 0; i < perTurn; i++)
        const ToolCall(toolName: 'search', arguments: {'q': 'x'}, executionMode: 'sequential'),
    ];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) => ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

void main() {
  test('A2: a 200-call mission completes with no event loss or state corruption', () async {
    final events = <EngineEvent>[];
    final dispatcher = FakeToolDispatcher();

    // First 199 turns ask for a tool call; the 200th is the natural stop.
    final completions = [
      for (var i = 0; i < _turns - 1; i++) completionOf('turn-$i', finish: 'tool_calls'),
      completionOf('final-answer'),
    ];

    // Both budgets must allow the full 200 turns, else the loop stops early.
    const loop = EngineLoop(
      id: 'loop-200',
      sessionId: 's1',
      maxTurns: 250,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 1000,
    );
    const policy = StopPolicy(
      id: 'wide',
      maxTurns: 250,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 1000,
    );

    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, ScriptedLlmClient(completions: completions)),
      toolDispatcher: dispatcher,
      stopPolicy: policy,
      onEvent: events.add,
    );

    final result = await runner.run(
      missionId: 'm200',
      messages: const [ChatMessage(role: 'user', content: 'go')],
      planner: ScriptedPlanner(1),
    );

    // Terminal state.
    expect(result.status, MissionStatus.completed);
    expect(result.turnsUsed, _turns);
    expect(result.summary, 'final-answer');
    expect(events.first, isA<MissionStarted>());
    expect(events.last, isA<MissionCompleted>());

    // No event loss: every turn emits TurnStarted/TurnCompleted; tool calls on
    // turns 1..199 emit ToolCallStarted/ToolCallCompleted; the final turn does not.
    expect(events.whereType<TurnStarted>().length, _turns);
    expect(events.whereType<TurnCompleted>().length, _turns);
    expect(events.whereType<ToolCallStarted>().length, _turns - 1);
    expect(events.whereType<ToolCallCompleted>().length, _turns - 1);
    expect(events.length, 1 + _turns * 2 + (_turns - 1) * 2 + 1);

    // No state corruption: every tool call was dispatched once, transcript grows
    // by exactly two messages per tool turn + one on the final turn.
    expect(dispatcher.calls, hasLength(_turns - 1));
    expect(result.transcript.length, 1 + (_turns - 1) * 2 + 1);
    expect(result.transcript.last.role, 'assistant');
    expect(result.transcript.last.content, 'final-answer');
  });
}
