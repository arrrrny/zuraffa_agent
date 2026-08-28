// Spec 002 — acceptance behavior A9: identical repeated tool calls hitting the
// threshold fire `LoopDetected` and abort the mission cleanly.
//
// Drives MissionRunner (spec 069) with a planner that always asks for the SAME
// tool call. A RepetitionTracker (maxCalls: 3) wired through its datasource
// trips `loopDetected` after the 3rd identical dispatch, and the mission ends
// with that typed outcome (not a generic completed / turn-cap).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart';
import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/repetition_tracker/repetition_tracker.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient()
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

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async =>
      ChatCompletion(
        content: 'call a tool',
        finishReason: 'tool_calls',
        usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
      );
}

class FakeToolDispatcher implements ToolDispatcher {
  final List<String> toolNames = [];
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    toolNames.add(toolName);
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
  }) async =>
      [for (final c in calls) await dispatch(toolName: c.toolName, arguments: c.arguments, isInternalMission: isInternalMission)];

  @override
  List<String> validateSchema({required Map<String, dynamic> schema, required Map<String, dynamic> arguments}) => const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

class LoopPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async =>
      const [ToolCall(toolName: 'search', arguments: {'q': 'same'}, executionMode: 'sequential')];
}

void main() {
  test('A9: maxCalls=3 with a repeating tool call ends in loopDetected after the 3rd', () async {
    final events = <EngineEvent>[];
    final repetition = RepetitionTrackerMockDatasource(
      config: const RepetitionTracker(id: 'default', maxCalls: 3, window: Duration(seconds: 60)),
      clock: () => DateTime.utc(2026, 1, 1),
    );

    const loop = EngineLoop(
      id: 'loop-9',
      sessionId: 's9',
      maxTurns: 10,
      wallClockTimeoutMs: 600000,
      repetitionThreshold: 3,
    );
    const policy = StopPolicy(
      id: 'cap9',
      maxTurns: 10,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 3,
    );

    final runner = MissionRunner(
      executor: EngineLoopExecutor(loop, ScriptedLlmClient()),
      toolDispatcher: FakeToolDispatcher(),
      stopPolicy: policy,
      repetitionTracker: repetition,
      onEvent: events.add,
    );

    final result = await runner.run(
      missionId: 'm9',
      messages: const [ChatMessage(role: 'user', content: 'go')],
      planner: LoopPlanner(),
    );

    expect(result.status.name, 'loopDetected');
    expect(result.turnsUsed, 3);
    final completed = events.whereType<MissionCompleted>().single;
    expect(completed.status, 'loopDetected');
    expect(events.whereType<ToolCallCompleted>().length, 3);
  });
}
