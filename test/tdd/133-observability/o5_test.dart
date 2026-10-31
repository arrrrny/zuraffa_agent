// Tests for issue arrrrny/zuraffa_agent#133 — the review-fix wiring round
// on PR #150 (merge task a0491b29). Each group pins one resolved finding:
//
//   F1 — LastLlmErrorTracker has a real recording path: MissionRunner's
//        provider-failure catch records (with provider id) and a clean turn
//        clears; FallbackChainClient records per-provider advance-path
//        failures and recoveries; the tracker's clock is injectable; the
//        /health rendering is bounded and body-free (LlmHttpException).
//   F2 — BreakerHealthProbe is feedable: FallbackChainClient exposes its
//        breakers.
//   F3 — engine.turn is ambient during runTurn (span tree + traceparent).
//   F4 — the crash path records mission.status='crashed' and the duration
//        histogram (run()'s finally — every exit path).
//   F5 — agent_tool_calls_failed_total counts thrown dispatches and failed
//        batch results.

import 'dart:async';

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
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/llm/fallback_chain_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/observability/health_check.dart';
import 'package:zuraffa_agent/src/observability/metrics.dart';
import 'package:zuraffa_agent/src/observability/traced_adapters.dart';
import 'package:zuraffa_agent/src/observability/tracing.dart';
import 'package:zuraffa_agent/src/types.dart';

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

ChatCompletion completionOf(String content) => ChatCompletion(
  content: content,
  finishReason: 'stop',
  usage: const TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
);

/// Provider whose [complete] throws [error] exactly [failFirst] times,
/// then succeeds — drives the MissionRunner provider-failure catch.
class FlakyLlmClient extends LlmClientProvider {
  FlakyLlmClient({required this.error, this.failFirst = 1})
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

  final Object error;
  final int failFirst;
  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    if (callCount <= failFirst) throw error;
    return completionOf('recovered');
  }
}

/// Provider that captures the ambient span during [complete] — proves the
/// engine.turn scope (F3) from inside the executor call.
class AmbientCapturingClient extends LlmClientProvider {
  AmbientCapturingClient()
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

  String? ambientSpanName;
  String? ambientTraceparent;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    ambientSpanName = Spans.current?.name;
    ambientTraceparent = Spans.current?.traceparent;
    return completionOf('ok');
  }
}

class FakeToolDispatcher implements ToolDispatcher {
  FakeToolDispatcher({this.dispatchError, this.batchResults = const []});

  final Object? dispatchError;
  final List<ToolDispatchResult> batchResults;

  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async {
    if (dispatchError != null) throw dispatchError!;
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
  }) async => batchResults;

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

ToolDispatchResult okResult() => ToolDispatchResult(
  success: true,
  result: 'ok',
  error: '',
  artifactRefs: const [],
);

ToolDispatchResult failResult() => ToolDispatchResult(
  success: false,
  result: '',
  error: 'boom',
  artifactRefs: const [],
);

class FixedLlmClock implements LlmClock {
  FixedLlmClock(this.fixed);
  DateTime fixed;
  @override
  DateTime now() => fixed;
  @override
  Future<void> sleep(int milliseconds) async {}
}

/// Minimal LlmClient fake for the fallback chain (F1 chain-side / F2).
class ScriptedLlmClient implements LlmClient {
  ScriptedLlmClient(this.id, {this.error});

  final String id;
  final Object? error;
  int generateCalls = 0;

  @override
  String get providerName => id;

