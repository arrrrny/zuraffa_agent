// Tests for lib/src/llm/llm_client.dart value objects — Spec 007 (US: shared contract).
// TDD: behavior U1 (value objects are immutable value types with spec-exact
// fields), U2 (typed error) — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

void main() {
  group('LlmClient value objects (U1)', () {
    test('LlmUsage, LlmToolCall, LlmResponse, LlmResponseChunk are value types with spec-exact fields', () {
      final usage = LlmUsage(
        inputTokens: 25,
        outputTokens: 42,
        cachedTokens: 8,
        thoughtTokens: 7,
      );
      expect(
        usage,
        equals(LlmUsage(
          inputTokens: 25,
          outputTokens: 42,
          cachedTokens: 8,
          thoughtTokens: 7,
        )),
      );
      expect(usage.copyWith(outputTokens: 99).outputTokens, 99);
      expect(usage.copyWith(outputTokens: 99).inputTokens, 25);

      final call = LlmToolCall(
        id: 'call_1',
        name: 'get_weather',
        arguments: const {'city': 'Paris'},
      );
      expect(
        call,
        equals(LlmToolCall(
          id: 'call_1',
          name: 'get_weather',
          arguments: const {'city': 'Paris'},
        )),
      );
      expect(call.arguments['city'], 'Paris');

      final resp = LlmResponse(
        content: 'hi',
        toolCalls: [call],
        usage: usage,
        finishReason: 'stop',
      );
      expect(resp.content, 'hi');
      expect(resp.toolCalls.single.name, 'get_weather');
      expect(resp.usage.outputTokens, 42);
      expect(resp.finishReason, 'stop');

      final chunk = LlmResponseChunk(content: 'he', isComplete: false);
      expect(chunk.content, 'he');
      expect(chunk.isComplete, isFalse);

      final done = LlmResponseChunk(
        content: 'llo',
        usage: usage,
        isComplete: true,
        finishReason: 'stop',
      );
      expect(done.isComplete, isTrue);
      expect(done.usage, equals(usage));
    });
  });
}
