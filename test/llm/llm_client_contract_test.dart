// Shared LLM client contract suite — Spec 007 US4 (behaviors A1, A4, A6, A8).
//
// One suite, three providers, identical client-level assertions over recorded
// wire fixtures (test/fixtures/llm/<provider>/). The fixtures encode the SAME
// canonical scenario in each provider's native wire format:
//   - generate: content "Hello, world.", finish stop, usage 25/42/cached 8
//   - stream:   text deltas Hello / ", " / "world.", one assembled
//               get_weather{"city":"Paris"} tool call, final completing chunk
//               with usage
//   - errors:   non-2xx raises LlmHttpException; 429 is retried and succeeds
//
// Provider-specific vocabulary (finishReason on the streamed tool-call turn,
// thought-token reporting) is parameterized in [ContractFixtures] and
// documented inline — the shared assertion set itself is identical.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/types.dart';
import 'package:zuraffa_agent/src/llm/anthropic_client.dart';
import 'package:zuraffa_agent/src/llm/gemini_client.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

class ContractFixtures {
  final String generateBody;
  final List<String> streamLines;
  final String errorBody;
  final String rateLimitedBody;

  /// Finish reason vocabulary on the streamed tool-call turn:
  /// 'tool_calls' (OpenAI/Anthropic) vs 'stop' (Gemini STOP).
  final String expectedStreamFinishReason;

  /// Thought tokens are only reported by OpenAI (reasoning_tokens) and Gemini
  /// (thoughtsTokenCount); Anthropic folds thinking into output tokens.
  final int expectedThoughtTokens;

  const ContractFixtures({
    required this.generateBody,
    required this.streamLines,
    required this.errorBody,
    required this.rateLimitedBody,
    required this.expectedStreamFinishReason,
    required this.expectedThoughtTokens,
  });
}

Future<String> _fixture(String provider, String name) =>
    File('test/fixtures/llm/$provider/$name').readAsString();

List<String> _fixtureLines(String provider, String name) =>
    File('test/fixtures/llm/$provider/$name')
        .readAsLinesSync()
        .where((line) => line.isNotEmpty)
        .toList();

void runLlmClientContractSuite({
  required String label,
  required LlmClient Function(FakeLlmTransport transport,
          {RetryConfig retryConfig})
      makeClient,
  required ContractFixtures fixtures,
}) {
  group('LlmClient contract suite — $label (A-behaviors)', () {
    test('generate returns the canonical content, usage, and finish reason', () async {
      final transport = FakeLlmTransport(
        provider: label,
        script: [
          ScriptedResponse(statusCode: 200, body: fixtures.generateBody),
        ],
      );
      final client = makeClient(transport);

      final response = await client
          .generate(LlmRequest(messages: [UserMessage.text('hi')]));

      expect(response.content, 'Hello, world.');
      expect(response.finishReason, 'stop');
      expect(response.usage.inputTokens, 25);
      expect(response.usage.outputTokens, 42);
      expect(response.usage.cachedTokens, 8);
      expect(response.usage.thoughtTokens, fixtures.expectedThoughtTokens);
    });

    test('stream emits the canonical text deltas, assembled tool call, and completing usage chunk', () async {
      final transport = FakeLlmTransport(
        provider: label,
        script: [
          ScriptedResponse(statusCode: 200, lines: fixtures.streamLines),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('hi')]))
          .toList();

      // Identical text delta sequence across providers.
      expect(chunks.where((c) => c.content != null).map((c) => c.content).toList(),
          ['Hello', ', ', 'world.']);

      // Identical assembled tool-call buffering.
      final toolChunks = chunks.where((c) => c.toolCalls.isNotEmpty).toList();
      expect(toolChunks, hasLength(1));
      expect(toolChunks.single.toolCalls.single.name, 'get_weather');
      expect(toolChunks.single.toolCalls.single.arguments,
          {'city': 'Paris'});

      // Identical completing final chunk with usage fields.
      final last = chunks.last;
      expect(last.isComplete, isTrue);
      expect(last.usage!.inputTokens, 25);
      expect(last.usage!.outputTokens, 42);
      expect(last.usage!.cachedTokens, 8);
      expect(last.finishReason, fixtures.expectedStreamFinishReason);
    });

    test('a non-2xx response raises LlmHttpException with status and body', () async {
      final transport = FakeLlmTransport(
        provider: label,
        script: [
          ScriptedResponse(statusCode: 500, body: fixtures.errorBody),
        ],
      );
      // Single 500, no retries: the typed error must surface immediately.
      final client = makeClient(transport,
          retryConfig: const RetryConfig(maxAttempts: 1));

      await expectLater(
        client.generate(LlmRequest(messages: [UserMessage.text('hi')])),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.body, 'body', fixtures.errorBody)),
      );
    });

    test('a 429 is retried and then succeeds', () async {
      final transport = FakeLlmTransport(
        provider: label,
        script: [
          ScriptedResponse(statusCode: 429, body: fixtures.rateLimitedBody),
          ScriptedResponse(statusCode: 200, body: fixtures.generateBody),
        ],
      );
      final client = makeClient(transport,
          retryConfig: const RetryConfig(maxAttempts: 2, baseDelayMs: 10));

      final response = await client
          .generate(LlmRequest(messages: [UserMessage.text('hi')]));

      expect(response.content, 'Hello, world.');
      expect(transport.requests, hasLength(2));
    });
  });
}

