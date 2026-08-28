// Tests for the MissionRunner multi-turn mission loop (spec 069).
//
// Fakes: ScriptedLlmClient (no network), FakeToolDispatcher, ScriptedPlanner,
// and an injected fixed clock so every emittedAt is deterministic.

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

/// LLM client returning a FIFO script of completions; optionally throws on a
/// 1-based call index and lets the test advance the fake clock after each call.
class ScriptedLlmClient extends LlmClientProvider {
  ScriptedLlmClient({required this.completions, this.throwOnCall})
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
  final int? throwOnCall;
  int callCount = 0;
  void Function(int call)? afterCall;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    if (throwOnCall == callCount) {
      throw StateError('provider down (call $callCount)');
    }
    final completion = completions[callCount - 1];
    afterCall?.call(callCount);
    return completion;
  }
}

/// Records every dispatch; returns scripted results by tool name.
class FakeToolDispatcher implements ToolDispatcher {
  FakeToolDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;
  final List<({String toolName, Map<String, dynamic> arguments, bool isInternalMission})>
      calls = [];

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
    return resultsByTool[toolName] ??
        ToolDispatchResult(
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
  }) =>
      const [];

  @override
  bool checkRiskTier({required String riskTier, required bool isInternalMission}) => true;
}

/// Plans tool calls by 1-based completion index; records what it saw.
class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByCall);

  final Map<int, List<ToolCall>> planByCall;
  final List<({ChatCompletion completion, int transcriptLength})> invocations = [];
  List<ChatMessage>? lastTranscript;

  @override
  Future<List<ToolCall>> plan(ChatCompletion completion, List<ChatMessage> transcript) async {
    _count++;
    invocations.add((completion: completion, transcriptLength: transcript.length));
    lastTranscript = transcript;
    return planByCall[_count] ?? const [];
  }

  int _count = 0;
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) => ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
    );

