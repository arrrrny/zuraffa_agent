// Tests for lib/src/llm/io_llm_transport.dart — Spec 007, behavior U10.
// Uses a loopback HttpServer (tests may use dart:io; the purity gate only
// constrains lib/src runtime paths).

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/io_llm_transport.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';

void main() {
  group('IoLlmTransport (U10)', () {
    test('maps LlmHttpRequest onto HttpClient producing status, headers, body, and a line stream', () async {
      final received = <_RecordedRequest>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serverSub = server.listen((HttpRequest req) async {
        final body = await utf8.decoder.bind(req).join();
        final headerMap = <String, String>{};
        req.headers.forEach((name, values) {
          headerMap[name.toLowerCase()] = values.join(',');
        });
        received.add(_RecordedRequest(
            req.method, req.uri.path, headerMap, body));
        req.response.statusCode = 200;
        if (req.uri.path == '/v1/chat') {
          req.response.headers.contentType = ContentType.json;
          req.response.write('{"ok":true}');
        } else {
          req.response.headers.set('content-type', 'text/event-stream');
          req.response.write('data: {"a":1}\r\ndata: [DONE]\r\n');
        }
        await req.response.close();
      });

      final transport = IoLlmTransport(provider: 'openai');
      addTearDown(() async {
        await transport.close();
        await serverSub.cancel();
        await server.close(force: true);
      });

      final base = 'http://127.0.0.1:${server.port}';

      final response = await transport.send(LlmHttpRequest(
        uri: Uri.parse('$base/v1/chat'),
        headers: const {'authorization': 'Bearer test-key'},
        body: '{"model":"m"}',
      ));
      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
      expect(response.headers['content-type'], contains('application/json'));
      expect(received.single.method, 'POST');
      expect(received.single.path, '/v1/chat');
      expect(received.single.headers['authorization'], 'Bearer test-key');
      expect(received.single.body, '{"model":"m"}');

      final streamed = await transport.openStream(LlmHttpRequest(
        uri: Uri.parse('$base/v1/stream'),
        body: '{}',
      ));
      expect(streamed.statusCode, 200);
      expect(await streamed.lines.toList(),
          ['data: {"a":1}', 'data: [DONE]']);
    });
  });
}

class _RecordedRequest {
  final String method;
  final String path;
  final Map<String, String> headers;
  final String body;
  _RecordedRequest(this.method, this.path, this.headers, this.body);
}
