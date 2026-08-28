// HAND-CURATED regression tests for the McpTransport value object +
// McpTransportProvider stub + SSE/stdio transport stubs. Pattern mirrors spec 033.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/domain/services/mcp_transport_service.dart';
import 'package:zuraffa_agent/src/data/providers/mcp_transport/mcp_transport_provider.dart';
import 'package:zuraffa_agent/src/mcp/io_sse_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';

void main() {
  group('arrarrny/zuraffa_agent#4 - McpTransport value equality', () {
    test('McpTransport equality is value-based across all fields', () {
      final a = McpTransport(id: 'id-a', transportType: 'sse', endpoint: 'http://localhost:8080/sse', authRequired: true);
      final b = McpTransport(id: 'id-a', transportType: 'sse', endpoint: 'http://localhost:8080/sse', authRequired: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('McpTransport inequality differs when a field changes', () {
      final a = McpTransport(id: 'id-a', transportType: 'sse', endpoint: 'http://localhost:8080/sse', authRequired: true);
      final b = McpTransport(id: 'id-b', transportType: 'stdio', endpoint: 'http://localhost:8080/sse', authRequired: false);
      expect(a == b, isFalse);
    });

    test('McpTransport inequality detected per-field: id', () {
      final a = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://x', authRequired: false);
      final b = McpTransport(id: '2', transportType: 'sse', endpoint: 'http://x', authRequired: false);
      expect(a == b, isFalse);
    });

    test('McpTransport inequality detected per-field: transportType', () {
      final a = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://x', authRequired: false);
      final b = McpTransport(id: '1', transportType: 'stdio', endpoint: 'http://x', authRequired: false);
      expect(a == b, isFalse);
    });

    test('McpTransport inequality detected per-field: endpoint', () {
      final a = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://a', authRequired: false);
      final b = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://b', authRequired: false);
      expect(a == b, isFalse);
    });

    test('McpTransport inequality detected per-field: authRequired', () {
      final a = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://x', authRequired: true);
      final b = McpTransport(id: '1', transportType: 'sse', endpoint: 'http://x', authRequired: false);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#4 - McpTransport toString', () {
    test('toString includes id, transportType, and endpoint', () {
      final t = McpTransport(id: 'sse-1', transportType: 'sse', endpoint: 'http://localhost:9000/mcp', authRequired: true);
      final s = t.toString();
      expect(s, contains('sse-1'));
      expect(s, contains('sse'));
      expect(s, contains('http://localhost:9000/mcp'));
    });
  });

  group('arrarrny/zuraffa_agent#4 - McpTransport clean-arch layers', () {
    test('McpTransportProvider is a McpTransportService', () {
      final provider = McpTransportProvider();
      expect(provider, isA<McpTransportService>());
    });

    test('McpTransportProvider.current returns the active transport', () async {
      final transport = await McpTransportProvider().current(NoParams());
      expect(transport, isA<McpTransport>());
      expect(transport.id, 'inproc');
      expect(transport.transportType, 'in-proc');
      expect(transport.endpoint, 'in-process');
      expect(transport.authRequired, isFalse);
    });

    test('McpTransportProvider honors an injected active transport', () async {
      final injected = const McpTransport(
        id: 'remote',
        transportType: 'sse',
        endpoint: 'http://localhost:8080/sse',
        authRequired: true,
      );
      final transport = await McpTransportProvider(injected).current(NoParams());
      expect(transport, same(injected));
    });

    test('McpTransportProvider.count returns 1', () async {
      expect(await McpTransportProvider().count(NoParams()), 1);
    });
  });

  group('IoSseMcpTransport stub behavior', () {
    test('starts with isOpen=false', () {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse');
      expect(t.isOpen, isFalse);
    });

    test('open() throws UnimplementedError', () {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse');
      expect(() => t.open(), throwsA(isA<UnimplementedError>()));
    });

    test('send() throws UnimplementedError', () async {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse');
      expect(
        () => t.send(const McpWireRequestListTools()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('close() sets isOpen=false and is idempotent', () async {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse');
      await t.close();
      expect(t.isOpen, isFalse);
      // second close should not throw
      await t.close();
      expect(t.isOpen, isFalse);
    });

    test('notifications is a broadcast stream', () {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse');
      // Multiple listeners on the same stream should not throw
      expect(() {
        t.notifications.listen((_) {});
        t.notifications.listen((_) {});
      }, returnsNormally);
    });

    test('accepts optional bearerToken', () {
      final t = IoSseMcpTransport(endpoint: 'http://localhost:8080/sse', bearerToken: 'tok-123');
      expect(t.isOpen, isFalse);
    });
  });

  group('IoStdioMcpTransport stub behavior', () {
    test('starts with isOpen=false', () {
      final t = IoStdioMcpTransport(executable: 'node');
      expect(t.isOpen, isFalse);
    });

    test('open() throws UnimplementedError', () {
      final t = IoStdioMcpTransport(executable: 'node');
      expect(() => t.open(), throwsA(isA<UnimplementedError>()));
    });

    test('send() throws UnimplementedError', () async {
      final t = IoStdioMcpTransport(executable: 'node');
      expect(
        () => t.send(const McpWireRequestListTools()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('close() sets isOpen=false and is idempotent', () async {
      final t = IoStdioMcpTransport(executable: 'node');
      await t.close();
      expect(t.isOpen, isFalse);
      // second close should not throw
      await t.close();
      expect(t.isOpen, isFalse);
    });

    test('accepts empty args list', () {
      final t = IoStdioMcpTransport(executable: 'python3', args: []);
      expect(t.isOpen, isFalse);
    });

    test('accepts non-empty args list', () {
      final t = IoStdioMcpTransport(executable: 'node', args: ['server.js', '--port', '3000']);
      expect(t.isOpen, isFalse);
    });
  });
}
