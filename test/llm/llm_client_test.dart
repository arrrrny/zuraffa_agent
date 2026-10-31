// Tests for lib/src/llm/llm_client.dart value objects — Spec 007 (US: shared contract).
// TDD: behavior U1 (value objects are immutable value types with spec-exact
// fields), U2 (typed error) — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

void main() {
  group('LlmClient value objects (U1)', () {
    test('LlmUsage, LlmToolCall, LlmResponse, LlmResponseChunk are value types '
        'with spec-exact fields', () {
      const usage = LlmUsage(
        inputTokens: 25,
        outputTokens: 42,
        cachedTokens: 8,
        thoughtTokens: 7,
      );
      expect(
        usage,
        equals(
          const LlmUsage(
            inputTokens: 25,
            outputTokens: 42,
            cachedTokens: 8,
            thoughtTokens: 7,
          ),
        ),
      );
      expect(usage.copyWith(outputTokens: 99).outputTokens, 99);
      expect(usage.copyWith(outputTokens: 99).inputTokens, 25);

      const call = LlmToolCall(
        id: 'call_1',
        name: 'get_weather',
        arguments: {'city': 'Paris'},
      );
      expect(
        call,
        equals(
          const LlmToolCall(
            id: 'call_1',
            name: 'get_weather',
            arguments: {'city': 'Paris'},
          ),
        ),
      );
      expect(call.arguments['city'], 'Paris');

      const resp = LlmResponse(
        content: 'hi',
        toolCalls: [call],
        usage: usage,
        finishReason: 'stop',
      );
      expect(resp.content, 'hi');
      expect(resp.toolCalls.single.name, 'get_weather');
      expect(resp.usage.outputTokens, 42);
      expect(resp.finishReason, 'stop');

      const chunk = LlmResponseChunk(content: 'he', isComplete: false);
      expect(chunk.content, 'he');
      expect(chunk.isComplete, isFalse);

      const done = LlmResponseChunk(
        content: 'llo',
        usage: usage,
        isComplete: true,
        finishReason: 'stop',
      );
      expect(done.isComplete, isTrue);
      expect(done.usage, equals(usage));
    });
  });
  group('LlmHttpException (U2)', () {
    test('carries provider, statusCode, body, and a readable message', () {
      const err = LlmHttpException(
        provider: 'openai',
        statusCode: 503,
        body: '{"error":{"message":"overloaded"}}',
      );
      expect(err.provider, 'openai');
      expect(err.statusCode, 503);
      expect(err.body, '{"error":{"message":"overloaded"}}');
      expect(err.toString(), contains('503'));
      expect(err.toString(), contains('openai'));
      expect(err.toString(), contains('overloaded'));
    });
  });
}
