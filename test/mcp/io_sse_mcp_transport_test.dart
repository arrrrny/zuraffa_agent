// Integration tests for `IoSseMcpTransport` (spec 105, issue #107).
//
// Hermetic: every test binds a loopback `HttpServer` (port 0) that plays the
// MCP SSE peer — GET for the event stream, POST for RPC — per the dialect
// contract in specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.
// No external network.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/mcp/io_sse_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';

class _GetRecord {
  final String? accept;
  final String? authorization;
  _GetRecord(HttpHeaders h)
      : accept = h.value(HttpHeaders.acceptHeader),
        authorization = h.value(HttpHeaders.authorizationHeader);
}

class _PostRecord {
  final String? authorization;
  final String body;
  _PostRecord(HttpHeaders h, this.body)
      : authorization = h.value(HttpHeaders.authorizationHeader);
}

/// Loopback mock of the SSE MCP endpoint.
class _SseMock {
  HttpServer? _server;
  final _openResponses = <HttpResponse>[];
  final getRequests = <_GetRecord>[];
  final postRequests = <_PostRecord>[];
  int getStatus = 200;

  /// Raw SSE text written to the stream once it is open (events, keep-alives).
  String streamText = '';

  /// Responds to a POST with the JSON body to reply with.
  Map<String, Object?> Function(Map<String, Object?> envelope)? postResponder;
  int postStatus = 200;

  late Uri url;

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    url = Uri.parse('http://127.0.0.1:${server.port}/mcp');
    server.listen(_handle, onError: (Object _) {});
  }

  Future<void> _handle(HttpRequest req) async {
    if (req.method == 'GET') {
      getRequests.add(_GetRecord(req.headers));
      if (getStatus != 200) {
        req.response.statusCode = getStatus;
        await req.response.close();
        return;
      }
      req.response.headers.contentType = ContentType('text', 'event-stream');
      for (final line in streamText.split('\n')) {
        req.response.writeln(line);
      }
      await req.response.flush();
      _openResponses.add(req.response); // hold the stream open
      return;
    }
    if (req.method == 'POST') {
      final body = await utf8.decoder.bind(req).join();
      postRequests.add(_PostRecord(req.headers, body));
      final responder = postResponder;
      final reply = responder == null
          ? <String, Object?>{}
          : responder(jsonDecode(body) as Map<String, dynamic>);
      req.response.statusCode = postStatus;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(reply));
      await req.response.close();
    }
  }

  Future<void> stop() async {
    for (final r in _openResponses) {
      try {
        await r.close();
      } on HttpException {
        // client aborted first — fine
      }
    }
    await _server?.close(force: true);
  }
}

void main() {
  group('spec-105 — IoSseMcpTransport', () {
    late _SseMock mock;
    setUp(() async {
      mock = _SseMock();
      await mock.start();
    });
    tearDown(() async {
      await mock.stop();
    });

    test(
        'U13: open GETs the event stream with auth headers and reports open',
        () async {
      final transport = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        bearerToken: 'tok-123',
      );
      await transport.open();
      expect(transport.isOpen, isTrue);
      expect(mock.getRequests, hasLength(1));
      expect(mock.getRequests.single.accept, 'text/event-stream');
      expect(mock.getRequests.single.authorization, 'Bearer tok-123');
      await transport.open(); // idempotent: no second GET
      expect(mock.getRequests, hasLength(1));
      await transport.close();
      await mock.stop();
    });

    test('U14: non-200 open fails typed; endpoint validated at construction',
        () async {
      mock.getStatus = 404;
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      await expectLater(
        transport.open(),
        throwsA(isA<McpWireOpenException>()),
      );
      expect(transport.isOpen, isFalse);
      expect(
        () => IoSseMcpTransport(endpoint: 'ftp://nope/x'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
