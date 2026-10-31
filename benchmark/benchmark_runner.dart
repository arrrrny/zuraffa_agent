// benchmark_runner.dart — load benchmarks for issue #128 AC-4.
//
// Three scenarios, straight from the acceptance criteria:
//   (a) JSONL session append throughput at 1k / 10k / 100k entries
//       (JsonlSessionStorage.appendEntry — the streaming-append hot path)
//   (b) MissionRunner wall-clock for the 50-tool-call mission against a
//       scripted fake LLM (no network)
//   (c) FallbackChainClient failover latency (advance-class 500 hop, and
//       the open-breaker skip path)
//
// The runner is a CLI, not a test: benchmarks don't belong in the PR gate.
// Nightly CI executes it and uploads the JSON report as an artifact
// (.github/workflows/nightly.yml). Usage:
//
//   dart run benchmark/benchmark_runner.dart                 # full
//   dart run benchmark/benchmark_runner.dart --quick         # 1k-only tier
//   dart run benchmark/benchmark_runner.dart --json out.json # artifact
//
// Every scenario uses fresh temp dirs and cleans up after itself.
library;

import 'dart:convert';
import 'dart:io';

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
import 'package:zuraffa_agent/src/jsonl_session_storage.dart';
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/llm/fallback_chain_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'report.dart';

const _defaultSizes = [1000, 10000, 100000];
const _quickSizes = [1000];

void main(List<String> args) async {
  final quick = args.contains('--quick');
  final jsonIndex = args.indexOf('--json');
  final jsonPath = jsonIndex >= 0 && jsonIndex + 1 < args.length
      ? args[jsonIndex + 1]
      : null;

  final report = BenchmarkReport(
    startedAt: DateTime.now(),
    quickMode: quick,
    results: [],
  );

  stdout.writeln('zuraffa_agent benchmarks (${quick ? "quick" : "full"})');
  await _benchJsonlAppend(report, quick ? _quickSizes : _defaultSizes);
  await _benchMissionRunner(report);
  await _benchFallbackFailover(report, iterations: quick ? 50 : 300);

  stdout.writeln(report.toText());
  if (jsonPath != null) {
    File(jsonPath).writeAsStringSync('${report.encodeJson()}\n');
    stdout.writeln('JSON report written to $jsonPath');
  }
}

// ---------------------------------------------------------------------------
// (a) JSONL session append throughput
// ---------------------------------------------------------------------------

Future<void> _benchJsonlAppend(BenchmarkReport report, List<int> sizes) async {
  for (final size in sizes) {
    final dir = await Directory.systemTemp.createTemp('zfa_bench_jsonl_');
    try {
      final store = JsonlSessionStorage('${dir.path}/session.jsonl');
      await store.init();
      final entries = List.generate(
        size,
        (i) => MessageEntry(
          id: 'e-bench-$i',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000 + i),
          message: UserMessage.text('benchmark payload #$i — ${'x' * 160}'),
        ),
      );
      final sw = Stopwatch()..start();
      for (final entry in entries) {
        await store.appendEntry(entry);
      }
      sw.stop();
      await store.close();
      report.results.add(
        BenchmarkResult(
          name: 'jsonl_append',
          unit: 'entries/sec',
          metrics: {
            'entries_per_sec': size / (sw.elapsedMicroseconds / 1e6),
            'ms_total': sw.elapsedMicroseconds / 1000,
            'us_per_entry': sw.elapsedMicroseconds / size,
          },
          params: {'entries': size},
        ),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  }
}

// ---------------------------------------------------------------------------
// (b) MissionRunner 50-tool-call mission wall-clock (fake LLM)
// ---------------------------------------------------------------------------

/// Scripted LLM provider — a completion per call index; the 50-tool-call
/// mission needs 51 (one per tool turn + the natural stop).
class _BenchLlmClient extends LlmClientProvider {
  _BenchLlmClient()
    : super(
        config: const ProviderConfig(
          id: 'bench',
          providerKind: 'openai',
          baseUrl: 'https://bench.invalid/v1',
          models: ['bench-model'],
          timeoutMs: 1,
        ),
        apiKey: 'bench-key',
      );

  int callCount = 0;

  @override
  Future<ChatCompletion> complete(List<ChatMessage> messages) async {
    callCount++;
    final isLast = callCount > _toolCallTurns;
    return ChatCompletion(
      content: isLast ? 'mission complete' : 'turn $callCount needs a tool',
      finishReason: isLast ? 'stop' : 'tool_calls',
      usage: const TokenUsage(
        promptTokens: 120,
        completionTokens: 40,
        totalTokens: 160,
      ),
    );
  }
}

const _toolCallTurns = 50;

class _BenchDispatcher implements ToolDispatcher {
  @override
  Future<ToolDispatchResult> dispatch({
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isInternalMission,
  }) async => ToolDispatchResult(
    success: true,
    result: 'ok:${arguments.length}',
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

class _BenchPlanner implements ToolCallPlanner {
  @override
  Future<List<ToolCall>> plan(
    ChatCompletion completion,
    List<ChatMessage> transcript,
  ) async {
    if (completion.finishReason == 'stop') return const [];
    return [
      const ToolCall(
        toolName: 'bench_tool',
        arguments: {'q': 'bench'},
        executionMode: 'sequential',
      ),
    ];
  }
}

Future<void> _benchMissionRunner(BenchmarkReport report) async {
  final llm = _BenchLlmClient();
  final events = <EngineEvent>[];
  final runner = MissionRunner(
    executor: EngineLoopExecutor(
      const EngineLoop(
        id: 'bench-loop',
        sessionId: 'bench',
        maxTurns: 60,
        wallClockTimeoutMs: 60000,
        repetitionThreshold: 1000,
      ),
      llm,
    ),
    toolDispatcher: _BenchDispatcher(),
    stopPolicy: const StopPolicy(
      id: 'bench',
      maxTurns: 100,
      wallClockTimeout: Duration.zero,
      repetitionThreshold: 1000,
    ),
    onEvent: events.add,
    clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );

  final sw = Stopwatch()..start();
  final result = await runner.run(
    missionId: 'bench-mission',
    messages: const [ChatMessage(role: 'user', content: 'go')],
    planner: _BenchPlanner(),
  );
  sw.stop();

  // Sanity: the benchmark must actually exercise the 50-tool-call shape.
  if (result.status != MissionStatus.completed ||
      events.whereType<ToolCallCompleted>().length < _toolCallTurns) {
    stderr.writeln(
      'benchmark harness broken: status=${result.status} '
      'toolCalls=${events.whereType<ToolCallCompleted>().length}',
    );
    exit(2);
  }

  report.results.add(
    BenchmarkResult(
      name: 'mission_runner_50_tool_calls',
      unit: 'ms',
      metrics: {
        'wall_clock_ms': sw.elapsedMicroseconds / 1000,
        'llm_calls': llm.callCount.toDouble(),
        'events_emitted': events.length.toDouble(),
      },
      params: {'tool_calls': _toolCallTurns, 'llm': 'scripted-fake'},
    ),
  );
}

// ---------------------------------------------------------------------------
// (c) FallbackChainClient failover latency
// ---------------------------------------------------------------------------

class _FailingClient implements LlmClient {
  @override
  String get providerName => 'failing';

  @override
  String get model => 'bench-model';

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    throw const LlmHttpException(
      provider: 'failing',
      statusCode: 500,
      body: '{"error": {"message": "upstream 500"}}',
    );
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    throw const LlmHttpException(
      provider: 'failing',
      statusCode: 500,
      body: '{"error": {"message": "upstream 500"}}',
    );
  }

  @override
  Future<void> close() async {}
}

class _HappyClient implements LlmClient {
  @override
  String get providerName => 'happy';

  @override
  String get model => 'bench-model';

  @override
  Future<LlmResponse> generate(LlmRequest request) async =>
      const LlmResponse(content: 'ok');

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    yield const LlmResponseChunk(content: 'ok', isComplete: true);
  }

  @override
  Future<void> close() async {}
}

class _BenchClock implements LlmClock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(1700000000000);

  @override
  Future<void> sleep(int milliseconds) async {}
}

