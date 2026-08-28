// Spec 002 — acceptance behavior A8: with maxTurns=5 and a model that never
// stops calling tools, the mission ends with a typed MaxTurnsExceeded outcome
// after turn 5 (not a generic budget-exhausted).
//
// Drives MissionRunner (spec 069) with a planner that always asks for a tool
// call, so the loop can only terminate on the turn cap. Self-contained fakes
// mirror spec 069's test.

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

class AlwaysToolPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async =>
      const [ToolCall(toolName: 'search', arguments: {'q': 'x'}, executionMode: 'sequential')];
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) => ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

void main() {
  test('A8: maxTurns=5 with a non-stopping model ends in MaxTurnsExceeded after turn 5', () async {
    final events = <EngineEvent>[];

    // Model never stops: every turn asks for a tool call.
    final completions = [
      for (var i = 0; i < 10; i++) completionOf('turn-$i', finish: 'tool_calls'),
    ];

    const loop = EngineLoop(
      id: 'loop-5',
      sessionId: 's1',
      maxTurns: 5,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 1000,
    );
    const policy = StopPolicy(
      id: 'cap5',
      maxTurns: 5,
      wallClockTimeout: Duration.zero, // no wall-clock deadline; stop is purely turn-cap
      repetitionThreshold: 1000,
    );

    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, ScriptedLlmClient(completions: completions)),
      toolDispatcher: FakeToolDispatcher(),
      stopPolicy: policy,
      onEvent: events.add,
    );

    final result = await runner.run(
      missionId: 'm8',
      messages: const [ChatMessage(role: 'user', content: 'go')],
      planner: AlwaysToolPlanner(),
    );

    expect(result.turnsUsed, 5);
    expect(result.status.name, "maxTurnsExceeded");
    final completed = events.whereType<MissionCompleted>().single;
    expect(completed.status, 'maxTurnsExceeded');
    expect(dispatcher(allCalls: events), 5);
  });
}

// Small helper so the test reads cleanly; counts tool dispatches via events.
int dispatcher({required List<EngineEvent> allCalls}) => allCalls.whereType<ToolCallCompleted>().length;
