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
  });
}
