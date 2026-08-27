// HAND-CURATED regression tests for the McpTransport value object +
// McpTransportProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/domain/services/mcp_transport_service.dart';
import 'package:zuraffa_agent/src/data/providers/mcp_transport/mcp_transport_provider.dart';

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
}
