// spec 107 (issue #121) — the MissionRunner fail-fast config gate.
//
// Fakes mirror the spec 069 exemplar (ScriptedLlmClient / FakeToolDispatcher)
// so the gate is proven through a real mission composition.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/config/zuraffa_config.dart';
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
          id: 'test-provider',
          providerKind: 'openai',
          baseUrl: 'https://example.invalid/v1',
          models: ['test/model'],
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
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async => ToolDispatchResult(
    success: true,
    result: 'ok:$toolName',
    error: '',
    artifactRefs: const [],
  );

  @override
  Future<List<ToolDispatchResult>> dispatchBatch({
    required List<ToolCall> calls,
    required bool isInternalMission,
  }) async => const [];

  @override
  List<String> validateSchema({
    required Map<String, dynamic> schema,
    required Map<String, dynamic> arguments,
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

ChatCompletion completionOf(String content) => ChatCompletion(
  content: content,
  finishReason: 'stop',
  usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
);

const loop10 = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

final provider = ProviderConfig(
  id: 'p1',
  providerKind: 'openai',
  baseUrl: 'https://llm.example.internal/api',
  models: const ['internal/model'],
  timeoutMs: 30000,
);

DateTime fakeClock() => DateTime.utc(2026, 1, 1);

void main() {
  group('spec 107 — MissionRunner config gate (issue #121)', () {
    test(
      'U12: an invalid configuration throws before any event or call',
      () async {
        final events = <EngineEvent>[];
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(completions: [completionOf('never reached')]),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: const StopPolicy(
            id: 'test',
            maxTurns: 100,
            wallClockTimeout: Duration.zero,
            repetitionThreshold: 5,
          ),
          onEvent: events.add,
          clock: fakeClock,
          // Invalid: engine loop configured but no provider section, and the
          // loop's maxTurns is non-positive — two distinct typed issues.
          config: ZuraffaConfig(
            engineLoop: const EngineLoop(
              id: 'loop-bad',
              sessionId: 's1',
              maxTurns: 0,
              wallClockTimeoutMs: 0,
              repetitionThreshold: 5,
            ),
          ),
        );

        await expectLater(
          runner.run(
            missionId: 'm1',
            messages: const [ChatMessage(role: 'user', content: 'go')],
          ),
          throwsA(
            predicate(
              (Object e) =>
                  e is StateError &&
                  e.message.contains('providerConfig') &&
                  e.message.contains('engineLoop.maxTurns'),
            ),
          ),
        );
        expect(events, isEmpty); // zero events — failed before MissionStarted
      },
    );

    test('U13: a valid configuration runs the mission unchanged', () async {
      final events = <EngineEvent>[];
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: [completionOf('hello done')]),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: const StopPolicy(
          id: 'test',
          maxTurns: 100,
          wallClockTimeout: Duration.zero,
          repetitionThreshold: 5,
        ),
        onEvent: events.add,
        clock: fakeClock,
        config: ZuraffaConfig(providerConfig: provider, engineLoop: loop10),
      );

      final result = await runner.run(
        missionId: 'm2',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );
      expect(result.status, MissionStatus.completed);
      expect(events.map((e) => e.runtimeType).first, MissionStarted);
    });

    test('U14: no configuration behaves exactly as before', () async {
      final events = <EngineEvent>[];
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: [completionOf('hello done')]),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: const StopPolicy(
          id: 'test',
          maxTurns: 100,
          wallClockTimeout: Duration.zero,
          repetitionThreshold: 5,
        ),
        onEvent: events.add,
        clock: fakeClock,
      );

      final result = await runner.run(
        missionId: 'm3',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );
      expect(result.status, MissionStatus.completed);
      expect(events, hasLength(4));
    });
  });
}
