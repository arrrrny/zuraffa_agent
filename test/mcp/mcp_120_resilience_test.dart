// spec 108 (issue #120) — client-level resilience: call timeout, per-server
// breaker wiring, and read-only transient retry, through the real clients
// with a scripted fake wire (hermetic; house pattern from spec 015/082).

import 'dart:async';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mcp_transport/mcp_transport.dart';
import 'package:zuraffa_agent/src/mcp/in_proc_mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_guard.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';
import 'package:zuraffa_agent/src/mcp/mcp_client.dart';
import 'package:zuraffa_agent/src/mcp/mcp_tool_descriptor.dart';
import 'package:zuraffa_agent/src/mcp/mcp_wire.dart';
import 'package:zuraffa_agent/src/mcp/sse_mcp_client.dart';

/// A wire that never answers — for the timeout behavior.
class HungMcpWire implements McpWire {
  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}

  @override
  bool get isOpen => true;

  @override
  Future<McpWireResponse> send(McpWireRequest request) =>
      Completer<McpWireResponse>().future; // hangs forever

  @override
  Stream<McpWireNotification> get notifications => const Stream.empty();
}

/// A wire failing `failTimes` sends with a transient code, then succeeding.
class FlakyMcpWire implements McpWire {
  FlakyMcpWire({this.failTimes = 0, this.code = 'server-error'});

  int failTimes;
  final String code;
  int sends = 0;

  @override
  Future<void> open() async {}

  @override
  Future<void> close() async {}

  @override
  bool get isOpen => true;

  @override
  Future<McpWireResponse> send(McpWireRequest request) async {
    sends += 1;
    if (sends <= failTimes) {
      return McpWireResponseError(code: code, message: 'transient trouble');
    }
    return McpWireResponseOk(const {'tools': <Map<String, dynamic>>[]});
  }

  @override
  Stream<McpWireNotification> get notifications => const Stream.empty();
}

McpTransport _transport(String id) => McpTransport(
  id: id,
  transportType: 'sse',
  endpoint: 'https://mcp.example.internal/sse',
  authRequired: false,
);

McpCallOptions readOnlyRetry({int maxAttempts = 3}) => McpCallOptions(
  readOnly: true,
  retry: McpRetryConfig(maxAttempts: maxAttempts, backoff: Duration.zero),
);

