// spec 108 (issue #120) — McpCallGuard: per-server breaker over the
// immutable CircuitBreaker (spec 035), with an injectable clock.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/config/zuraffa_config.dart';
import 'package:zuraffa_agent/src/domain/entities/circuit_breaker/circuit_breaker.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_guard.dart';
import 'package:zuraffa_agent/src/mcp/mcp_call_result.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  var now = t0;
  DateTime clock() => now;

  McpCallGuard guard({
    int failureThreshold = 3,
    Duration cooldown = const Duration(seconds: 30),
  }) {
    now = t0;
    return McpCallGuard(
      config: McpBreakerConfig(
        failureThreshold: failureThreshold,
        cooldown: cooldown,
      ),
      now: clock,
    );
  }

  Future<McpCallResult> ok() async => const McpCallOk({'ok': true});
  Future<McpCallResult> err(String code) async =>
      McpCallError(code: code, message: 'boom:$code');

  group('spec 108 — McpCallGuard (issue #120)', () {
    test('U1: N consecutive call errors open the guard', () async {
      final g = guard(failureThreshold: 3);
      await g.call(() => err('server-error'));
      await g.call(() => err('server-error'));
      expect(g.isOpen, isFalse, reason: 'below threshold');
      await g.call(() => err('server-error'));
      expect(g.isOpen, isTrue);
    });

    test('U2: a success in closed state resets the failure count', () async {
      final g = guard(failureThreshold: 3);
      await g.call(() => err('server-error'));
      await g.call(() => err('server-error'));
      await g.call(ok);
      await g.call(() => err('server-error'));
      await g.call(() => err('server-error'));
      expect(g.isOpen, isFalse, reason: 'streak broken by the success');
      await g.call(() => err('server-error'));
      expect(g.isOpen, isTrue);
    });

    test('U3: open guard fails fast typed WITHOUT invoking the wire', () async {
      final g = guard(failureThreshold: 1);
      var wireTouched = false;
      await g.call(() => err('server-error'));
      expect(g.isOpen, isTrue);

      final result = await g.call(() async {
        wireTouched = true;
        return ok();
      });
      expect(result, isA<McpCallError>());
      expect((result as McpCallError).code, 'circuit-open');
      expect(wireTouched, isFalse, reason: 'fail fast — no wire touch');
      // The fail-fast error must not feed the breaker (no state churn).
      expect(g.state, CircuitBreakerState.open);
    });

    test('U4: after the cooldown the probe decides recovery', () async {
      final g = guard(
        failureThreshold: 1,
        cooldown: const Duration(seconds: 30),
      );
      await g.call(() => err('server-error')); // opens
      expect(g.isOpen, isTrue);

      now = t0.add(const Duration(seconds: 31)); // cooldown elapsed

      // Successful probe closes the breaker.
      await g.call(ok);
      expect(g.isClosed, isTrue);
      expect(g.state, CircuitBreakerState.closed);

      // Failing probe re-opens.
      final g2 = guard(
        failureThreshold: 1,
        cooldown: const Duration(seconds: 30),
      );
      await g2.call(() => err('server-error'));
      now = now.add(const Duration(seconds: 31));
      await g2.call(() => err('server-error')); // failing probe
      expect(g2.isOpen, isTrue);
    });

    test(
      'U5: a thrown transport exception counts as a failure AND propagates',
      () async {
        final g = guard(failureThreshold: 2);
        await expectLater(
          g.call(() async => throw StateError('wire dropped')),
          throwsA(isA<StateError>()),
        );
        expect(g.state, CircuitBreakerState.closed); // 1 of 2
        await expectLater(
          g.call(() async => throw StateError('wire dropped again')),
          throwsA(isA<StateError>()),
        );
        expect(g.isOpen, isTrue); // threshold reached via throws
      },
    );
  });

  group('spec 108 — options + configs', () {
    test(
      'U7: McpCallOptions defaults — 30s timeout, not read-only, no retry',
      () {
        const options = McpCallOptions();
        expect(options.timeout, isNull);
        expect(options.readOnly, isFalse);
        expect(options.retry, isNull);
        expect(McpCallOptions.defaultTimeout, const Duration(seconds: 30));
      },
    );
  });

  group('spec 108 — config smoke (purity)', () {
    test('breaker config carries threshold + cooldown', () {
      const config = McpBreakerConfig(
        failureThreshold: 7,
        cooldown: Duration(minutes: 1),
      );
      expect(config.failureThreshold, 7);
      expect(config.cooldown, const Duration(minutes: 1));
    });
  });
}
