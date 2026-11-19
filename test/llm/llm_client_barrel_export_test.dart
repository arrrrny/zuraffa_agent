// Tests for the barrel export of the typed LLM client seam — issue #188
// ("Packaging: export the typed LLM client seam from the barrel").
//
// Downstream packages deep-import
// `package:zuraffa_agent/src/llm/llm_client.dart` because the barrel did not
// re-export it. This test pins the barrel surface: all five public types of
// that seam must be reachable through
// `package:zuraffa_agent/zuraffa_agent.dart` without a deep import. Deep
// imports keep working after the export lands; they just become redundant.

import 'package:test/test.dart';
import 'package:zuraffa_agent/zuraffa_agent.dart';

void main() {
  group('LlmClient seam is exported from the barrel (issue #188)', () {
    test('all five typed seam types are reachable via the package barrel', () {
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

      // LlmClient is an abstract interface — reference its type only.
      expect(LlmClient, isNotNull);
    });
  });
}