const loop10 = EngineLoop(
  id: 'loop-1',
  sessionId: 's1',
  maxTurns: 10,
  wallClockTimeoutMs: 60000,
  repetitionThreshold: 5,
);

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  MissionRunner makeRunner(
    ScriptedLlmClient llm, {
    required List<EngineEvent> events,
    FakeToolDispatcher? dispatcher,
    StopPolicy policy = const StopPolicy(
      id: 'test',
      maxTurns: 100,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 5,
    ),
    SteeringQueue? queue,
  }) =>
      MissionRunner(
        executor: EngineLoopExecutor(loop10, llm),
        toolDispatcher: dispatcher ?? FakeToolDispatcher(),
        stopPolicy: policy,
        steeringQueue: queue,
        onEvent: events.add,
        clock: fakeClock,
      );

  group('spec 069 — MissionRunner', () {
    test('natural single-turn mission emits the full ordered event sequence', () async {
      final events = <EngineEvent>[];
      final dispatcher = FakeToolDispatcher();
      final runner = makeRunner(
        ScriptedLlmClient(completions: [completionOf('hello done')]),
        events: events,
        dispatcher: dispatcher,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(
        events.map((e) => e.runtimeType),
        [MissionStarted, TurnStarted, TurnCompleted, MissionCompleted],
      );
      final started = events[0] as MissionStarted;
      expect(started.missionId, 'm1');
      expect(started.startedAt, DateTime.utc(2026, 1, 1));
      expect(started.emittedAt, DateTime.utc(2026, 1, 1));
      final completed = events.last as MissionCompleted;
      expect(completed.missionId, 'm1');
      expect(completed.status, 'completed');
      expect(completed.summary, 'hello done');
      expect(dispatcher.calls, isEmpty);
      expect(result.status, MissionStatus.completed);
    });

    test('natural completion returns completed status, summary, and grown transcript',
        () async {
      final events = <EngineEvent>[];
      final runner = makeRunner(
        ScriptedLlmClient(completions: [completionOf('hello done')]),
        events: events,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(result.missionId, 'm1');
      expect(result.status, MissionStatus.completed);
      expect(result.turnsUsed, 1);
      expect(result.summary, 'hello done');
      expect(result.transcript.map((m) => m.role), ['user', 'assistant']);
      expect(result.transcript.last.content, 'hello done');
    });

    test('tool dispatch round-trip emits correlated events and feeds results back',
        () async {
      final events = <EngineEvent>[];
      final dispatcher = FakeToolDispatcher();
      final planner = ScriptedPlanner({
        1: [
          const ToolCall(
            toolName: 'search',
            arguments: {'q': 'zuraffa'},
            executionMode: 'sequential',
          ),
        ],
      });
      final runner = makeRunner(
        ScriptedLlmClient(completions: [
          completionOf('need tool', finish: 'tool_calls'),
          completionOf('all done'),
        ]),
        events: events,
        dispatcher: dispatcher,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: planner,
      );

      expect(
        events.map((e) => e.runtimeType),
        [
          MissionStarted,
          TurnStarted,
          ToolCallStarted,
          ToolCallCompleted,
          TurnCompleted,
          TurnStarted,
          TurnCompleted,
          MissionCompleted,
        ],
      );
      final startedCall = events[2] as ToolCallStarted;
      final completedCall = events[3] as ToolCallCompleted;
      expect(startedCall.callId, 'm1-call-1-0');
      expect(completedCall.callId, 'm1-call-1-0');
      expect(startedCall.toolName, 'search');
      expect(completedCall.toolName, 'search');
      expect(completedCall.ok, isTrue);

      expect(dispatcher.calls, hasLength(1));
      expect(dispatcher.calls.single.toolName, 'search');
      expect(dispatcher.calls.single.isInternalMission, isFalse);
      expect(dispatcher.calls.single.arguments, {'q': 'zuraffa'});

      expect(result.transcript.map((m) => m.role), ['user', 'assistant', 'tool', 'assistant']);
      expect(result.transcript[2].content, 'ok:search');
      expect(result.status, MissionStatus.completed);
      expect(result.turnsUsed, 2);
      expect(result.summary, 'all done');

      // planner seam: consulted after EVERY turn (its output participates in
      // the stop decision — FR-002), so turn 1 ('need tool', 2-message
      // transcript) and turn 2 ('all done', 4-message transcript) both hit it.
      expect(planner.invocations, hasLength(2));
      expect(planner.invocations[0].completion.content, 'need tool');
      expect(planner.invocations[0].transcriptLength, 2);
      expect(planner.invocations[1].completion.content, 'all done');
      expect(planner.invocations[1].transcriptLength, 4);
    });

    test('failed tool dispatch reports ok:false and the error text, mission continues',
        () async {
      final events = <EngineEvent>[];
      final dispatcher = FakeToolDispatcher({
        'broken': ToolDispatchResult(
          success: false,
          result: '',
          error: 'exploded',
          artifactRefs: const [],
        ),
      });
      final planner = ScriptedPlanner({
        1: [
          const ToolCall(
            toolName: 'broken',
            arguments: {},
            executionMode: 'sequential',
          ),
        ],
      });
      final runner = makeRunner(
        ScriptedLlmClient(completions: [
          completionOf('try tool', finish: 'tool_calls'),
          completionOf('recovered'),
        ]),
        events: events,
        dispatcher: dispatcher,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: planner,
      );

      final completedCall =
          events.whereType<ToolCallCompleted>().single;
      expect(completedCall.ok, isFalse);
      expect(completedCall.toolName, 'broken');
      expect(result.transcript[2].role, 'tool');
      expect(result.transcript[2].content, 'exploded');
      expect(result.status, MissionStatus.completed);
      expect(result.summary, 'recovered');
    });

    test('steering queue drains at turn start in FIFO order', () async {
      final events = <EngineEvent>[];
      final queue = SteeringQueue(
        id: 'q1',
        pending: [
          SteeringMessage(
            id: 'sm1',
            content: 'steer one',
            injectedAt: DateTime.utc(2025, 12, 31),
          ),
          SteeringMessage(
            id: 'sm2',
            content: 'steer two',
            injectedAt: DateTime.utc(2025, 12, 31, 0, 0, 1),
          ),
        ],
        processedCount: 0,
      );
      final runner = makeRunner(
        ScriptedLlmClient(completions: [completionOf('steered done')]),
        events: events,
        queue: queue,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(
        events.map((e) => e.runtimeType),
        [
          MissionStarted,
          SteeringInjected,
          SteeringInjected,
          TurnStarted,
          TurnCompleted,
          MissionCompleted,
        ],
      );
      final first = events[1] as SteeringInjected;
      final second = events[2] as SteeringInjected;
      expect(first.content, 'steer one');
      expect(first.injectedAt, DateTime.utc(2025, 12, 31));
      expect(second.content, 'steer two');
      expect(second.injectedAt, DateTime.utc(2025, 12, 31, 0, 0, 1));

      expect(result.transcript.map((m) => m.role), ['user', 'user', 'user', 'assistant']);
      expect(result.transcript[1].content, 'steer one');
      expect(result.transcript[2].content, 'steer two');
    });

    test('maxTurns budget stops the mission before the executor backstop', () async {
      final events = <EngineEvent>[];
      final dispatcher = FakeToolDispatcher();
      final planner = ScriptedPlanner({
        1: [
          const ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
        ],
        2: [
          const ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
        ],
      });
      final runner = makeRunner(
        ScriptedLlmClient(completions: [
          completionOf('t1', finish: 'tool_calls'),
          completionOf('t2', finish: 'tool_calls'),
        ]),
        events: events,
        dispatcher: dispatcher,
        policy: const StopPolicy(
          id: 'tight',
          maxTurns: 2,
          wallClockTimeout: Duration.zero,
          repetitionThreshold: 5,
        ),
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: planner,
      );

      expect(result.turnsUsed, 2);
      expect(result.status, MissionStatus.budgetExhausted);
      expect((events.last as MissionCompleted).status, 'budgetExhausted');
      expect(dispatcher.calls, hasLength(2));
      expect(planner.invocations, hasLength(2));
    });

    test('wall-clock deadline stops the mission between turns', () async {
      final events = <EngineEvent>[];
      final llm = ScriptedLlmClient(completions: [
        completionOf('working', finish: 'tool_calls'),
      ]);
      llm.afterCall = (_) => fakeNow = fakeNow.add(const Duration(seconds: 10));
      final planner = ScriptedPlanner({
        1: [
          const ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
        ],
      });
      final runner = makeRunner(
        llm,
        events: events,
        policy: const StopPolicy(
          id: 'clocked',
          maxTurns: 10,
          wallClockTimeout: Duration(seconds: 5),
          repetitionThreshold: 5,
        ),
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: planner,
      );

      expect(result.turnsUsed, 1);
      expect(result.status, MissionStatus.budgetExhausted);
      expect((events.last as MissionCompleted).status, 'budgetExhausted');
    });

    test('provider failure emits ProviderError and still closes the mission', () async {
      final events = <EngineEvent>[];
      final runner = makeRunner(
        ScriptedLlmClient(completions: [], throwOnCall: 1),
        events: events,
      );

      final result = await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(
        events.map((e) => e.runtimeType),
        [MissionStarted, TurnStarted, ProviderError, MissionCompleted],
      );
      final error = events[2] as ProviderError;
      expect(error.providerName, 'kilo');
      expect(error.error, contains('provider down'));
      expect(result.status, MissionStatus.providerFailed);
      expect(result.turnsUsed, 1);
      expect(result.summary, isNull);
      expect((events.last as MissionCompleted).status, 'providerFailed');
      expect((events.last as MissionCompleted).summary, isNull);
    });

    test('MissionResult value semantics', () {
      final a = MissionResult(
        missionId: 'm',
        status: MissionStatus.completed,
        turnsUsed: 1,
        transcript: const [ChatMessage(role: 'user', content: 'x')],
        summary: 's',
      );
      final b = MissionResult(
        missionId: 'm',
        status: MissionStatus.completed,
        turnsUsed: 1,
        transcript: const [ChatMessage(role: 'user', content: 'x')],
        summary: 's',
      );
      final c = MissionResult(
        missionId: 'm',
        status: MissionStatus.completed,
        turnsUsed: 2,
        transcript: const [ChatMessage(role: 'user', content: 'x')],
        summary: 's',
      );

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('m'));
      expect(a.toString(), contains('completed'));
      expect(a.toString(), contains('1'));
    });

    test('planner receives an unmodifiable transcript view', () async {
      final events = <EngineEvent>[];
      final planner = ScriptedPlanner({
        1: [
          const ToolCall(toolName: 'search', arguments: {}, executionMode: 'sequential'),
        ],
      });
      final runner = makeRunner(
        ScriptedLlmClient(completions: [
          completionOf('need tool', finish: 'tool_calls'),
          completionOf('done'),
        ]),
        events: events,
      );
      await runner.run(
        missionId: 'm1',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: planner,
      );

      expect(planner.lastTranscript, isNotNull);
      expect(
        () => planner.lastTranscript!.add(const ChatMessage(role: 'user', content: 'nope')),
        throwsUnsupportedError,
      );
    });
  });
}
