// Tests for issue arrrrny/zuraffa_agent#133 — O-4: runGuarded crash boundary
// and traceparent propagation through LlmRequest headers.
//
// runGuarded wraps run() in runZonedGuarded: uncaught zone errors are routed
// to the structured logger (SEVERE, engine subsystem) and to the optional
// CrashReporter, then rethrown to the caller — observation, not suppression.
// Sentry / OTLP plug in by implementing CrashReporter.

import 'dart:convert';

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
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';
import 'package:zuraffa_agent/src/observability/crash_reporter.dart';
import 'package:zuraffa_agent/src/observability/tracing.dart';
import 'package:zuraffa_agent/src/types.dart';

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

/// Captures the outbound request; answers with a canned chat.completion.
class CapturingTransport implements LlmTransport {
  final List<LlmHttpRequest> requests = [];

  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async {
    requests.add(request);
    return LlmHttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'choices': [
          {
            'message': {'content': 'ok'},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 3,
          'completion_tokens': 4,
          'total_tokens': 7,
        },
      }),
    );
  }

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) async {
    throw UnimplementedError('not needed in this test');
  }
}

const _kTraceparent = '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';

void main() {
  var fakeNow = DateTime.utc(2026, 1, 1);
  DateTime fakeClock() => fakeNow;

  setUp(() {
    fakeNow = DateTime.utc(2026, 1, 1);
  });

  group('133 O-4 — runGuarded crash boundary', () {
    test(
      'routes a zone error to the crash reporter and rethrows to the caller',
      () async {
        final reporter = RecordingCrashReporter();
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(completions: [completionOf('never reached')]),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          // A misbehaving consumer event sink: the classic uncaught zone error.
          onEvent: (event) {
            if (event is TurnStarted) throw StateError('sink exploded');
          },
          clock: fakeClock,
          crashReporter: reporter,
        );

        await expectLater(
          runner.runGuarded(
            missionId: 'm-crash',
            messages: const [ChatMessage(role: 'user', content: 'go')],
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'sink exploded',
            ),
          ),
        );

        expect(reporter.reports, hasLength(1));
        final crash = reporter.reports.single;
        expect(crash.error, isA<StateError>());
        expect(crash.context?['mission.id'], 'm-crash');
        expect(crash.stackTrace, isNotNull);
      },
    );

    test('a clean mission passes through with nothing reported', () async {
      final reporter = RecordingCrashReporter();
      final runner = MissionRunner(
        executor: EngineLoopExecutor(
          loop10,
          ScriptedLlmClient(completions: [completionOf('all done')]),
        ),
        toolDispatcher: FakeToolDispatcher(),
        stopPolicy: policy,
        onEvent: (_) {},
        clock: fakeClock,
        crashReporter: reporter,
      );

      final result = await runner.runGuarded(
        missionId: 'm-clean',
        messages: const [ChatMessage(role: 'user', content: 'go')],
      );

      expect(result.status, MissionStatus.completed);
      expect(result.summary, 'all done');
      expect(reporter.reports, isEmpty);
    });

    test(
      'zone errors are reported even when no crash reporter is wired',
      () async {
        final runner = MissionRunner(
          executor: EngineLoopExecutor(
            loop10,
            ScriptedLlmClient(completions: [completionOf('never reached')]),
          ),
          toolDispatcher: FakeToolDispatcher(),
          stopPolicy: policy,
          onEvent: (event) {
            if (event is TurnStarted) throw StateError('sink exploded');
          },
          clock: fakeClock,
        );

        await expectLater(
          runner.runGuarded(
            missionId: 'm-noreporter',
            messages: const [ChatMessage(role: 'user', content: 'go')],
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('133 O-4 — traceparent through LlmRequest.headers', () {
    test('request headers are merged into the outbound HTTP request', () async {
      final transport = CapturingTransport();
      final client = OpenAiCompatibleClient(
        transport: transport,
        baseUrl: 'https://api.example.com/v1',
        model: 'model-1',
        apiKey: 'secret-key',
      );

      await client.generate(
        LlmRequest(
          messages: [UserMessage.text('hi')],
          headers: {'traceparent': _kTraceparent},
        ),
      );

      final sent = transport.requests.single;
      expect(sent.headers['traceparent'], _kTraceparent);
      // Defaults survive the merge.
      expect(sent.headers['authorization'], 'Bearer secret-key');
      expect(sent.headers['content-type'], 'application/json');
    });

    test('a request without headers keeps the default header set', () async {
      final transport = CapturingTransport();
      final client = OpenAiCompatibleClient(
        transport: transport,
        baseUrl: 'https://api.example.com/v1',
        model: 'model-1',
        apiKey: 'secret-key',
      );

      await client.generate(LlmRequest(messages: [UserMessage.text('hi')]));

      expect(
        transport.requests.single.headers.containsKey('traceparent'),
        isFalse,
      );
      expect(
        transport.requests.single.headers['authorization'],
        'Bearer secret-key',
      );
    });

    test(
      'Spans.propagationHeaders feeds LlmRequest.headers end-to-end',
      () async {
        final transport = CapturingTransport();
        final client = OpenAiCompatibleClient(
          transport: transport,
          baseUrl: 'https://api.example.com/v1',
          model: 'model-1',
        );
        final tracer = RecordingTracer();
        final span = tracer.startSpan('llm.call');

        await Spans.withScope(span, () async {
          await client.generate(
            LlmRequest(
              messages: [UserMessage.text('hi')],
              headers: Spans.propagationHeaders(),
            ),
          );
        });

        expect(
          transport.requests.single.headers['traceparent'],
          span.traceparent,
        );
        span.end();
      },
    );
  });
}
