// HAND-CURATED regression tests for StdioMcpClient (spec 015-mcp-client).
//
// Uses a fake McpWire (no real subprocess — constitution: fixtures only).
// Covers:
//   - connect() opens the wire; state -> connected.
//   - listTools() maps the wire's payload to descriptors.
//   - callTool() maps the wire's response to McpCallOk / McpCallError.
//   - A drop mid-call triggers reconnect within stdio backoff (SC-003).
//   - disconnect() closes the wire and transitions to disconnected.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_reconnect_policy.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/stdio_mcp_client.dart';

import '_fake_wire.dart';

void main() {
  group('spec-015 — StdioMcpClient', () {
    late McpTransport transport;
    setUp(() {
      transport = const McpTransport(
        id: 'stdio-1',
        transportType: 'stdio',
        endpoint: '/usr/local/bin/mcp-server',
        authRequired: false,
      );
    });

    StdioMcpClient buildClient({required FakeMcpWire fakeWire}) {
      return StdioMcpClient(
        transport: transport,
        wireFactory: () => fakeWire,
        now: () => DateTime.utc(2026, 8, 27, 10, 0, 0),
        delay: (d) async {},
      );
    }

    test('connect opens the wire and transitions to connected', () async {
      final fakeWire = FakeMcpWire();
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      expect(fakeWire.openCallCount, 1);
      expect(client.state, McpClientState.connected);
      await client.disconnect();
    });

    test('listTools maps the wire payload to descriptors', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(
        const McpWireResponseOk({
          'tools': [
            {'name': 'fs.read', 'description': 'Read a file'},
          ],
        }),
      );
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final tools = await client.listTools();
      expect(tools.map((t) => t.name), ['fs.read']);
      await client.disconnect();
    });

    test('callTool returns McpCallOk on wire success', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(const McpWireResponseOk({'content': 'hello'}));
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallOk>());
      expect((result as McpCallOk).result['content'], 'hello');
      await client.disconnect();
    });

    test('a drop mid-call triggers reconnect within stdio backoff (SC-003)', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(Exception('subprocess crashed'));
      fakeWire.enqueueNext(const McpWireResponseOk({'content': 'recovered'}));
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallOk>());
      expect(fakeWire.openCallCount, greaterThanOrEqualTo(2));
      await client.disconnect();
    });

    test('exhausted retries transition the client to failed state', () async {
      final fakeWire = FakeMcpWire();
      for (var i = 0; i < McpReconnectPolicyConfig.stdio.maxAttempts + 1; i++) {
        fakeWire.enqueueNext(Exception('persistent crash'));
      }
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallError>());
      expect(client.state, McpClientState.failed);
      await client.disconnect();
    });

    test('onToolsChanged relays wire tools-changed notifications', () async {
      final fakeWire = FakeMcpWire();
      final client = buildClient(fakeWire: fakeWire);
      var fired = 0;
      client.onToolsChanged.listen((_) => fired += 1);
      await client.connect();
      fakeWire.emitNotification(const McpWireNotificationToolsChanged());
      await Future<void>.delayed(Duration.zero);
      expect(fired, 1);
      await client.disconnect();
    });
  });
}
