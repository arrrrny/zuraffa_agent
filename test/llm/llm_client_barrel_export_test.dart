// Tests for the barrel export of the typed LLM client seam — issue #188
// ("Packaging: export the typed LLM client seam from the barrel").
//
// Downstream packages deep-import
// `package:zuraffa_agent/src/llm/llm_client.dart` because the barrel did not
// re-export it. This test pins the barrel surface: all nine public types of
// that seam must be reachable through
// `package:zuraffa_agent/zuraffa_agent.dart` without a deep import. Deep
// imports keep working after the export lands; they just become redundant.
//
// A bare type reference pins only that the name resolves — a future `show`
// clause on the barrel export that narrows the seam would still compile
// against a name-only reference. So every type is exercised through its real
// shape (value construction, field access), and LlmClient is *implemented*
// through the barrel so a `show` clause that drops `generate`/`stream`/
// `close` breaks the build.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

// LlmClient is abstract: implement it through the barrel so a `show`
// clause that drops a member breaks the build.
class _BarrelLlmClient implements LlmClient {
  @override
  String get providerName => 'barrel';

  @override
  String get model => 'barrel-1';

  @override
  Future<LlmResponse> generate(LlmRequest request) async =>
      const LlmResponse(content: 'ok');

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) =>
      Stream.value(const LlmResponseChunk(isComplete: true));

  @override
  Future<void> close() async {}
}

void main() {
  group('LlmClient seam is exported from the barrel (issue #188)', () {
    test('all nine typed seam types are reachable via the package barrel', () {
      // Referencing each type through the barrel's import is the whole
      // assertion: a missing export is a compile error, so this test is RED
      // until `export 'src/llm/llm_client.dart';` lands in
      // lib/zuraffa_agent.dart.
      const request = LlmRequest(messages: <AgentMessage>[]);
      expect(request.messages, isEmpty);

      const toolSpec = LlmToolSpec(
        name: 'tool',
        description: 'a tool',
        parameters: <String, dynamic>{},
      );
      expect(toolSpec.name, 'tool');

      const toolCall = LlmToolCall(
        id: 'c1',
        name: 'tool',
        arguments: <String, dynamic>{},
      );
      expect(toolCall.id, 'c1');

      const response = LlmResponse(content: 'hi');
      expect(response.content, 'hi');
    });

    test('the rest of the seam file is exported too', () {
      const usage = LlmUsage(inputTokens: 3, outputTokens: 4);
      expect(usage.inputTokens, 3);
      expect(usage.outputTokens, 4);

      expect(const LlmResponseChunk().isComplete, isFalse);
      expect(
        const LlmResponseChunk(content: 'x', isComplete: true).content,
        'x',
      );

      expect(
        const LlmHttpException(
          provider: 'p',
          statusCode: 503,
          body: 'boom',
        ).statusCode,
        503,
      );

      expect(const LlmNetworkException(provider: 'p', cause: 'x').attempts, 1);
    });

    test('LlmClient shape is implementable through the barrel', () {
      final client = _BarrelLlmClient();
      expect(client.providerName, 'barrel');
      expect(client.model, 'barrel-1');
    });
  });
}
