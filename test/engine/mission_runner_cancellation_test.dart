// Cooperative-cancellation tests for the MissionRunner (issue #140).
//
// A CancellationToken injected into run()/runStream() stops the mission at
// the NEXT turn boundary: the turn in flight when cancel() landed completes
// (Dart futures are not abortable), the loop observes the signal before
// spending another turn, and the mission reports MissionStatus.cancelled —
// still ending with exactly one terminal MissionCompleted event.
//
// Fakes mirror mission_runner_test.dart: ScriptedLlmClient (no network),
// FakeToolDispatcher, ScriptedPlanner, and an injected fixed clock.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/providers/engine_loop/engine_loop_executor.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/engine_loop/engine_loop.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_dispatch_result/tool_dispatch_result.dart';
import 'package:zuraffa_agent/src/engine/cancellation_token.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/mission_runner.dart';
import 'package:zuraffa_agent/src/engine/tool_dispatcher.dart';

/// LLM client returning a FIFO script of completions; cancels the test's
/// token after a chosen 1-based call index so the signal lands MID-mission
/// (during turn N's completion, before turn N+1's checkpoint).
class CancellingLlmClient extends LlmClientProvider {
  CancellingLlmClient({required this.completions, this.cancelAfterCall})
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
  final int? cancelAfterCall;
  CancellationToken? token;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    final completion = completions[callCount - 1];
    if (cancelAfterCall == callCount) {
      token?.cancel();
    }
    return completion;
  }
}

/// Records every dispatch; returns a scripted result per tool name.
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
  }) async => [
    for (final call in calls)
      await dispatch(
        toolName: call.toolName,
        arguments: call.arguments,
        isInternalMission: isInternalMission,
      ),
  ];

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

/// Plans one tool call on the first completion only — forces a second turn.
class OneShotPlanner implements ToolCallPlanner {
  bool planned = false;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    if (planned) return const [];
    planned = true;
    return const [
      ToolCall(
        toolName: 'search',
        arguments: {'q': 'zuraffa'},
        executionMode: 'sequential',
      ),
    ];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      ),
    );

const loop10 = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

const policy = StopPolicy(
  id: 'test',
  maxTurns: 100,
  wallClockTimeout: Duration.zero,
  repetitionThreshold: 5,
);

MissionRunner makeRunner(
  CancellingLlmClient llm, {
  required List<EngineEvent> events,
}) => MissionRunner(
  executor: EngineLoopExecutor(loop10, llm),
  toolDispatcher: FakeToolDispatcher(),
  stopPolicy: policy,
  onEvent: events.add,
  clock: () => DateTime.utc(2026, 1, 1),
);

void main() {
  group('MissionRunner cooperative cancellation (issue #140)', () {
    test('a pre-cancelled token stops the mission before turn 1', () async {
      final events = <EngineEvent>[];
      final llm = CancellingLlmClient(completions: [completionOf('nope')]);
      final token = CancellationToken()..cancel();
      llm.token = token;
      final runner = makeRunner(llm, events: events);

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        cancellationToken: token,
      );

      expect(result.status, MissionStatus.cancelled);
      expect(result.turnsUsed, 0);
      expect(
        llm.callCount,
        0,
        reason:
            'no turn may be spent when the '
            'token is already signalled',
      );
      expect(result.transcript, const [
        ChatMessage(role: 'user', content: 'go'),
      ]);
      expect(events.last, isA<MissionCompleted>());
      expect(
        events.whereType<MissionCompleted>().length,
        1,
        reason: 'exactly one terminal event, as on every exit path',
      );
      expect((events.last as MissionCompleted).status, 'cancelled');
    });

    test(
      'a token cancelled mid-mission stops at the next turn boundary',
      () async {
        final events = <EngineEvent>[];
        final llm = CancellingLlmClient(
          completions: [
            completionOf('searching', finish: 'tool_calls'),
            completionOf('never reached'),
          ],
          cancelAfterCall: 1,
        );
        final token = CancellationToken();
        llm.token = token;
        final runner = makeRunner(llm, events: events);

        final result = await runner.run(
          missionId: 'm2',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          planner: OneShotPlanner(),
          cancellationToken: token,
        );

        // Turn 1 completed (its completion + tool result are in the
        // transcript — Dart futures cannot be aborted); the checkpoint
        // before turn 2 observed the signal and stopped the mission.
        expect(result.status, MissionStatus.cancelled);
        expect(result.turnsUsed, 1);
        expect(llm.callCount, 1);
        expect(result.transcript.map((m) => m.role), [
          'user',
          'assistant',
          'tool',
        ]);
        expect(events.last, isA<MissionCompleted>());
        expect(events.whereType<MissionCompleted>().single.status, 'cancelled');
      },
    );

    test('the same script WITHOUT cancellation runs to natural completion '
        '(control)', () async {
      final events = <EngineEvent>[];
      final llm = CancellingLlmClient(
        completions: [
          completionOf('searching', finish: 'tool_calls'),
          completionOf('done'),
        ],
      );
      final runner = makeRunner(llm, events: events);

      final result = await runner.run(
        missionId: 'm3',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: OneShotPlanner(),
      );

      expect(result.status, MissionStatus.completed);
      expect(result.turnsUsed, 2);
      expect(result.summary, 'done');
    });

    test('runStream honours the token too (pre-cancelled)', () async {
      final events = <EngineEvent>[];
      final llm = CancellingLlmClient(completions: [completionOf('nope')]);
      final token = CancellationToken()..cancel();
      llm.token = token;
      final runner = makeRunner(llm, events: events);

      final result = await runner.runStream(
        missionId: 'm4',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        cancellationToken: token,
      );

      expect(result.status, MissionStatus.cancelled);
      expect(result.turnsUsed, 0);
      expect(llm.callCount, 0);
    });
  });
}