void main() async {
  final openai = ContractFixtures(
    generateBody: await _fixture('openai', 'generate.json'),
    streamLines: _fixtureLines('openai', 'stream.sse'),
    errorBody: await _fixture('openai', 'error_500.json'),
    rateLimitedBody: await _fixture('openai', 'rate_limited.json'),
    expectedStreamFinishReason: 'tool_calls',
    expectedThoughtTokens: 7,
  );
  final anthropic = ContractFixtures(
    generateBody: await _fixture('anthropic', 'generate.json'),
    streamLines: _fixtureLines('anthropic', 'stream.sse'),
    errorBody: await _fixture('anthropic', 'error_500.json'),
    rateLimitedBody: await _fixture('anthropic', 'rate_limited.json'),
    expectedStreamFinishReason: 'tool_calls',
    expectedThoughtTokens: 0,
  );
  final gemini = ContractFixtures(
    generateBody: await _fixture('gemini', 'generate.json'),
    streamLines: _fixtureLines('gemini', 'stream.sse'),
    errorBody: await _fixture('gemini', 'error_500.json'),
    rateLimitedBody: await _fixture('gemini', 'rate_limited.json'),
    expectedStreamFinishReason: 'stop',
    expectedThoughtTokens: 7,
  );

  // A8: the same suite, the same assertions, over each provider's recorded
  // fixtures. A1/A4/A6 are the per-provider slices.
  runLlmClientContractSuite(
    label: 'openai',
    fixtures: openai,
    makeClient: (transport, {retryConfig = const RetryConfig(maxAttempts: 1)}) => OpenAiCompatibleClient(
      transport: transport,
      baseUrl: 'https://api.test/v1',
      model: 'test-model',
      apiKey: 'test-key',
      retryConfig: retryConfig,
      clock: FakeLlmClock(),
    ),
  );
  runLlmClientContractSuite(
    label: 'anthropic',
    fixtures: anthropic,
    makeClient: (transport, {retryConfig = const RetryConfig(maxAttempts: 1)}) => AnthropicClient(
      transport: transport,
      baseUrl: 'https://api.test/v1',
      model: 'test-model',
      apiKey: 'test-key',
      retryConfig: retryConfig,
      clock: FakeLlmClock(),
    ),
  );
  runLlmClientContractSuite(
    label: 'gemini',
    fixtures: gemini,
    makeClient: (transport, {retryConfig = const RetryConfig(maxAttempts: 1)}) => GeminiClient(
      transport: transport,
      baseUrl: 'https://api.test/v1beta',
      model: 'test-model',
      apiKey: 'test-key',
      retryConfig: retryConfig,
      clock: FakeLlmClock(),
    ),
  );
}