  @override
  String get model => 'test-model';

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    generateCalls++;
    if (error != null) throw error!;
    return const LlmResponse(content: 'ok');
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    if (error != null) throw error!;
    yield const LlmResponseChunk(content: 'ok', isComplete: true);
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('133 review fixes — F1: LastLlmErrorTracker recording path', () {
    test(
      'MissionRunner records the provider failure with its provider id',
      () async {
        final tracker = LastLlmErrorTracker(
          clock: () => DateTime.utc(2026, 1, 1),
        );
        final metrics = InMemoryMetrics();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            FlakyLlmClient(error: StateError('provider exploded')),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: (_) {},
          clock: () => DateTime.utc(2026, 1, 1),
          tracer: RecordingTracer(),
          metrics: metrics,
          llmErrorTracker: tracker,
        );

        final result = await runner.run(
          missionId: 'm-f1',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        expect(result.status, MissionStatus.providerFailed);
        expect(tracker.lastError, isA<StateError>());
        expect(tracker.lastErrorProvider, 'kilo');
        expect(tracker.lastErrorAt, DateTime.utc(2026, 1, 1));
        // The probe the issue asks for now degrades instead of lying ok.
        final probe = await LastLlmErrorProbe(tracker).probe();
        expect(probe.status, HealthStatus.degraded);
        expect(probe.details['provider'], 'kilo');
      },
    );

    test(
      'a clean turn records success and clears the recorded error',
      () async {
        final tracker = LastLlmErrorTracker(
          clock: () => DateTime.utc(2026, 1, 1),
        );
        tracker.recordError(StateError('outage'), provider: 'kilo');

        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            FlakyLlmClient(error: StateError('x'), failFirst: 0),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: (_) {},
          clock: () => DateTime.utc(2026, 1, 1),
          llmErrorTracker: tracker,
        );

        final result = await runner.run(
          missionId: 'm-f1-ok',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        expect(result.status, MissionStatus.completed);
        expect(tracker.lastError, isNull);
        expect(tracker.lastSuccessAt, DateTime.utc(2026, 1, 1));
      },
    );

    test('the tracker clock is injectable (no direct DateTime.now)', () {
      final fixed = DateTime.utc(2026, 2, 2, 3, 4, 5);
      final tracker = LastLlmErrorTracker(clock: () => fixed);

      tracker.recordError(StateError('e'), provider: 'p');
      expect(tracker.lastErrorAt, fixed);

      tracker.recordSuccess();
      expect(tracker.lastSuccessAt, fixed);
    });

    test(
      'FallbackChainClient records per-provider failures it advanced past',
      () async {
        final tracker = LastLlmErrorTracker(
          clock: () => DateTime.utc(2026, 1, 1),
        );
        final outage = LlmNetworkException(provider: 'p1', cause: 'reset');
        final chain = FallbackChainClient(
          providers: [
            (id: 'p1', client: ScriptedLlmClient('p1', error: outage)),
            (id: 'p2', client: ScriptedLlmClient('p2', error: outage)),
          ],
          clock: FixedLlmClock(DateTime.utc(2026, 1, 1)),
          llmErrorTracker: tracker,
        );

        await expectLater(
          chain.generate(LlmRequest(messages: [UserMessage.text('hi')])),
          throwsA(isA<LlmFallbackExhaustedException>()),
        );

        // Both providers failed; the tracker holds the LAST one, per id.
        expect(tracker.lastErrorProvider, 'p2');
        expect(tracker.lastError, outage);
      },
    );

    test(
      'FallbackChainClient clears the error when a later provider serves',
      () async {
        final tracker = LastLlmErrorTracker();
        tracker.recordError(StateError('earlier outage'), provider: 'p1');
        final chain = FallbackChainClient(
          providers: [
            (
              // LlmNetworkException is advance-class: the chain failovers
              // to p2 and clears the recorded error on its success.
              id: 'p1',
              client: ScriptedLlmClient(
                'p1',
                error: LlmNetworkException(provider: 'p1', cause: 'down'),
              ),
            ),
            (id: 'p2', client: ScriptedLlmClient('p2')),
          ],
          clock: FixedLlmClock(DateTime.utc(2026, 1, 1)),
          llmErrorTracker: tracker,
        );

        final response = await chain.generate(
          LlmRequest(messages: [UserMessage.text('hi')]),
        );

        expect(response.content, 'ok');
        expect(tracker.lastError, isNull);
        expect(tracker.lastSuccessAt, isNotNull);
      },
    );

    test('the /health rendering is bounded and drops the HTTP body', () async {
      final tracker = LastLlmErrorTracker();
      tracker.recordError(
        LlmHttpException(
          provider: 'kilo',
          statusCode: 500,
          body: 'SECRET-PROMPT-CONTENT-EMBEDDED-IN-BODY',
        ),
        provider: 'kilo',
      );

      final result = await LastLlmErrorProbe(tracker).probe();

      expect(result.status, HealthStatus.degraded);
      expect(
        result.details['error'],
        'LlmHttpException: kilo returned HTTP 500',
      );
      expect(result.details['error'].toString(), isNot(contains('SECRET')));

      // Non-HTTP errors are length-bounded, not verbatim.
      tracker.recordError(StateError('x' * 500), provider: 'kilo');
      final bounded = await LastLlmErrorProbe(tracker).probe();
      expect(
        (bounded.details['error'] as String).length,
        lessThanOrEqualTo(201),
      );
    });
  });

