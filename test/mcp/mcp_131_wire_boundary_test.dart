// Issue #131 — Validate the MCP wire boundary: every `McpWireResponse` is
// checked against the JSON-RPC 2.0 envelope (`jsonrpc: "2.0"`, `id` matches
// the request, `result` XOR `error`), responses over a size cap (default
// 1 MiB) are rejected before they reach the engine, and tool-result content
// carrying control characters / unmatched surrogate pairs is rejected.
//
// Three lanes:
//   1. `McpWireValidator` unit tests — every rejection path, pure, no I/O.
//   2. `IoSseMcpTransport` against a loopback `HttpServer` mock — the real
//      POST response path (house pattern from the spec-105 tests).
//   3. `IoStdioMcpTransport` against the mock subprocess in `badwire` mode.
// Plus one client-level guard: a wire rejection surfaces as `McpCallError`
// and is never retried (the codes are not in `transientCallCodes`).

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/io_sse_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_guard.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire_validation.dart';
import 'package:zuraffa_agent/src/mcp/sse_mcp_client.dart';

import '_fake_wire.dart';
import '_mock_stdio_mcp_server.dart' show mockScriptPath;

final _scriptPath = File(mockScriptPath).absolute.path;

IoStdioMcpTransport _spawn(String mode, {int? maxResponseBytes}) =>
    IoStdioMcpTransport(
      executable: Platform.resolvedExecutable,
      args: [_scriptPath, mode],
      maxResponseBytes: maxResponseBytes,
    );

Map<String, dynamic> _okEnvelope({Object? id = 0, Object? result}) => {
  'jsonrpc': '2.0',
  'id': id,
  'result': result ?? <String, dynamic>{'ok': true},
};

McpWireResponse _validate(
  Map<String, dynamic> envelope, {
  int? maxResponseBytes,
  String? rawBody,
  Object? expectedId,
}) {
  return McpWireValidator(
    maxResponseBytes: maxResponseBytes ?? defaultMcpWireMaxResponseBytes,
  ).validateResponse(
    rawBody: rawBody ?? jsonEncode(envelope),
    message: envelope,
    expectedId: expectedId ?? envelope['id'],
  );
}

void _expectViolation(McpWireResponse resp, String code) {
  expect(
    resp,
    isA<McpWireResponseError>(),
    reason: 'expected a $code rejection',
  );
  final err = resp as McpWireResponseError;
  expect(err.code, code);
}

void _expectOk(McpWireResponse resp) {
  expect(
    resp,
    isA<McpWireResponseOk>(),
    reason: 'expected the response to pass',
  );
}

/// Loopback mock of the SSE MCP endpoint (minimal spec-105 pattern: GET
/// opens the event stream, POST answers with the programmed JSON-RPC body).
class _SseMock {
  HttpServer? _server;
  final _openResponses = <HttpResponse>[];

  /// Programmed JSON-RPC reply for a POST (echoes the request envelope).
  Map<String, Object?> Function(Map<String, Object?> envelope)? postResponder;

  /// When set, the POST reply is this verbatim body (non-object JSON, exact
  /// byte-size boundary cases).
  String? rawPostBody;

  /// Stream the POST reply chunked (no Content-Length → exercises the
  /// post-read half of the size cap).
  bool chunked = false;

  /// When set, the POST reply streams chunks forever (never closes on its
  /// own) — the client must abort the read at the cap instead of buffering
  /// the unbounded body.
  bool endlessPost = false;

