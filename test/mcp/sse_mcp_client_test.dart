// HAND-CURATED regression tests for SseMcpClient (spec 015-mcp-client).
//
// Uses a fake McpWire (no real network — constitution: fixtures only).
// Covers:
//   - connect() opens the wire; state -> connected.
//   - listTools() maps the wire's payload to descriptors.
//   - callTool() maps the wire's response to McpCallOk / McpCallError.
//   - A drop mid-call triggers reconnect within the SSE backoff (SC-002).
//   - Auth callback is invoked on each reconnect (token rotation, FR-003).
//   - disconnect() closes the wire and transitions to disconnected.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_reconnect_policy.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/sse_mcp_client.dart';

import '_fake_wire.dart';

void main() {
  group('spec-015 — SseMcpClient', () {
    late McpTransport transport;
    setUp(() {
      transport = const McpTransport(
        id: 'sse-1',
        transportType: 'sse',
        endpoint: 'https://example.invalid/sse',
        authRequired: true,
      );
    });

    SseMcpClient buildClient({
      required FakeMcpWire fakeWire,
      McpAuthTokenCallback? authCallback,
    }) {
      return SseMcpClient(
        transport: transport,
        wireFactory: (token) => fakeWire,
        authTokenCallback: authCallback,
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

    test('connect invokes the auth callback to fetch the bearer token', () async {
      final fakeWire = FakeMcpWire();
      var authCallCount = 0;
      final client = buildClient(
        fakeWire: fakeWire,
        authCallback: () async {
          authCallCount += 1;
          return 'bearer-token-$authCallCount';
        },
      );
      await client.connect();
      expect(authCallCount, 1);
      await client.disconnect();
    });

    test('listTools maps the wire payload to descriptors', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(
        const McpWireResponseOk({
          'tools': [
            {'name': 'fs.read', 'description': 'Read a file'},
            {
              'name': 'fs.write',
              'description': 'Write a file',
              'paramsSchema': {'type': 'object'},
            },
          ],
        }),
      );
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final tools = await client.listTools();
      expect(tools.map((t) => t.name), ['fs.read', 'fs.write']);
      expect(tools[1].paramsSchema, isNotNull);
      await client.disconnect();
    });

    test('callTool returns McpCallOk on wire success', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(
        const McpWireResponseOk({'content': 'hello'}),
      );
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {'path': '/etc/hosts'});
      expect(result, isA<McpCallOk>());
      final ok = result as McpCallOk;
      expect(ok.result['content'], 'hello');
      await client.disconnect();
    });

    test('callTool returns McpCallError on wire error', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(
        const McpWireResponseError(code: 'invalid-params', message: 'bad args'),
      );
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallError>());
      final err = result as McpCallError;
      expect(err.code, 'invalid-params');
      expect(err.message, 'bad args');
      await client.disconnect();
    });

    test('a drop mid-call triggers reconnect within SSE backoff (SC-002)', () async {
      final fakeWire = FakeMcpWire();
      // First send throws (transport drop); reconnect opens the wire
      // again; second send succeeds.
      fakeWire.enqueueNext(Exception('transport drop'));
      fakeWire.enqueueNext(
        const McpWireResponseOk({'content': 'recovered'}),
      );
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallOk>());
      final ok = result as McpCallOk;
      expect(ok.result['content'], 'recovered');
      // Reconnect happened — wire.open called at least twice.
      expect(fakeWire.openCallCount, greaterThanOrEqualTo(2));
      await client.disconnect();
    });

    test('auth callback is invoked on reconnect (FR-003 token rotation)', () async {
      final fakeWire = FakeMcpWire();
      fakeWire.enqueueNext(Exception('transport drop'));
      fakeWire.enqueueNext(const McpWireResponseOk({}));
      var authCallCount = 0;
      final client = buildClient(
        fakeWire: fakeWire,
        authCallback: () async {
          authCallCount += 1;
          return 'token-$authCallCount';
        },
      );
      await client.connect();
      expect(authCallCount, 1);
      await client.callTool('fs.read', {});
      expect(authCallCount, 2); // auth callback called again on reconnect
      await client.disconnect();
    });

    test('exhausted retries transition the client to failed state', () async {
      final fakeWire = FakeMcpWire();
      // Always throw — exhausts the policy.
      for (var i = 0; i < McpReconnectPolicyConfig.sse.maxAttempts + 1; i++) {
        fakeWire.enqueueNext(Exception('persistent drop'));
      }
      final client = buildClient(fakeWire: fakeWire);
      await client.connect();
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallError>());
      final err = result as McpCallError;
      expect(err.code, 'transport-error');
      expect(client.state, McpClientState.failed);
      await client.disconnect();
    });

    test('callTool when disconnected returns McpCallError', () async {
      final fakeWire = FakeMcpWire();
      final client = buildClient(fakeWire: fakeWire);
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallError>());
      expect((result as McpCallError).code, 'client-not-connected');
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