  group('133 review fixes — F2: breaker probe is feedable from the chain', () {
    test('FallbackChainClient exposes its per-provider breakers', () {
      final chain = FallbackChainClient(
        providers: [
          (id: 'p1', client: ScriptedLlmClient('p1')),
          (id: 'p2', client: ScriptedLlmClient('p2')),
        ],
        clock: FixedLlmClock(DateTime.utc(2026, 1, 1)),
      );

      final breakers = chain.breakers;
      expect(breakers.keys, containsAll(['p1', 'p2']));
      expect(breakers.values, everyElement(isA<CircuitBreaker>()));
      expect(
        () => breakers['p3'] = CircuitBreaker(
          providerId: 'p3',
          clock: FixedLlmClock(DateTime.utc(2026, 1, 1)),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'BreakerHealthProbe consumes the exposed breakers end-to-end',
      () async {
        final clock = FixedLlmClock(DateTime.utc(2026, 1, 1));
        final chain = FallbackChainClient(
          providers: [
            (id: 'p1', client: ScriptedLlmClient('p1')),
            (id: 'p2', client: ScriptedLlmClient('p2')),
          ],
          clock: clock,
        );
        // Drive p1's breaker open so the probe has something to report.
        final p1Breaker = chain.breakers['p1']!;
        p1Breaker.recordFailure();
        p1Breaker.recordFailure();
        p1Breaker.recordFailure();

        final probe = BreakerHealthProbe(chain.breakers.values.toList());
        final check = await probe.probe();

        expect(check.name, 'circuit_breakers');
        expect(check.status, HealthStatus.degraded);
        expect((check.details['providers'] as Map)['p1'], 'open');
        expect((check.details['providers'] as Map)['p2'], 'closed');
      },
    );
  });

  group('133 review fixes — F3: engine.turn is ambient during runTurn', () {
    test(
      'the LLM call sees engine.turn ambient and parented to mission.run',
      () async {
        final tracer = RecordingTracer();
        final client = AmbientCapturingClient();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(loop10, client),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: (_) {},
          clock: () => DateTime.utc(2026, 1, 1),
          tracer: tracer,
        );

        await runner.run(
          missionId: 'm-f3',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        // Inside the executor call the ambient span is the TURN, not the
        // mission — vendor SDK spans would nest under engine.turn.
        expect(client.ambientSpanName, 'engine.turn');

        final mission = tracer.spans.firstWhere((s) => s.name == 'mission.run');
        final turn = tracer.spans.firstWhere((s) => s.name == 'engine.turn');
        // The documented tree: engine.turn is a child of mission.run …
        expect(turn.parentTraceparent, mission.traceparent);
        // … and the ambient traceparent inside runTurn carries the TURN's id.
        expect(client.ambientTraceparent, turn.traceparent);
      },
    );
  });

  group('133 review fixes — F4: crash path records status + duration', () {
    test(
      'an uncaught error records status=crashed and the histogram sample',
      () async {
        final tracer = RecordingTracer();
        final metrics = InMemoryMetrics();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            FlakyLlmClient(error: StateError('never reached'), failFirst: 0),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          // A throwing event sink — the classic uncaught zone error (O-4).
          onEvent: (event) {
            if (event is TurnStarted) throw StateError('sink exploded');
          },
          clock: () => DateTime.utc(2026, 1, 1),
          tracer: tracer,
          metrics: metrics,
        );

        await expectLater(
          runner.run(
            missionId: 'm-f4',
            messages: const [ChatMessage(role: 'user', content: 'go')],
          ),
          throwsA(isA<StateError>()),
        );

        final mission = tracer.spans.firstWhere((s) => s.name == 'mission.run');
        expect(mission.attributes['mission.status'], 'crashed');
        expect(
          metrics.histograms['agent_mission_duration_ms{status=crashed}'],
          hasLength(1),
        );
      },
    );

    test(
      'a clean mission still records its terminal status exactly once',
      () async {
        final metrics = InMemoryMetrics();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(loop10, AmbientCapturingClient()),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: (_) {},
          clock: () => DateTime.utc(2026, 1, 1),
          metrics: metrics,
        );

        final result = await runner.run(
          missionId: 'm-f4-ok',
          messages: const [ChatMessage(role: 'user', content: 'go')],
        );

        expect(result.status, MissionStatus.completed);
        expect(
          metrics.histograms['agent_mission_duration_ms{status=completed}'],
          hasLength(1),
        );
      },
    );
  });

  group('133 review fixes — F5: tool-call failure counter', () {
    test(
      'a throwing dispatch increments agent_tool_calls_failed_total',
      () async {
        final metrics = InMemoryMetrics();
        final dispatcher = TracedToolDispatcher(
          FakeToolDispatcher(dispatchError: StateError('dispatch threw')),
          RecordingTracer(),
          metrics: metrics,
        );

        await expectLater(
          dispatcher.dispatch(
            toolName: 't',
            arguments: const {},
            isInternalMission: false,
          ),
          throwsA(isA<StateError>()),
        );

        expect(metrics.counters['agent_tool_calls_failed_total'], 1.0);
      },
    );

    test('failed results inside a batch increment the counter', () async {
      final metrics = InMemoryMetrics();
      final dispatcher = TracedToolDispatcher(
        FakeToolDispatcher(
          batchResults: [okResult(), failResult(), failResult()],
        ),
        RecordingTracer(),
        metrics: metrics,
      );

      final results = await dispatcher.dispatchBatch(
        calls: const [],
        isInternalMission: false,
      );

      expect(results, hasLength(3));
      expect(metrics.counters['agent_tool_calls_failed_total'], 2.0);
    });
  });
}
