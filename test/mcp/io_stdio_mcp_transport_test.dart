// Integration tests for `IoStdioMcpTransport` (spec 105, issue #107).
//
// Hermetic: every test spawns the mock MCP child in
// `test/mcp/_mock_stdio_mcp_server.dart` via the current VM executable —
// real subprocess I/O, no external services, no prebuilt binaries.
// Dialect contract: specs/105-production-mcp-transports/contracts/mcp-wire-dialect.md.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';

final _scriptPath =
    File('test/mcp/_mock_stdio_mcp_server.dart').absolute.path;

IoStdioMcpTransport _spawn(String mode) => IoStdioMcpTransport(
      executable: Platform.resolvedExecutable,
      args: [_scriptPath, mode],
    );

void main() {
  group('spec-105 — IoStdioMcpTransport', () {
    test('U1: open spawns the mock child and reports open', () async {
      final transport = _spawn('echo');
      await transport.open();
      expect(transport.isOpen, isTrue);
      await transport.close();
    });

    test('U2: tools/list round-trips the advertised descriptors', () async {
      final transport = _spawn('echo');
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      final payload = (resp as McpWireResponseOk).payload;
      expect(payload['tools'], [
        {
          'name': 'echo',
          'description': 'Echoes arguments',
          'paramsSchema': {'type': 'object'},
        },
      ]);
      await transport.close();
    });

    test('U3: tools/call round-trips arguments and the session persists',
        () async {
      final transport = _spawn('echo');
      await transport.open();
      final first = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'x': 1}),
      );
      expect(first, isA<McpWireResponseOk>());
      expect((first as McpWireResponseOk).payload, {
        'echo': {'x': 1},
      });
      final second = await transport.send(
        const McpWireRequestCallTool(name: 'echo', arguments: {'y': 'z'}),
      );
      expect((second as McpWireResponseOk).payload, {
        'echo': {'y': 'z'},
      });
      await transport.close();
    });

    test('U4: constructor rejects an empty executable', () {
      expect(
        () => IoStdioMcpTransport(executable: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('U7: garbage lines are skipped and the session survives', () async {
      final transport = _spawn('garbage');
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      await transport.close();
    });

    test('U5: a JSON-RPC error response maps to the typed error response',
        () async {
      final transport = _spawn('garbage');
      await transport.open();
      final resp = await transport.send(
        const McpWireRequestCallTool(name: 'boom', arguments: {}),
      );
      expect(resp, isA<McpWireResponseError>());
      final err = resp as McpWireResponseError;
      expect(err.code, '-32601');
      expect(err.message, 'tool exploded');
      await transport.close();
    });

    test('U8: a response with an unknown id is dropped; the real answer still resolves',
        () async {
      // garbage mode emits a result for id 999 (nobody asked) at startup.
      final transport = _spawn('garbage');
      await transport.open();
      final resp = await transport.send(const McpWireRequestListTools());
      expect(resp, isA<McpWireResponseOk>());
      final payload = (resp as McpWireResponseOk).payload;
      expect(payload['tools'], isNotEmpty); // the echo descriptor, not 999's
      await transport.close();
    });
  });
}
