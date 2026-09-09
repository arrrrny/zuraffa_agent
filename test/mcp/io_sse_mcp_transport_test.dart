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
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart'
    show McpWireClosedException;
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
      // dart:io quirk (verified by probe): HttpResponse.flush() completing
      // does NOT push buffered body bytes for a held-open chunked response;
      // bufferOutput=false streams writes straight to the socket.
      req.response.bufferOutput = false;
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

    test('U15: tools/list POSTs the contract envelope and maps the result',
        () async {
      mock.postResponder = (envelope) => {
            'jsonrpc': '2.0',
            'id': envelope['id'],
            'result': {
              'tools': [
                {
                  'name': 'echo',
                  'description': 'Echoes arguments',
                  'paramsSchema': {'type': 'object'},
                },
              ],
            },
          };
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      final payload = (resp as McpWireResponseOk).payload;
      expect(payload['tools'], isNotEmpty);
      final posted = mock.postRequests.single;
      final envelope = jsonDecode(posted.body) as Map<String, dynamic>;
      expect(envelope['jsonrpc'], '2.0');
      expect(envelope['method'], 'tools/list');
      await transport.close();
    });

    test('U16: tools/call POST round-trips arguments and carries auth',
        () async {
      mock.postResponder = (envelope) => {
            'jsonrpc': '2.0',
            'id': envelope['id'],
            'result': {
              'echo': (envelope['params'] as Map)['arguments'],
            },
          };
      final transport = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        bearerToken: 'tok-1',
      );
      await transport.open();
      final resp = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'x': 1}),
      );
      expect(resp, isA<McpWireResponseOk>());
      expect((resp as McpWireResponseOk).payload, {
        'echo': {'x': 1},
      });
      final posted = mock.postRequests.single;
      expect(posted.authorization, 'Bearer tok-1');
      final envelope = jsonDecode(posted.body) as Map<String, dynamic>;
      final params = envelope['params'] as Map<String, dynamic>;
      expect(params['name'], 'echo');
      expect(params['arguments'], {'x': 1});
      await transport.close();
    });

    test('U17: POST failures map — 2xx error body to the typed error '
        'response, non-2xx to a typed throw', () async {
      mock.postResponder = (envelope) => {
            'jsonrpc': '2.0',
            'id': envelope['id'],
            'error': {'code': -32000, 'message': 'tool exploded'},
          };
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      await transport.open();
      final resp = await transport.send(
        const McpWireRequestCallTool(name: 'boom', arguments: {}),
      );
      expect(resp, isA<McpWireResponseError>());
      final err = resp as McpWireResponseError;
      expect(err.code, '-32000');
      expect(err.message, 'tool exploded');
      await transport.close();

      mock.postStatus = 500;
      mock.postResponder = null;
      final transport2 = IoSseMcpTransport(endpoint: mock.url.toString());
      await transport2.open();
      await expectLater(
        transport2.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
      await transport2.close();
    });

    test('U18: the SSE parser surfaces tools-changed and ignores noise',
        () async {
      mock.streamText = [
        // keep-alive comment with CRLF terminators
        ': keep-alive ping\r\n\r\n',
        // an unrecognized notification method
        'data: {"jsonrpc":"2.0","method":"other/notification"}\r\n\r\n',
        // an empty-data event
        'data: \r\n\r\n',
        // the real notification, split across two data: fields
        'data: {"jsonrpc":"2.0",\r\n',
        'data:  "method":"notifications/tools/list_changed"}\r\n\r\n',
      ].join();
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      // Subscribe BEFORE opening: the mock writes at stream-open time and
      // `notifications` is a broadcast stream — events emitted before a
      // listener attaches are dropped.
      final notificationFuture = transport.notifications.first
          .timeout(const Duration(seconds: 5));
      await transport.open();
      final notification = await notificationFuture;
      expect(notification, isA<McpWireNotificationToolsChanged>());
      await transport.close();
    });
  });
}
