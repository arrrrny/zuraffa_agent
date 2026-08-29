// HAND-CURATED regression tests for McpToolAdapter (spec 015-mcp-client).
//
// Covers:
//   - sync() lists tools via the cache and registers each into the registry.
//   - Names use the `mcp:<serverId>:<toolName>` convention.
//   - A subsequent sync() with new tools registers new ones and unregisters gone ones.
//   - startAutoSync() reacts to onToolsChanged: invalidates cache and re-syncs.
//   - dispose() stops the auto-sync.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_adapter.dart';

class _FakeMcpClient implements McpClient {
  @override
  final McpTransport transport;
  List<McpToolDescriptor> nextTools = const [];
  final StreamController<void> _toolsChangedController =
      StreamController<void>.broadcast();

  _FakeMcpClient(this.transport);

  void fireToolsChanged() => _toolsChangedController.add(null);

  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<McpToolDescriptor>> listTools() async => nextTools;
  @override
  Future<McpCallResult> callTool(String n, Map<String, dynamic> a) async =>
      const McpCallError(code: 'not-implemented', message: 'stub');
  @override
  Stream<void> get onToolsChanged => _toolsChangedController.stream;

  // Spec 082: the cache now subscribes to onReconnected — this fake never
  // recovers (no transport), so the signal never fires.
  @override
  Stream<void> get onReconnected => const Stream.empty();
  @override
  McpClientState get state => McpClientState.connected;
}

class _FakeToolRegistry implements ToolRegistry {
  final Map<String, AgentTool> _tools = {};
  final StreamController<NamespaceCollisionEvent> _collisionController =
      StreamController<NamespaceCollisionEvent>.broadcast();

  @override
  Future<void> registerDdaTool(AgentTool tool) async {
    _tools[tool.id] = tool;
  }

  @override
  Future<void> registerGeneratedTool(AgentTool tool) async {
    _tools['gen:${tool.id}'] = tool;
  }

  @override
  Future<void> registerMcpTool(AgentTool tool, String serverId) async {
    _tools[tool.id] = tool;
  }

  @override
  Future<void> unregister(String qualifiedName) async {
    _tools.remove(qualifiedName);
  }

  @override
  Future<AgentTool?> resolve(String qualifiedName) async => _tools[qualifiedName];

  @override
  Future<List<AgentTool>> list() async => _tools.values.toList();

  @override
  Stream<NamespaceCollisionEvent> get onCollision => _collisionController.stream;

  Future<void> dispose() async {
    await _collisionController.close();
  }
}

void main() {
  group('spec-015 — McpToolAdapter', () {
    late McpTransport transport;
    setUp(() {
      transport = const McpTransport(
        id: 'in-proc-1',
        transportType: 'in-proc',
        endpoint: 'local',
        authRequired: false,
      );
    });

    test('sync() lists tools via the cache and registers each into the registry', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'fs.read', description: 'Read a file'),
        McpToolDescriptor(name: 'fs.write', description: 'Write a file'),
      ];
      final registry = _FakeToolRegistry();
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'raptorr',
        now: () => now,
      );
      await adapter.sync();
      final tools = await registry.list();
      expect(tools.map((t) => t.id), unorderedEquals([
        'mcp:raptorr:fs.read',
        'mcp:raptorr:fs.write',
      ]));
      await adapter.dispose();
    });

    test('names use the mcp:<serverId>:<toolName> convention', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final registry = _FakeToolRegistry();
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'srv-42',
        now: () => now,
      );
      await adapter.sync();
      final tool = await registry.resolve('mcp:srv-42:a');
      expect(tool, isNotNull);
      expect(tool!.description, 'A');
      await adapter.dispose();
    });

    test('a subsequent sync() with new tools registers new and unregisters gone', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
        McpToolDescriptor(name: 'b', description: 'B'),
      ];
      final registry = _FakeToolRegistry();
      var now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'srv',
        now: () => now,
      );
      await adapter.sync();
      expect((await registry.list()).map((t) => t.id), unorderedEquals([
        'mcp:srv:a', 'mcp:srv:b',
      ]));
      // Force cache invalidation (advance past TTL).
      now = now.add(const Duration(seconds: 61));
      // 'b' is gone, 'c' is new.
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
        McpToolDescriptor(name: 'c', description: 'C'),
      ];
      await adapter.sync();
      final tools = (await registry.list()).map((t) => t.id).toList();
      expect(tools, unorderedEquals(['mcp:srv:a', 'mcp:srv:c']));
      expect(tools, isNot(contains('mcp:srv:b')));
      await adapter.dispose();
    });

    test('startAutoSync() reacts to onToolsChanged: invalidates cache and re-syncs', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final registry = _FakeToolRegistry();
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'srv',
        now: () => now,
      );
      await adapter.sync();
      await adapter.startAutoSync();
      // Within TTL — but onToolsChanged invalidates the cache, so the
      // next sync should re-list even without time advance.
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
        McpToolDescriptor(name: 'b', description: 'B'),
      ];
      client.fireToolsChanged();
      // Give the auto-sync a couple of event-loop ticks.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final tools = (await registry.list()).map((t) => t.id).toList();
      expect(tools, containsAll(['mcp:srv:a', 'mcp:srv:b']));
      await adapter.dispose();
    });

    test('dispose() stops the auto-sync', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final registry = _FakeToolRegistry();
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'srv',
        now: () => now,
      );
      await adapter.sync();
      await adapter.startAutoSync();
      await adapter.dispose();
      // After dispose, firing onToolsChanged should not propagate to
      // any registry mutation (the auto-sync subscription is cancelled).
      // We assert no exception — the subscription cancellation is the
      // observable invariant.
      client.fireToolsChanged();
      await Future<void>.delayed(Duration.zero);
    });

    test('sync() after dispose throws StateError', () async {
      final client = _FakeMcpClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final registry = _FakeToolRegistry();
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final adapter = McpToolAdapter(
        client: client,
        registry: registry,
        serverId: 'srv',
        now: () => now,
      );
      await adapter.dispose();
      expect(() => adapter.sync(), throwsA(isA<StateError>()));
    });
  });
}
