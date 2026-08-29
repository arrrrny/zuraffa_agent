// Spec 082 — R3 MCP transport resilience (issue #93, parent epic #4).
//
// RED surface (new behavior):
//   T1  SSE drop mid-call → recovery → `onReconnected` fires exactly once
//       (never on the initial connect, never on a plain successful call).
//   T2  stdio: same recovery-emission contract.
//   T3  `ToolListingCache` re-lists after `onReconnected` despite a TTL-fresh
//       entry (fake-client level).
//   T4  End-to-end: real `SseMcpClient` + `ToolListingCache` — drop +
//       recovery → the cache re-lists (SC-002).
//   T8  `InProcMcpClient.onReconnected` never emits (no transport to drop).
//
// Pins (existing behavior, previously unguarded — justified by mutants):
//   T5  Jitter never pushes an applied backoff delay past `config.cap`
//       (seed 0 draws jitterScale > 1.0 on every capped attempt, so removing
//       the clamp is observable).
//   T6  Storm terminality: an always-dropping wire yields exactly
//       `maxAttempts` delays, a `failed` client, and NO further delays after
//       failure (no zombie reconnect loop).
//   T7  TTL boundary: an entry aged exactly `maxAge` is stale (freshness is
//       `age < maxAge`).

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/in_proc_mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_reconnect_policy.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/sse_mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/stdio_mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/tool_listing_cache.dart';

import '_fake_wire.dart';

class TransportDropped implements Exception {
  const TransportDropped();
  @override
  String toString() => 'TransportDropped';
}

/// Minimal McpClient fake whose `onReconnected` is fireable on demand and
/// whose `listTools` counts calls.
class _ReconnectableClient implements McpClient {
  @override
  final McpTransport transport;
  int listToolsCallCount = 0;
  List<McpToolDescriptor> nextTools = const [];
  final StreamController<void> _reconnectedController =
      StreamController<void>.broadcast();

  _ReconnectableClient(this.transport);

  void fireReconnected() => _reconnectedController.add(null);

  @override
  Stream<void> get onReconnected => _reconnectedController.stream;

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
  Stream<void> get onToolsChanged => const Stream.empty();

  @override
  McpClientState get state => McpClientState.connected;
}

const _sseTransport = McpTransport(
  id: 'sse-082',
  transportType: 'sse',
  endpoint: 'https://example.invalid/sse',
  authRequired: false,
);

const _stdioTransport = McpTransport(
  id: 'stdio-082',
  transportType: 'stdio',
  endpoint: 'local',
  authRequired: false,
);

const _inProcTransport = McpTransport(
  id: 'in-proc-082',
  transportType: 'in-proc',
  endpoint: 'local',
  authRequired: false,
);

DateTime _t0() => DateTime.utc(2026, 8, 29);

Map<String, dynamic> _listingPayload() => {
      'tools': [
        {'name': 'fs.read', 'description': 'Read a file'},
      ],
    };