void main() {
  group('spec 108 — callTool timeout (issue #120)', () {
    test('U6: a hung wire returns the typed timeout error', () async {
      final client = SseMcpClient(
        transport: _transport('t1'),
        wireFactory: (_) => HungMcpWire(),
        now: () => DateTime.utc(2026, 1, 1),
        delay: (d) => Future<void>.value(),
      );
      await client.connect();
      final sw = Stopwatch()..start();
      final result = await client.callTool(
        'slow.tool',
        const {},
        options: const McpCallOptions(timeout: Duration(milliseconds: 80)),
      );
      sw.stop();
      expect(result, isA<McpCallError>());
      expect((result as McpCallError).code, 'timeout');
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('U7: the default timeout is 30 seconds', () {
      expect(McpCallOptions.defaultTimeout, const Duration(seconds: 30));
      expect(
        const McpCallOptions().effectiveTimeout,
        const Duration(seconds: 30),
      );
    });
  });

  group('spec 108 — read-only transient retry (issue #120)', () {
    test('U8: a read-only transient failure is retried to success', () async {
      final wire = FlakyMcpWire(failTimes: 2);
      final client = SseMcpClient(
        transport: _transport('t2'),
        wireFactory: (_) => wire,
        now: () => DateTime.utc(2026, 1, 1),
        delay: (d) => Future<void>.value(),
      );
      await client.connect();
      final result = await client.callTool(
        'ro.tool',
        const {},
        options: readOnlyRetry(maxAttempts: 3),
      );
      expect(result, isA<McpCallOk>());
      expect(wire.sends, 3); // two transient failures + one success
    });

    test('U9: a non-read-only call is never retried', () async {
      final wire = FlakyMcpWire(failTimes: 1);
      final client = SseMcpClient(
        transport: _transport('t3'),
        wireFactory: (_) => wire,
        now: () => DateTime.utc(2026, 1, 1),
        delay: (d) => Future<void>.value(),
      );
      await client.connect();
      final result = await client.callTool(
        'mutating.tool',
        const {},
        options: const McpCallOptions(
          readOnly: false,
          retry: McpRetryConfig(maxAttempts: 3, backoff: Duration.zero),
        ),
      );
      expect(result, isA<McpCallError>());
      expect(wire.sends, 1);
    });

    test('U10: a timeout result is never retried', () async {
      var hungSeen = false;
      final client = SseMcpClient(
        transport: _transport('t4'),
        wireFactory: (_) {
          if (hungSeen) {
            throw StateError('must not re-invoke the wire after a timeout');
          }
          hungSeen = true;
          return HungMcpWire();
        },
        now: () => DateTime.utc(2026, 1, 1),
        delay: (d) => Future<void>.value(),
      );
      await client.connect();
      final result = await client.callTool(
        'ro.hang',
        const {},
        options: McpCallOptions(
          timeout: const Duration(milliseconds: 50),
          readOnly: true,
          retry: const McpRetryConfig(maxAttempts: 3, backoff: Duration.zero),
        ),
      );
      expect((result as McpCallError).code, 'timeout');
    });

    test('U11: an application-level error is never retried', () async {
      final wire = FlakyMcpWire(failTimes: 1, code: 'invalid-params');
      final client = SseMcpClient(
        transport: _transport('t5'),
        wireFactory: (_) => wire,
        now: () => DateTime.utc(2026, 1, 1),
        delay: (d) => Future<void>.value(),
      );
      await client.connect();
      await client.callTool(
        'ro.app',
        const {},
        options: readOnlyRetry(maxAttempts: 3),
      );
      expect(wire.sends, 1, reason: 'app errors are final answers');
    });
  });

  group('spec 108 — per-server breaker through the client (issue #120)', () {
    test('U-breaker: threshold failures open the breaker; open calls fail fast '
        'without touching the wire; cooldown probe recovers', () async {
      var now = DateTime.utc(2026, 1, 1);
      final wire = FlakyMcpWire(
        failTimes: 99,
        code: 'server-error',
      ); // always fails at the app level
      final client = SseMcpClient(
        transport: _transport('t6'),
        wireFactory: (_) => wire,
        now: () => now,
        delay: (d) => Future<void>.value(),
        breakerConfig: const McpBreakerConfig(
          failureThreshold: 3,
          cooldown: Duration(seconds: 30),
        ),
      );
      await client.connect();

      for (var i = 0; i < 3; i++) {
        final result = await client.callTool('failing.tool', const {});
        expect(result, isA<McpCallError>());
      }
      expect(wire.sends, 3);
      final fast = await client.callTool('failing.tool', const {});
      expect((fast as McpCallError).code, 'circuit-open');
      expect(wire.sends, 3, reason: 'fail fast — the wire is untouched');

      // Cooldown elapses → the next call probes; the wire still fails →
      // re-opened.
      now = now.add(const Duration(seconds: 31));
      final probe = await client.callTool('failing.tool', const {});
      expect((probe as McpCallError).code, 'server-error');
      expect(wire.sends, 4);
      final fastAgain = await client.callTool('failing.tool', const {});
      expect((fastAgain as McpCallError).code, 'circuit-open');
    });

    test(
      'U-breaker-reset: a success in closed state resets the failure count',
      () async {
        final wire = FlakyMcpWire(failTimes: 2);
        final client = SseMcpClient(
          transport: _transport('t7'),
          wireFactory: (_) => wire,
          now: () => DateTime.utc(2026, 1, 1),
          delay: (d) => Future<void>.value(),
          breakerConfig: const McpBreakerConfig(
            failureThreshold: 3,
            cooldown: Duration(seconds: 30),
          ),
        );
        await client.connect();
        for (var i = 0; i < 2; i++) {
          await client.callTool('flaky.tool', const {});
        }
        // Third call succeeds (wire stops failing) → streak reset → the
        // breaker never opens: subsequent calls still reach the wire.
        await client.callTool('flaky.tool', const {});
        expect(wire.sends, 3);
        await client.callTool('flaky.tool', const {});
        expect(wire.sends, 4, reason: 'breaker never opened');
      },
    );
  });

  group('spec 108 — descriptor readOnly flag (issue #120)', () {
    test('U12: readOnly defaults to false and round-trips', () {
      const plain = McpToolDescriptor(name: 'a', description: 'b');
      expect(plain.readOnly, isFalse);
      const ro = McpToolDescriptor(name: 'a', description: 'b', readOnly: true);
      expect(ro.readOnly, isTrue);
      expect(
        McpToolDescriptor(name: 'a', description: 'b', readOnly: true),
        McpToolDescriptor(name: 'a', description: 'b', readOnly: true),
      );
    });
  });

  group('spec 108 — InProc pass-through (issue #120)', () {
    test(
      'InProcMcpClient.callTool accepts options with unchanged behavior',
      () async {
        final client = InProcMcpClient(transport: _transport('in-proc-opt'));
        client.registerTool(
          descriptor: const McpToolDescriptor(
            name: 'echo',
            description: 'echo',
            readOnly: true,
          ),
          callback: (args) async => {'echo': args},
        );
        await client.connect();
        final result = await client.callTool('echo', {
          'x': 1,
        }, options: readOnlyRetry());
        expect((result as McpCallOk).result['echo'], {'x': 1});
      },
    );
  });
}
