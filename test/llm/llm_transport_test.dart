// Tests for lib/src/llm/llm_transport.dart seam + fake helper — Spec 007.
// TDD: behavior U3 (seam round-trips via the fixture-replaying fake).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';

import 'fake_llm_transport.dart';

void main() {
  group('LlmTransport seam (U3)', () {
    test('round-trips a request to a status/headers/body response and a line stream via the fake', () async {
      final transport = FakeLlmTransport(
        script: [
          const ScriptedResponse(
            statusCode: 200,
            headers: {'content-type': 'application/json'},
            body: '{"ok":true}',
          ),
          const ScriptedResponse(
            statusCode: 200,
            headers: {'content-type': 'text/event-stream'},
            lines: ['data: {"a":1}', '', 'data: [DONE]'],
          ),
        ],
      );

      final request = LlmHttpRequest(
        uri: Uri.parse('https://api.test/v1/chat'),
        headers: const {'authorization': 'Bearer test-key'},
        body: '{"model":"m"}',
      );

      final response = await transport.send(request);
      expect(response.statusCode, 200);
      expect(response.isOk, isTrue);
      expect(response.body, '{"ok":true}');
      expect(response.headers['content-type'], 'application/json');

      // The fake recorded the outgoing request verbatim.
      expect(transport.requests, hasLength(1));
      expect(transport.requests.single.uri.toString(),
          'https://api.test/v1/chat');
      expect(transport.requests.single.headers['authorization'],
          'Bearer test-key');
      expect(transport.requests.single.body, '{"model":"m"}');

      final streamed = await transport.openStream(request);
      expect(streamed.statusCode, 200);
      expect(streamed.isOk, isTrue);
      expect(
        await streamed.lines.toList(),
        ['data: {"a":1}', '', 'data: [DONE]'],
      );
      expect(transport.requests, hasLength(2));
    });
  });
}