void main() {
  group('spec 082 — recovery emission (FR-004)', () {
    test('T1: SSE drop mid-call → recovery → onReconnected fires exactly once',
        () async {
      final wire = FakeMcpWire();
      final delays = <Duration>[];
      final client = SseMcpClient(
        transport: _sseTransport,
        wireFactory: (_) => wire,
        now: _t0,
        delay: (d) async => delays.add(d),
      );
      var events = 0;
      client.onReconnected.listen((_) => events++);

      await client.connect();
      await Future<void>.delayed(Duration.zero);
      expect(events, 0,
          reason: 'the initial connect must not fire onReconnected');

      wire.enqueueNext(const TransportDropped());
      wire.enqueueNext(const McpWireResponseOk({'content': 'ok'}));
      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallOk>());
      await Future<void>.delayed(Duration.zero);
      expect(events, 1, reason: 'exactly one event for one recovery');
      expect(delays.length, 1, reason: 'one backoff delay for one recovery');

      // A plain successful call with no drop must not fire again.
      wire.enqueueNext(const McpWireResponseOk({'content': 'again'}));
      await client.callTool('fs.read', {});
      await Future<void>.delayed(Duration.zero);
      expect(events, 1,
          reason: 'a successful call without a drop is not a recovery');
    });

    test('T2: stdio drop mid-call → recovery → onReconnected fires once',
        () async {
      final wire = FakeMcpWire();
      final client = StdioMcpClient(
        transport: _stdioTransport,
        wireFactory: () => wire,
        now: _t0,
        delay: (d) async {},
      );
      var events = 0;
      client.onReconnected.listen((_) => events++);

      await client.connect();
      await Future<void>.delayed(Duration.zero);
      expect(events, 0);

      wire.enqueueNext(const TransportDropped());
      wire.enqueueNext(const McpWireResponseOk({'content': 'ok'}));
      final result = await client.callTool('shell.run', {});
      expect(result, isA<McpCallOk>());
      await Future<void>.delayed(Duration.zero);
      expect(events, 1);
    });
  });

  group('spec 082 — cache invalidation on reconnect (FR-005)', () {
    test('T3: onReconnected invalidates a TTL-fresh cache entry', () async {
      final client = _ReconnectableClient(_inProcTransport);
      client.nextTools = const [
        McpToolDescriptor(name: 'fs.read', description: 'Read a file'),
      ];
      var now = _t0();
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );

      await cache.getOrRefresh();
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 1,
          reason: 'TTL-fresh entry is served without re-listing');

      // Still far inside the TTL when the transport recovers.
      now = now.add(const Duration(seconds: 1));
      client.fireReconnected();
      await Future<void>.delayed(Duration.zero);

      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 2,
          reason: 'a recovery invalidates the cache despite fresh TTL');
      await cache.dispose();
    });

    test('T4: end-to-end — drop + recovery → the cache re-lists (SC-002)',
        () async {
      final wire = FakeMcpWire();
      final client = SseMcpClient(
        transport: _sseTransport,
        wireFactory: (_) => wire,
        now: _t0,
        delay: (d) async {},
      );
      await client.connect();

      var now = _t0();
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );

      // Prime the cache (ListTools send #1).
      wire.enqueueNext(McpWireResponseOk(_listingPayload()));
      await cache.getOrRefresh();

      // A drop mid-call, then a successful retry (CallTool sends), then the
      // post-recovery re-list (ListTools send #2).
      wire.enqueueNext(const TransportDropped());
      wire.enqueueNext(const McpWireResponseOk({'content': 'ok'}));
      wire.enqueueNext(McpWireResponseOk(_listingPayload()));

      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallOk>());

      now = now.add(const Duration(seconds: 1)); // deep inside the TTL
      await cache.getOrRefresh();

      final listCalls =
          wire.sentRequests.whereType<McpWireRequestListTools>().length;
      expect(listCalls, 2,
          reason: 'the recovery must invalidate the cache and force a '
              're-list even though the TTL had not expired');
    });
  });

  group('spec 082 — in-proc signal is silent (FR-004)', () {
    test('T8: InProcMcpClient.onReconnected never emits', () async {
      final client = InProcMcpClient(transport: _inProcTransport);
      var events = 0;
      client.onReconnected.listen((_) => events++);
      await client.connect();
      await Future<void>.delayed(Duration.zero);
      expect(events, 0);
    });
  });

  group('spec 082 — pins over existing resilience behavior', () {
    test('T5: jittered backoff never exceeds the cap (FR-002)', () async {
      final delays = <Duration>[];
      final policy = McpReconnectPolicy(
        config: const McpReconnectPolicyConfig(
          initial: Duration(milliseconds: 100),
          factor: 2.0,
          cap: Duration(seconds: 1),
          maxAttempts: 8,
          jitter: 0.5,
        ),
        delay: (d) async => delays.add(d),
        // Seed 0 draws nextDouble() > 0.5 on every capped attempt (5..8),
        // i.e. jitterScale > 1.0 — an unclamped policy would exceed the cap.
        seed: 0,
      );
      while (!policy.exhausted) {
        await policy.nextBackoff();
      }
      expect(delays.length, 8);
      for (final d in delays) {
        expect(d.inMilliseconds, lessThanOrEqualTo(1000),
            reason:
                '${d.inMilliseconds}ms exceeds the cap — jitter must be clamped');
      }
    });

    test('T6: storm terminality — bounded delays, failed state, frozen '
        'counter (FR-003)', () async {
      final wire = FakeMcpWire(); // never enqueued → every send throws
      final delays = <Duration>[];
      final client = SseMcpClient(
        transport: _sseTransport,
        wireFactory: (_) => wire,
        now: _t0,
        delay: (d) async => delays.add(d),
      );
      await client.connect();

      final result = await client.callTool('fs.read', {});
      expect(result, isA<McpCallError>());
      expect((result as McpCallError).code, 'transport-error');
      expect(client.state, McpClientState.failed);
      expect(delays.length, McpReconnectPolicyConfig.sse.maxAttempts,
          reason: 'exactly maxAttempts backoff delays per failure episode');

      // No zombie reconnects after the terminal failure.
      final result2 = await client.callTool('fs.read', {});
      expect((result2 as McpCallError).code, 'client-not-connected');
      expect(delays.length, McpReconnectPolicyConfig.sse.maxAttempts,
          reason: 'a post-failure call must not schedule further delays');
    });

    test('T7: TTL boundary — an entry aged exactly maxAge is stale (FR-006)',
        () async {
      final client = _ReconnectableClient(_inProcTransport);
      client.nextTools = const [
        McpToolDescriptor(name: 'fs.read', description: 'Read a file'),
      ];
      var now = _t0();
      final cache = ToolListingCache(
        client: client,
        maxAge: const Duration(seconds: 60),
        now: () => now,
      );

      await cache.getOrRefresh();
      now = now.add(const Duration(seconds: 60)); // exactly maxAge
      await cache.getOrRefresh();
      expect(client.listToolsCallCount, 2,
          reason: 'freshness is age < maxAge — age == maxAge is stale');
      await cache.dispose();
    });
  });
}
