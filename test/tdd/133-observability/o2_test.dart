// Tests for issue arrrrny/zuraffa_agent#133 — O-2: metrics exporter seam.
//
// `Metrics` interface: counter(name) / histogram(name, value) /
// gauge(name, value) with a no-op default. Wiring under test:
//   - token counters from each turn's completion usage
//   - mission latency histogram, labeled by terminal status
//   - tool-call failure counter on a failed dispatch
//   - circuit-breaker state gauges on state transitions

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
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/observability/metrics.dart';

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
  FakeToolDispatcher([this.resultsByTool = const {}]);

  final Map<String, ToolDispatchResult> resultsByTool;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async =>
      resultsByTool[toolName] ??
      ToolDispatchResult(
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

class FixedLlmClock implements LlmClock {
  FixedLlmClock(this.fixed);
  DateTime fixed;
  @override
  DateTime now() => fixed;
  @override
  Future<void> sleep(int milliseconds) async {}
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

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  group('133 O-2 — metrics', () {
    test('token counters are wired from each turn completion usage', () async {
      final metrics = InMemoryMetrics();
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(
            completions: [
              completionOf('step1', finish: 'tool_calls'),
              completionOf('done'),
            ],
          ),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: policy,
        onEvent: (_) {},
        clock: fakeClock,
        metrics: metrics,
      );

      await runner.run(
        missionId: 'm-tokens',
        messages: const [ChatMessage(role: 'user', content: 'go')],
        planner: ScriptedPlanner({
          1: [
            const ToolCall(
              toolName: 'search',
              arguments: {},
              executionMode: 'sequential',
            ),
          ],
        }),
      );

      // Two turns x (10 prompt + 5 completion).
      expect(metrics.counters['agent_llm_tokens_total{type=input}'], 20);
      expect(metrics.counters['agent_llm_tokens_total{type=output}'], 10);
    });

    test('mission latency histogram is labeled by terminal status', () async {
      final metrics = InMemoryMetrics();
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: [completionOf('done')]),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: policy,
        onEvent: (_) {},
        clock: fakeClock,
        metrics: metrics,
      );

      await runner.run(
        missionId: 'm-latency',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(
        metrics.histograms['agent_mission_duration_ms{status=completed}'],
        hasLength(1),
      );
      expect(
        metrics
            .histograms['agent_mission_duration_ms{status=completed}']!
            .single,
        greaterThanOrEqualTo(0),
      );
    });

    test(
      'failed tool dispatch increments the tool-call failure counter',
      () async {
        final metrics = InMemoryMetrics();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(
              completions: [
                completionOf('step1', finish: 'tool_calls'),
                completionOf('done'),
              ],
            ),
          ),
          toolDispatcher: FakeToolDispatcher({
            'bad': ToolDispatchResult(
              success: false,
              result: '',
              error: 'boom',
              artifactRefs: const [],
            ),
          }),
          stopPolicy: policy,
          onEvent: (_) {},
          clock: fakeClock,
          metrics: metrics,
        );

        await runner.run(
          missionId: 'm-toolfail',
          messages: const [ChatMessage(role: 'user', content: 'go')],
          planner: ScriptedPlanner({
            1: [
              const ToolCall(
                toolName: 'bad',
                arguments: {},
                executionMode: 'sequential',
              ),
            ],
          }),
        );

        expect(metrics.counters['agent_tool_calls_failed_total'], 1);
      },
    );

    test('circuit breaker publishes state gauges on transitions', () {
      final metrics = InMemoryMetrics();
      final clock = FixedLlmClock(DateTime.utc(2026, 1, 1));
      final breaker = CircuitBreaker(
        providerId: 'p1',
        clock: clock,
        metrics: metrics,
      );

      breaker.recordFailure();
      breaker.recordFailure();
      // closed = 0 — still under the failure threshold.
      expect(metrics.gauges['agent_circuit_breaker_state{provider=p1}'], 0);

      breaker.recordFailure(); // third consecutive failure -> open (2).
      expect(metrics.gauges['agent_circuit_breaker_state{provider=p1}'], 2);

      clock.fixed = clock.fixed.add(const Duration(minutes: 2));
      breaker.recordSuccess(); // recovered -> closed (0).
      expect(metrics.gauges['agent_circuit_breaker_state{provider=p1}'], 0);
    });

    test('NoopMetrics is a silent default that never throws', () {
      const metrics = NoopMetrics();
      final counter = metrics.counter('anything_total');
      counter.inc();
      counter.inc(5);
      metrics.histogram('anything_ms', 12.5);
      metrics.gauge('anything_gauge', 3);
      expect(identical(NoopMetrics.instance, metrics), isTrue);
    });

    test('InMemoryMetrics counter handles accumulate per label set', () {
      final metrics = InMemoryMetrics();
      final input = metrics.counter(
        'agent_llm_tokens_total',
        labels: {'type': 'input'},
      );
      final output = metrics.counter(
        'agent_llm_tokens_total',
        labels: {'type': 'output'},
      );
      input.inc(10);
      input.inc(2);
      output.inc(3);
      expect(metrics.counters['agent_llm_tokens_total{type=input}'], 12);
      expect(metrics.counters['agent_llm_tokens_total{type=output}'], 3);
    });
  });
}
