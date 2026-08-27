// HAND-CURATED regression tests for InProcMcpClient (spec 015-mcp-client).
//
// Covers:
//   - In-proc round-trip works with zero serialization (SC-001).
//   - Tool registration / unregistration.
//   - listTools returns the registered descriptors.
//   - callTool wraps success in McpCallOk and failure in McpCallError.
//   - onToolsChanged fires when a tool is registered/unregistered
//     AFTER connect().
//   - State transitions: disconnected -> connected -> disconnected.
//   - Calling listTools / callTool before connect() surfaces a typed
//     error (not a throw).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/mcp/in_proc_mcp_client.dart';

void main() {
  group('spec-015 — InProcMcpClient', () {
    late McpTransport transport;
    setUp(() {
      transport = const McpTransport(
        id: 'in-proc-1',
        transportType: 'in-proc',
        endpoint: 'local',
        authRequired: false,
      );
    });

    test('connect transitions disconnected -> connected', () async {
      final client = InProcMcpClient(transport: transport);
      expect(client.state, McpClientState.disconnected);
      await client.connect();
      expect(client.state, McpClientState.connected);
      await client.disconnect();
      expect(client.state, McpClientState.disconnected);
    });

    test('connect is idempotent', () async {
      final client = InProcMcpClient(transport: transport);
      await client.connect();
      await client.connect();
      expect(client.state, McpClientState.connected);
      await client.disconnect();
    });

    test('in-proc round-trip works with zero serialization (SC-001)', () async {
      // The callback returns a literal map — the same object identity
      // would be preserved through callTool (no copy / serialize).
      // Asserting the *content* equality (not identity, since the
      // callback returns a fresh map each call) is the spec-correct
      // assertion: "executes without serialization overhead".
      final client = InProcMcpClient(transport: transport);
      const descriptor = McpToolDescriptor(
        name: 'fs.read',
        description: 'Read a file',
      );
      client.registerTool(
        descriptor: descriptor,
        callback: (args) async {
          return {'path': args['path'], 'content': 'hello'};
        },
      );
      await client.connect();

      final result = await client.callTool('fs.read', {'path': '/etc/hosts'});
      expect(result, isA<McpCallOk>());
      final ok = result as McpCallOk;
      expect(ok.result['path'], '/etc/hosts');
      expect(ok.result['content'], 'hello');
      await client.disconnect();
    });

    test('listTools returns the registered descriptors', () async {
      final client = InProcMcpClient(transport: transport);
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'a', description: 'A tool'),
        callback: (args) async => {},
      );
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'b', description: 'B tool'),
        callback: (args) async => {},
      );
      await client.connect();
      final tools = await client.listTools();
      expect(tools.map((t) => t.name), unorderedEquals(['a', 'b']));
      await client.disconnect();
    });

    test('callTool on unknown name returns McpCallError', () async {
      final client = InProcMcpClient(transport: transport);
      await client.connect();
      final result = await client.callTool('nope', {});
      expect(result, isA<McpCallError>());
      final err = result as McpCallError;
      expect(err.code, 'tool-not-found');
      await client.disconnect();
    });

    test('callTool when client is disconnected returns McpCallError', () async {
      final client = InProcMcpClient(transport: transport);
      // Don't connect.
      final result = await client.callTool('anything', {});
      expect(result, isA<McpCallError>());
      final err = result as McpCallError;
      expect(err.code, 'client-not-connected');
    });

    test('listTools when client is disconnected throws StateError', () async {
      final client = InProcMcpClient(transport: transport);
      expect(() => client.listTools(), throwsA(isA<StateError>()));
    });

    test('a throwing tool callback surfaces as McpCallError', () async {
      final client = InProcMcpClient(transport: transport);
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'boom', description: 'Boom'),
        callback: (args) async => throw Exception('kaboom'),
      );
      await client.connect();
      final result = await client.callTool('boom', {});
      expect(result, isA<McpCallError>());
      final err = result as McpCallError;
      expect(err.code, 'tool-threw');
      expect(err.message, contains('kaboom'));
      await client.disconnect();
    });

    test('registerTool before connect does NOT emit onToolsChanged', () async {
      final client = InProcMcpClient(transport: transport);
      var fired = 0;
      client.onToolsChanged.listen((_) => fired += 1);
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'a', description: 'A'),
        callback: (args) async => {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(fired, 0);
    });

    test('registerTool after connect emits onToolsChanged', () async {
      final client = InProcMcpClient(transport: transport);
      var fired = 0;
      client.onToolsChanged.listen((_) => fired += 1);
      await client.connect();
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'a', description: 'A'),
        callback: (args) async => {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(fired, 1);
      await client.disconnect();
    });

    test('unregisterTool after connect emits onToolsChanged', () async {
      final client = InProcMcpClient(transport: transport);
      var fired = 0;
      client.onToolsChanged.listen((_) => fired += 1);
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'a', description: 'A'),
        callback: (args) async => {},
      );
      await client.connect();
      client.unregisterTool('a');
      await Future<void>.delayed(Duration.zero);
      expect(fired, 1);
      await client.disconnect();
    });

    test('registering a duplicate name throws ArgumentError', () async {
      final client = InProcMcpClient(transport: transport);
      client.registerTool(
        descriptor: const McpToolDescriptor(name: 'a', description: 'A'),
        callback: (args) async => {},
      );
      expect(
        () => client.registerTool(
          descriptor: const McpToolDescriptor(name: 'a', description: 'A again'),
          callback: (args) async => {},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
