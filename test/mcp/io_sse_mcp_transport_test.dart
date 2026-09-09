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
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';

final _scriptPath =
    File('test/mcp/_mock_stdio_mcp_server.dart').absolute.path;

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
  group('spec-105 — IoSseMcpTransport', () {    late _SseMock mock;
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

    test('U19: SSE lifecycle — misuse typed, open/close idempotent, close '
        'aborts the stream', () async {
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      await expectLater(
        transport.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
      await transport.open();
      await transport.open(); // no second GET
      expect(mock.getRequests, hasLength(1));
      await transport.close();
      await transport.close(); // no throw
      expect(transport.isOpen, isFalse);
      await expectLater(
        transport.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
    });

    test('A2: full SSE session with auth, list, call — and a typed 404 '
        'open failure (SC-002)', () async {
      mock.postResponder = (envelope) => {
            'jsonrpc': '2.0',
            'id': envelope['id'],
            'result': envelope['method'] == 'tools/list'
                ? {
                    'tools': [
                      {'name': 'echo', 'description': 'Echoes arguments'},
                    ],
                  }
                : {
                    'echo': (envelope['params'] as Map)['arguments'],
                  },
          };
      final transport = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        bearerToken: 'session-token',
      );
      await transport.open();
      final list = await transport.send(const McpWireRequestListTools());
      final tools = ((list as McpWireResponseOk).payload['tools'] as List)
          .cast<Map<dynamic, dynamic>>();
      expect(tools.single['name'], 'echo');
      final call = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'q': 7}),
      );
      expect((call as McpWireResponseOk).payload, {
        'echo': {'q': 7},
      });
      expect(
        mock.postRequests.map((p) => p.authorization),
        everyElement('Bearer session-token'),
      );
      await transport.close();

      // non-200 open fails typed with the status named
      mock.getStatus = 404;
      final failing = IoSseMcpTransport(endpoint: mock.url.toString());
      await expectLater(
        failing.open(),
        throwsA(
          predicate((Object e) =>
              e is McpWireOpenException && e.statusCode == 404),
        ),
      );
    });
  });

  group('spec-105 — cross-transport acceptance', () {
    test('A3: tools-changed notifications surface from both transports '
        '(SC-003)', () async {
      // stdio: the notify-mode child pushes before answering
      final stdio = IoStdioMcpTransport(
        executable: Platform.resolvedExecutable,
        args: [_scriptPath, 'notify'],
      );
      final stdioNotification =
          stdio.notifications.first.timeout(const Duration(seconds: 5));
      await stdio.open();
      expect(await stdioNotification, isA<McpWireNotificationToolsChanged>());

      // SSE: the loopback mock pushes at stream-open time
      final mock = _SseMock();
      await mock.start();
      mock.streamText =
          'data: {"jsonrpc":"2.0","method":"notifications/tools/list_changed"}'
          '\n\n';
      final sse = IoSseMcpTransport(endpoint: mock.url.toString());
      final sseNotification =
          sse.notifications.first.timeout(const Duration(seconds: 5));
      await sse.open();
      expect(await sseNotification, isA<McpWireNotificationToolsChanged>());

      await sse.close();
      await mock.stop();
      await stdio.close();
    });

    test('A4: lifecycle safety across transports (SC-004)', () async {
      // stdio: a child crash drops the session with typed failures
      final stdio = IoStdioMcpTransport(
        executable: Platform.resolvedExecutable,
        args: [_scriptPath, 'crash'],
      );
      await stdio.open();
      Object? captured;
      final exitCaught = Completer<void>();
      unawaited(
        stdio
            .send(const McpWireRequestCallTool(name: 'crash', arguments: {}))
            .then((_) {}, onError: (Object e) {
          captured = e;
          exitCaught.complete();
        }),
      );
      await exitCaught.future.timeout(const Duration(seconds: 10));
      expect(captured, isA<McpWireClosedException>());
      expect(stdio.isOpen, isFalse);

      // SSE: misuse is typed and lifecycle calls are no-ops
      final mock = _SseMock();
      await mock.start();
      final sse = IoSseMcpTransport(endpoint: mock.url.toString());
      await expectLater(
        sse.send(const McpWireRequestListTools()),
        throwsA(isA<McpWireClosedException>()),
      );
      await sse.open();
      await sse.open();
      expect(mock.getRequests, hasLength(1));
      await sse.close();
      await sse.close();
      expect(sse.isOpen, isFalse);
      await mock.stop();
    });
  });
}