Future<void> _benchFallbackFailover(
  BenchmarkReport report, {
  required int iterations,
}) async {
  // Scenario 1: a chain of K dead providers then a live one — every call
  // walks K advance-class (500) failures before succeeding. High breaker
  // thresholds keep the dead providers' circuits closed so the hop is
  // always exercised.
  for (final deadCount in const [1, 4]) {
    final samples = <double>[];
    for (var i = 0; i < iterations; i++) {
      final chain = FallbackChainClient(
        providers: [
          for (var d = 0; d < deadCount; d++)
            (id: 'dead-$d', client: _FailingClient()),
          (id: 'live', client: _HappyClient()),
        ],
        maxConsecutiveFailures: 1000000,
        cooldownMs: 1000000,
        clock: _BenchClock(),
      );
      final sw = Stopwatch()..start();
      try {
        await await2(chain);
      } on Object {
        // Exhausted chains are a valid outcome; latency is what we measure.
      }
      sw.stop();
      samples.add(sw.elapsedMicroseconds.toDouble());
    }
    report.results.add(
      BenchmarkResult(
        name: 'fallback_failover_${deadCount}_dead_hops',
        unit: 'us',
        metrics: _percentiles(samples),
        params: {'iterations': iterations, 'chain': deadCount + 1},
      ),
    );
  }

  // Scenario 2: the open-breaker skip path — the dead provider's breaker is
  // already open, so the chain skips it without touching the client.
  final skipped = <double>[];
  for (var i = 0; i < iterations; i++) {
    final chain = FallbackChainClient(
      providers: [
        (id: 'open', client: _FailingClient()),
        (id: 'live', client: _HappyClient()),
      ],
      maxConsecutiveFailures: 1, // trips on the very first failure
      cooldownMs: 1000000, // stays open for the whole measurement
      clock: _BenchClock(),
    );
    // Trip the first provider's breaker, then measure the skip path.
    chain.breakers['open']!.recordFailure();
    final sw = Stopwatch()..start();
    try {
      await chain.generate(LlmRequest(messages: [UserMessage.text('hi')]));
    } on Object {
      // Same contract: latency of the walk, whatever the outcome.
    }
    sw.stop();
    skipped.add(sw.elapsedMicroseconds.toDouble());
  }
  report.results.add(
    BenchmarkResult(
      name: 'fallback_open_breaker_skip',
      unit: 'us',
      metrics: _percentiles(skipped),
      params: {'iterations': iterations},
    ),
  );
}

/// Awaits one failover generate() end-to-end (the timing wrapper lives in
/// the caller; this exists so the awaited call is a single statement).
Future<LlmResponse> await2(FallbackChainClient chain) =>
    chain.generate(LlmRequest(messages: [UserMessage.text('hi')]));

Map<String, double> _percentiles(List<double> samplesUs) {
  final sorted = List.of(samplesUs)..sort();
  double pick(double p) =>
      sorted[(p * (sorted.length - 1)).round().clamp(0, sorted.length - 1)];
  return {
    'p50_us': pick(0.50),
    'p95_us': pick(0.95),
    'max_us': sorted.last,
    'mean_us': samplesUs.reduce((a, b) => a + b) / samplesUs.length,
  };
}