  late Uri url;

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    url = Uri.parse('http://127.0.0.1:${server.port}/mcp');
    server.listen(_handle, onError: (Object _) {});
  }

  Future<void> _handle(HttpRequest req) async {
    if (req.method == 'GET') {
      req.response.headers.contentType = ContentType('text', 'event-stream');
      req.response.bufferOutput = false;
      req.response.writeln(': keep-alive');
      await req.response.flush();
      _openResponses.add(req.response); // hold the stream open
      return;
    }
    if (endlessPost) {
      // Unbounded chunked 2xx body: bufferOutput=false streams each write
      // straight to the socket (the buffered-flush() quirk pinned in the
      // adapter-test mock). Only a client that ABORTS the read at the cap
      // can complete this request — one that buffers the whole stream
      // first hangs on it forever.
      req.response.bufferOutput = false;
      req.response.headers.contentType = ContentType.json;
      for (var i = 0; i < 1024; i++) {
        try {
          req.response.write('{"pad":"${'x' * 4096}"}');
          await req.response.flush();
        } on Object {
          break; // client aborted — the socket is gone
        }
      }
      try {
        await req.response.close();
      } on Object {
        // already aborted — nothing to close
      }
      return;
    }
    final body = await utf8.decoder.bind(req).join();
    final reply =
        rawPostBody ??
        jsonEncode(
          postResponder?.call(jsonDecode(body) as Map<String, dynamic>) ??
              <String, Object?>{},
        );
    if (chunked) req.response.bufferOutput = false;
    req.response.headers.contentType = ContentType.json;
    req.response.write(reply);
    await req.response.close();
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
  group('issue-131 — McpWireValidator: JSON-RPC envelope', () {
    test('V1: a response with no jsonrpc member is a protocol violation', () {
      final envelope = {
        'id': 0,
        'result': {'ok': true},
      };
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V2: a jsonrpc version other than "2.0" is a protocol violation', () {
      final envelope = {
        'jsonrpc': '1.0',
        'id': 0,
        'result': {'ok': true},
      };
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test(
      'V3: a response id that does not match the request id is rejected',
      () {
        _expectViolation(
          _validate(_okEnvelope(id: 0), expectedId: 7),
          'protocol-violation',
        );
      },
    );

    test('V4: a response id of the wrong JSON type ("0" vs 0) is rejected', () {
      _expectViolation(
        _validate(_okEnvelope(id: '0'), expectedId: 0),
        'protocol-violation',
      );
    });

    test('V5: a response with no id member is a protocol violation', () {
      final envelope = {
        'jsonrpc': '2.0',
        'result': {'ok': true},
      };
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V6: result and error together are a protocol violation (XOR)', () {
      final envelope = {
        'jsonrpc': '2.0',
        'id': 0,
        'result': {'ok': true},
        'error': {'code': -32000, 'message': 'both'},
      };
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V7: neither result nor error is a protocol violation (XOR)', () {
      final envelope = {'jsonrpc': '2.0', 'id': 0, 'note': 'neither'};
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V8: a non-object error member is a protocol violation', () {
      final envelope = {'jsonrpc': '2.0', 'id': 0, 'error': 'boom'};
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V9: a non-object result member is a protocol violation', () {
      final envelope = {'jsonrpc': '2.0', 'id': 0, 'result': 'hello'};
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V10: a null result member is a protocol violation', () {
      final envelope = {'jsonrpc': '2.0', 'id': 0, 'result': null};
      _expectViolation(_validate(envelope), 'protocol-violation');
    });

    test('V11: a valid error envelope still maps to the typed error', () {
      final resp = _validate({
        'jsonrpc': '2.0',
        'id': 3,
        'error': {'code': -32000, 'message': 'tool exploded'},
      });
      expect(resp, isA<McpWireResponseError>());
      final err = resp as McpWireResponseError;
      expect(err.code, '-32000');
      expect(err.message, 'tool exploded');
    });

    test('V12: extra JSON-RPC fields are tolerated on a valid envelope', () {
      final envelope = _okEnvelope(result: {'ok': true})
        ..['params'] = {'leftover': 1};
      _expectOk(_validate(envelope));
    });
  });

  group('issue-131 — McpWireValidator: size cap', () {
    test('V13: a body over a custom cap is rejected as response-too-large', () {
      final envelope = _okEnvelope(result: {'pad': 'x' * 512});
      _expectViolation(
        _validate(envelope, maxResponseBytes: 64),
        'response-too-large',
      );
    });

    test('V14: a body exactly at the cap passes', () {
      final raw = jsonEncode(_okEnvelope(result: {'pad': 'x' * 64}));
      final cap = utf8.encode(raw).length;
      _expectOk(
        _validate(
          _okEnvelope(result: {'pad': 'x' * 64}),
          rawBody: raw,
          maxResponseBytes: cap,
        ),
      );
    });

    test('V15: a body over the default 1 MiB cap is rejected', () {
      final envelope = _okEnvelope(result: {'pad': 'x' * (1024 * 1024 + 64)});
      expect(defaultMcpWireMaxResponseBytes, 1024 * 1024);
      _expectViolation(_validate(envelope), 'response-too-large');
    });

    test('V16: the cap counts UTF-8 bytes, not UTF-16 code units', () {
      // 'é' is one UTF-16 code unit but two UTF-8 bytes: a byte-based cap
      // must reject a body whose code-unit length sneaks under the cap.
      final envelope = _okEnvelope(result: {'pad': 'é' * 400});
      final raw = jsonEncode(envelope);
      final cap = raw.length; // char-count passes, byte-count must fail
      expect(utf8.encode(raw).length, greaterThan(cap));
      _expectViolation(
        _validate(envelope, rawBody: raw, maxResponseBytes: cap),
        'response-too-large',
      );
    });
  });

  group('issue-131 — McpWireValidator: content policy', () {
    test('V17: a NUL control character (U+0000) is invalid content', () {
      final envelope = _okEnvelope(result: {'text': 'a\u0000b'});
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V18: a C0 control character (U+001F) is invalid content', () {
      final envelope = _okEnvelope(result: {'text': 'a\u001Fb'});
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V19: DEL (U+007F) is invalid content', () {
      final envelope = _okEnvelope(result: {'text': 'a\u007Fb'});
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V20: a C1 control character (U+0085) is invalid content', () {
      final envelope = _okEnvelope(result: {'text': 'a\u0085b'});
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V21: an unmatched high surrogate is invalid content', () {
      final envelope = _okEnvelope(
        result: {'text': 'x${String.fromCharCode(0xD800)}y'},
      );
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V22: an unmatched low surrogate is invalid content', () {
      final envelope = _okEnvelope(
        result: {'text': 'x${String.fromCharCode(0xDC00)}y'},
      );
      _expectViolation(_validate(envelope), 'invalid-content');
    });

    test('V23: a control character in a map key is invalid content', () {
      final envelope = _okEnvelope(result: {'bad\u0001key': 'value'});
      final resp = _validate(envelope);
      _expectViolation(resp, 'invalid-content');
      // The offending key is named in the diagnostic, log-safely
      // (control characters are \uXXXX-escaped), so it can be acted on.
      final err = resp as McpWireResponseError;
      expect(err.message, contains(r'$.result."bad\u0001key"'));
    });

    test('V24: the violation message names the JSON path of the content', () {
      final envelope = _okEnvelope(
        result: {
          'content': [
            {'type': 'text', 'text': 'ok\u0002bad'},
          ],
        },
      );
      final resp = _validate(envelope);
      final err = resp as McpWireResponseError;
      expect(err.code, 'invalid-content');
      expect(err.message, contains(r'$.result.content[0].text'));
    });

    test('V25: tab, newline and carriage return are allowed', () {
      final envelope = _okEnvelope(result: {'text': 'a\tb\nc\rd'});
      _expectOk(_validate(envelope));
    });

    test('V26: a valid surrogate pair (emoji) is allowed', () {
      final envelope = _okEnvelope(result: {'text': 'crab 🦀 ok'});
      _expectOk(_validate(envelope));
    });
  });

  group('issue-131 — IoSseMcpTransport wire boundary', () {
    late _SseMock mock;
    setUp(() async {
      mock = _SseMock();
      await mock.start();
    });
    tearDown(() async {
      await mock.stop();
    });

    test(
      'V27: a response with the wrong jsonrpc version is rejected typed',
      () async {
        mock.postResponder = (envelope) => {
          'jsonrpc': '1.0',
          'id': envelope['id'],
          'result': {'echo': true},
        };
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {}),
        );
        _expectViolation(resp, 'protocol-violation');
      },
    );

    test('V28: a response id that does not match the request is rejected '
        'typed', () async {
      mock.postResponder = (envelope) => {
        'jsonrpc': '2.0',
        'id': (envelope['id'] as int) + 1000,
        'result': {'echo': true},
      };
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      addTearDown(transport.close);
      await transport.open();
      final resp = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {}),
      );
      _expectViolation(resp, 'protocol-violation');
    });

    test(
      'V29: a response carrying both result and error is rejected typed',
      () async {
        mock.postResponder = (envelope) => {
          'jsonrpc': '2.0',
          'id': envelope['id'],
          'result': {'echo': true},
          'error': {'code': -32000, 'message': 'both'},
        };
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {}),
        );
        _expectViolation(resp, 'protocol-violation');
      },
    );

    test(
      'V30: a decodable non-object body is rejected typed (not a crash)',
      () async {
        mock.rawPostBody = '[1,2,3]';
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(const McpWireRequestListTools());
        _expectViolation(resp, 'protocol-violation');
      },
    );

    test('V31: a chunked body over a custom cap is rejected on its actual '
        'bytes; the same body passes at the cap boundary', () async {
      final reply = jsonEncode(_okEnvelope(result: {'pad': 'x' * 512}));
      // Over the cap: chunked framing means no Content-Length, so the cap
      // must fire on the bytes actually read.
      mock.rawPostBody = reply;
      mock.chunked = true;
      final over = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        maxResponseBytes: 64,
      );
      addTearDown(over.close);
      await over.open();
      _expectViolation(
        await over.send(const McpWireRequestListTools()),
        'response-too-large',
      );
      await over.close();

      // Exactly at the cap: the identical body passes.
      final atCap = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        maxResponseBytes: utf8.encode(reply).length,
      );
      addTearDown(atCap.close);
      await atCap.open();
      _expectOk(await atCap.send(const McpWireRequestListTools()));
    });

    test('V32: a declared Content-Length over the default 1 MiB cap is '
        'rejected before the body is trusted', () async {
      final reply = jsonEncode(
        _okEnvelope(result: {'pad': 'x' * (1024 * 1024 + 64)}),
      );
      // Buffered reply → dart:io frames it with an explicit Content-Length,
      // so the declared half of the cap fires before the body is read.
      mock.rawPostBody = reply;
      final transport = IoSseMcpTransport(endpoint: mock.url.toString());
      addTearDown(transport.close);
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      _expectViolation(resp, 'response-too-large');
    });

    test(
      'V33: a control character in tool content is rejected typed',
      () async {
        mock.postResponder = (envelope) => {
          'jsonrpc': '2.0',
          'id': envelope['id'],
          'result': {
            'content': [
              {'type': 'text', 'text': 'a\u0000b'},
            ],
          },
        };
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {}),
        );
        _expectViolation(resp, 'invalid-content');
      },
    );

    test(
      'V34: an unmatched surrogate in tool content is rejected typed',
      () async {
        mock.postResponder = (envelope) => {
          'jsonrpc': '2.0',
          'id': envelope['id'],
          'result': {
            'content': [
              {'type': 'text', 'text': 'x${String.fromCharCode(0xDC00)}y'},
            ],
          },
        };
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {}),
        );
        _expectViolation(resp, 'invalid-content');
      },
    );

    test(
      'V35: well-formed content with newlines and emoji passes through',
      () async {
        mock.postResponder = (envelope) => {
          'jsonrpc': '2.0',
          'id': envelope['id'],
          'result': {
            'content': [
              {'type': 'text', 'text': 'line1\nline2\t🦀'},
            ],
          },
        };
        final transport = IoSseMcpTransport(endpoint: mock.url.toString());
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'echo', arguments: {}),
        );
        _expectOk(resp);
        expect(
          ((resp as McpWireResponseOk).payload['content'] as List).first as Map,
          {'type': 'text', 'text': 'line1\nline2\t🦀'},
        );
      },
    );

    test('V43: a chunked 2xx stream over the cap is aborted as it arrives — '
        'not fully buffered first — and the session survives', () async {
      mock.postResponder = (envelope) => {
        'jsonrpc': '2.0',
        'id': envelope['id'],
        'result': {'ok': true},
      };
      mock.endlessPost = true;
      final transport = IoSseMcpTransport(
        endpoint: mock.url.toString(),
        maxResponseBytes: 64,
      );
      addTearDown(transport.close);
      await transport.open();
      // The reply never ends: only a read that ABORTS at the cap (not
      // one that buffers the whole stream first — the pre-fix exposure —
      // can complete this send within the timeout).
      final resp = await transport
          .send(const McpWireRequestListTools())
          .timeout(const Duration(seconds: 10));
      _expectViolation(resp, 'response-too-large');
      // The aborted POST did not poison the session: the event stream
      // (a separate socket) and the next RPC still work on this transport.
      mock.endlessPost = false;
      final stillWorks = await transport.send(const McpWireRequestListTools());
      _expectOk(stillWorks);
    });
  });

  group('issue-131 — IoStdioMcpTransport wire boundary', () {
    test(
      'V36: a wrong-jsonrpc response from the child is rejected typed',
      () async {
        final transport = _spawn('badwire');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'bad-jsonrpc', arguments: {}),
        );
        _expectViolation(resp, 'protocol-violation');
      },
    );

    test(
      'V37: a control character in tool content is rejected typed',
      () async {
        final transport = _spawn('badwire');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'ctrl-char', arguments: {}),
        );
        _expectViolation(resp, 'invalid-content');
      },
    );

    test(
      'V38: an unmatched surrogate in tool content is rejected typed',
      () async {
        final transport = _spawn('badwire');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'lone-surrogate', arguments: {}),
        );
        _expectViolation(resp, 'invalid-content');
      },
    );

    test(
      'V39: a response over the default 1 MiB cap is rejected typed',
      () async {
        final transport = _spawn('badwire');
        addTearDown(transport.close);
        await transport.open();
        final resp = await transport.send(
          const McpWireRequestCallTool(name: 'big', arguments: {}),
        );
        _expectViolation(resp, 'response-too-large');
      },
    );

    test('V40: a response over a custom cap is rejected typed', () async {
      final transport = _spawn('badwire', maxResponseBytes: 64);
      addTearDown(transport.close);
      await transport.open();
      final resp = await transport.send(
        McpWireRequestCallTool(name: 'echo', arguments: {'x': 'y' * 200}),
      );
      _expectViolation(resp, 'response-too-large');
    });

    test('V41: a rejection does not poison the session', () async {
      final transport = _spawn('badwire');
      addTearDown(transport.close);
      await transport.open();
      final rejected = await transport.send(
        const McpWireRequestCallTool(name: 'bad-jsonrpc', arguments: {}),
      );
      _expectViolation(rejected, 'protocol-violation');
      final stillWorks = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'x': 1}),
      );
      _expectOk(stillWorks);
      expect((stillWorks as McpWireResponseOk).payload, {
        'echo': {'x': 1},
      });
    });

    test('V44: an oversized child line is rejected typed by the byte-budgeted '
        'framer — never fully buffered — and the session survives', () async {
      final transport = _spawn('badwire', maxResponseBytes: 64);
      addTearDown(transport.close);
      await transport.open();
      // 'echo' answers with a ~250-byte line: the budgeted framer trips
      // past 64 bytes, discards the rest of the line and fails the
      // outstanding request typed (the oversized line's id is unroutable
      // without buffering the whole line — the thing the budget refuses).
      final resp = await transport.send(
        McpWireRequestCallTool(name: 'echo', arguments: {'x': 'y' * 200}),
      );
      _expectViolation(resp, 'response-too-large');
      final stillWorks = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'x': 1}),
      );
      _expectOk(stillWorks);
      expect((stillWorks as McpWireResponseOk).payload, {
        'echo': {'x': 1},
      });
    });
  });

  group('issue-131 — client mapping of wire rejections', () {
    test('V42: a wire rejection surfaces as McpCallError and is never '
        'retried', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(
        const McpWireResponseError(
          code: 'response-too-large',
          message:
              'MCP wire: response body of 1048608 bytes exceeds the '
              '1048576-byte wire cap',
        ),
      );
      const transport = McpTransport(
        id: 'sse-1',
        transportType: 'sse',
        endpoint: 'https://example.invalid/sse',
        authRequired: true,
      );
      final client = SseMcpClient(
        transport: transport,
        wireFactory: (token) => fakeWire,
        now: () => DateTime.utc(2026, 8, 27, 10, 0, 0),
        delay: (d) async {},
      );
      addTearDown(client.disconnect);
      await client.connect();
      final result = await client.callTool(
        'echo',
        const {},
        options: const McpCallOptions(
          readOnly: true,
          retry: McpRetryConfig(maxAttempts: 3),
        ),
      );
      expect(result, isA<McpCallError>());
      expect((result as McpCallError).code, 'response-too-large');
      // Not in transientCallCodes → exactly one send, no retry fan-out.
      expect(fakeWire.sentRequests, hasLength(1));
    });
  });
}
