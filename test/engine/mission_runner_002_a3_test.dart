// Spec 002 — acceptance behavior A3: identical inputs + a recorded LLM re-run
// 10x produce a byte-identical event stream (determinism).
//
// Drives MissionRunner (spec 069) 10 times with the SAME scripted LLM, planner,
// and an INJECTED FIXED clock, then asserts every run yields the identical
// event stream (exhaustive field key over the sealed EngineEvent union) and an
// identical MissionResult. Self-contained fakes mirror spec 069's test.

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

const _runs = 10;

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
  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async {
    if (completion.finishReason != 'tool_calls') return const [];
    return const [ToolCall(toolName: 'search', arguments: {'q': 'x'}, executionMode: 'sequential')];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) => ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

/// Exhaustive, content-bearing key for one event — stands in for a serialized
/// event stream. Covers every subtype of the sealed EngineEvent union.
String eventKey(EngineEvent e) => switch (e) {
      MissionStarted(:final emittedAt, :final missionId, :final startedAt) =>
        'MissionStarted|$emittedAt|$missionId|$startedAt',
      MissionCompleted(:final emittedAt, :final missionId, :final status, :final summary) =>
        'MissionCompleted|$emittedAt|$missionId|$status|$summary',
      TurnStarted(:final emittedAt, :final turnId) => 'TurnStarted|$emittedAt|$turnId',
      TurnCompleted(:final emittedAt, :final reason) => 'TurnCompleted|$emittedAt|$reason',
      ToolCallStarted(:final emittedAt, :final toolName, :final callId) =>
        'ToolCallStarted|$emittedAt|$toolName|$callId',
      ToolCallCompleted(:final emittedAt, :final toolName, :final callId, :final ok) =>
        'ToolCallCompleted|$emittedAt|$toolName|$callId|$ok',
      ThinkingDelta(:final emittedAt, :final delta) => 'ThinkingDelta|$emittedAt|$delta',
      SteeringInjected(:final emittedAt, :final content, :final injectedAt) =>
        'SteeringInjected|$emittedAt|$content|$injectedAt',
      ProviderError(:final emittedAt, :final providerName, :final error) =>
        'ProviderError|$emittedAt|$providerName|$error',
    };

void main() {
  test('A3: 10 identical runs produce a byte-identical event stream', () async {
    // Fixed clock so every emittedAt is constant across runs.
    final fixedClock = () => DateTime.utc(2026, 1, 1);

    // Build a fresh runner per run (no shared mutable state between runs).
    Future<(List<String>, MissionResult)> runOnce() async {
      final events = <EngineEvent>[];
      final completions = [
        completionOf('t1', finish: 'tool_calls'),
        completionOf('t2', finish: 'tool_calls'),
        completionOf('done'),
      ];
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          const EngineLoop(id: 'l', sessionId: 's', maxTurns: 50, wallClockTimeoutMs: 60000, repetitionThreshold: 5),
          ScriptedLlmClient(completions: completions),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: const StopPolicy(id: 'p', maxTurns: 50, wallClockTimeout: Duration.zero, repetitionThreshold: 5),
        onEvent: events.add,
        clock: fixedClock,
      );
      final result = await runner.run(
        missionId: 'det',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: ScriptedPlanner(),
      );
      return (events.map(eventKey).toList(), result);
    }

    final streams = <List<String>>[];
    final results = <MissionResult>[];
    for (var i = 0; i < _runs; i++) {
      final (stream, result) = await runOnce();
      streams.add(stream);
      results.add(result);
    }

    // Every run's serialized event stream equals the first.
    final first = streams.first.join('\n');
    for (var i = 1; i < _runs; i++) {
      expect(streams[i].join('\n'), first, reason: 'run $i stream diverged from run 0');
    }

    // And the terminal outcome is identical across runs.
    for (var i = 1; i < _runs; i++) {
      expect(results[i], results.first);
    }
    expect(results.first.status, MissionStatus.completed);
    expect(results.first.summary, 'done');
  });
}
