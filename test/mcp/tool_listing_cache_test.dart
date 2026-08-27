// HAND-CURATED regression tests for ToolListingCache (spec 015-mcp-client).
//
// Covers:
//   - First call hits the underlying client.
//   - Second call within TTL returns the cached value (no second listTools).
//   - After TTL expiry, the next call re-lists.
//   - Explicit invalidate() forces the next call to re-list.
//   - onToolsChanged from the client invalidates the cache.
//   - dispose() cancels the onToolsChanged subscription.

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/mcp/tool_listing_cache.dart';

/// Minimal McpClient fake that records listTools calls and lets tests
/// push onToolsChanged notifications.
class _CountingClient implements McpClient {
  @override
  final McpTransport transport;
  int listToolsCallCount = 0;
  List<McpToolDescriptor> nextTools = const [];
  final StreamController<void> _toolsChangedController =
      StreamController<void>.broadcast();

  _CountingClient(this.transport);

  void fireToolsChanged() => _toolsChangedController.add(null);

  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<McpToolDescriptor>> listTools() async {
    listToolsCallCount += 1;
    return nextTools;
  }

  @override
  Future<McpCallResult> callTool(String name, Map<String, dynamic> args) async =>
      const McpCallError(code: 'not-implemented', message: 'stub');

  @override
  Stream<void> get onToolsChanged => _toolsChangedController.stream;

  @override
  McpClientState get state => McpClientState.connected;
}

void main() {
  group('spec-015 — ToolListingCache', () {
    late McpTransport transport;
    setUp(() {
      transport = const McpTransport(
        id: 'in-proc-1',
        transportType: 'in-proc',
        endpoint: 'local',
        authRequired: false,
      );
    });

    test('first call hits the underlying client', () async {
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      final tools = await cache.getOrRefresh();
      expect(tools.map((t) => t.name), ['a']);
      expect(client.listToolsCallCount, 1);
      await cache.dispose();
    });

    test('second call within TTL returns the cached value (no second listTools)', () async {
      var now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      await cache.getOrRefresh();
      // Advance time by 30s (still within TTL).
      now = now.add(const Duration(seconds: 30));
      final tools = await cache.getOrRefresh();
      expect(tools.map((t) => t.name), ['a']);
      expect(client.listToolsCallCount, 1); // still 1, no re-list
      expect(cache.hasFreshEntry, isTrue);
      await cache.dispose();
    });

    test('after TTL expiry, the next call re-lists', () async {
      var now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 1);
      // Advance time past TTL.
      now = now.add(const Duration(seconds: 61));
      expect(cache.hasFreshEntry, isFalse);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
        McpToolDescriptor(name: 'b', description: 'B'),
      ];
      final tools = await cache.getOrRefresh();
      expect(tools.map((t) => t.name), ['a', 'b']);
      expect(client.listToolsCallCount, 2);
      await cache.dispose();
    });

    test('explicit invalidate() forces the next call to re-list', () async {
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 1);
      cache.invalidate();
      expect(cache.hasFreshEntry, isFalse);
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 2);
      await cache.dispose();
    });

    test('onToolsChanged from the client invalidates the cache', () async {
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 1);
      // Server reports tools-changed — cache should be invalidated.
      client.fireToolsChanged();
      // Give the stream subscription a tick to fire.
      await Future<void>.delayed(Duration.zero);
      expect(cache.hasFreshEntry, isFalse);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
        McpToolDescriptor(name: 'b', description: 'B'),
      ];
      final tools = await cache.getOrRefresh();
      expect(tools.map((t) => t.name), ['a', 'b']);
      expect(client.listToolsCallCount, 2);
      await cache.dispose();
    });

    test('dispose() cancels the onToolsChanged subscription', () async {
      final now = DateTime.utc(2026, 8, 27, 10, 0, 0);
      final client = _CountingClient(transport);
      client.nextTools = const [
        McpToolDescriptor(name: 'a', description: 'A'),
      ];
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );
      await cache.getOrRefresh();
      await cache.dispose();
      // After dispose, firing tools-changed should not throw / leak.
      client.fireToolsChanged();
      await Future<void>.delayed(Duration.zero);
      // No assertion — just verify no exception propagates.
    });
  });
}
