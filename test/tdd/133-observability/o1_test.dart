// Tests for issue arrrrny/zuraffa_agent#133 — O-1: tracing spans.
//
// One span per MissionRunner.run ('mission.run'), child spans per turn
// ('engine.turn') and per tool dispatch ('tool.dispatch'), W3C traceparent
// propagation, and a no-op default tracer that costs nothing when
// observability is not injected.
//
// Fakes mirror test/engine/mission_runner_test.dart (ScriptedLlmClient,
// FakeToolDispatcher, ScriptedPlanner, fixed clock).

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
import 'package:zuraffa_agent/src/observability/tracing.dart';

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

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    if (throwOnCall == callCount) {
      throw StateError('provider down (call $callCount)');
    }
    return completions[callCount - 1];
  }
}

class FakeToolDispatcher implements ToolDispatcher {
  FakeToolDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;
  int dispatchCount = 0;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    dispatchCount++;
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
  }) => const [];

  @override
  bool checkRiskTier({
    required String riskTier,
    required bool isInternalMission,
  }) => true;
}

class ScriptedPlanner implements ToolCallPlanner {
  ScriptedPlanner(this.planByCall);

  final Map<int, List<ToolCall>> planByCall;
  int _count = 0;

  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    _count++;
    return planByCall[_count] ?? const [];
  }
}

ChatCompletion completionOf(String content, {String finish = 'stop'}) =>
    ChatCompletion(
      content: content,
      finishReason: finish,
      usage: const TokenUsage(
        promptTokens: 10,
        completionTokens: 5,
        totalTokens: 15,
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

final _traceparentShape = RegExp(r'^00-[0-9a-f]{32}-[0-9a-f]{16}-01$');

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  group('133 O-1 — tracing spans', () {
    test(
      'one mission.run span with child engine.turn spans and tool.dispatch spans',
      () async {
        final tracer = RecordingTracer();
        final events = <EngineEvent>[];
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(
              completions: [
                completionOf('step1', finish: 'tool_calls'),
                completionOf('all done'),
              ],
            ),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: events.add,
          clock: fakeClock,
          tracer: tracer,
        );

        final result = await runner.run(
          missionId: 'm-trace',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          planner: ScriptedPlanner({
            1: [
              ToolCall(
                toolName: 'search',
                arguments: {'q': 'x'},
                executionMode: 'sequential',
              ),
            ],
          }),
        );

        expect(result.status, MissionStatus.completed);
        final missions = tracer.spans
            .where((s) => s.name == 'mission.run')
            .toList();
        expect(missions, hasLength(1));
        final mission = missions.single;
        expect(mission.attributes['mission.id'], 'm-trace');
        expect(mission.attributes['mission.status'], 'completed');
        expect(mission.isEnded, isTrue);

        final turns = tracer.spans
            .where((s) => s.name == 'engine.turn')
            .toList();
        expect(turns, hasLength(2));
        for (final turn in turns) {
          expect(turn.parentTraceparent, mission.traceparent);
          expect(turn.isEnded, isTrue);
        }

        final dispatches = tracer.spans
            .where((s) => s.name == 'tool.dispatch')
            .toList();
        expect(dispatches, hasLength(1));
        expect(dispatches.single.parentTraceparent, mission.traceparent);
        expect(dispatches.single.attributes['tool.name'], 'search');
      },
    );

    test('provider failure records the error on the mission span', () async {
      final tracer = RecordingTracer();
      final events = <EngineEvent>[];
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: const [], throwOnCall: 1),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: policy,
        onEvent: events.add,
        clock: fakeClock,
        tracer: tracer,
      );

      final result = await runner.run(
        missionId: 'm-fail',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(result.status, MissionStatus.providerFailed);
      final mission = tracer.spans.where((s) => s.name == 'mission.run').single;
      expect(mission.isEnded, isTrue);
      expect(mission.attributes['mission.status'], 'providerFailed');
      expect(mission.errors, hasLength(1));
      expect(mission.errors.single.toString(), contains('provider down'));
    });

    test(
      'no tracer injected: mission runs unchanged and records nothing',
      () async {
        final events = <EngineEvent>[];
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(completions: [completionOf('done')]),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: events.add,
          clock: fakeClock,
        );

        final result = await runner.run(
          missionId: 'm-plain',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        expect(result.status, MissionStatus.completed);
        expect(result.summary, 'done');
      },
    );

    test(
      'NoopTracer produces well-formed W3C traceparents and never throws',
      () {
        final span = const NoopTracer().startSpan('noop.span');
        expect(span.name, 'noop.span');
        expect(span.traceparent, matches(_traceparentShape));
        span.setAttribute('k', 'v');
        span.recordError(StateError('x'));
        expect(span.isEnded, isFalse);
        span.end();
        expect(span.isEnded, isTrue);
        span.end(); // idempotent
      },
    );

    test(
      'Spans.withScope propagates the ambient parent to nested spans',
      () async {
        final tracer = RecordingTracer();
        final outer = tracer.startSpan('outer');
        await Spans.withScope(outer, () async {
          final inner = tracer.startSpan('inner');
          expect(inner.parentTraceparent, outer.traceparent);
          inner.end();
        });
        outer.end();
        expect(tracer.spans.map((s) => s.name), ['outer', 'inner']);
      },
    );

    test(
      'propagationHeaders exposes the ambient traceparent for LlmRequest',
      () {
        final tracer = RecordingTracer();
        expect(Spans.propagationHeaders(), isEmpty);
        final span = tracer.startSpan('llm.call');
        expect(Spans.propagationHeaders(span), {
          'traceparent': span.traceparent,
        });
        span.end();
      },
    );
  });
}
