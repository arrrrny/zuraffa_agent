// Tests for lib/src/llm/circuit_breaker.dart — Spec 008 US2.
// Behaviors U6..U9 — see specs/008-fallback-chain-runtime/tdd/test-list.md.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';

import 'fake_llm_clock.dart';

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  CircuitBreaker makeBreaker({
    int maxConsecutiveFailures = 3,
    int cooldownWindowMs = 60000,
  }) =>
      CircuitBreaker(
        providerId: 'provider-a',
        maxConsecutiveFailures: maxConsecutiveFailures,
        cooldownWindowMs: cooldownWindowMs,
        clock: clock,
      );

  group('CircuitBreaker (U6..U9)', () {
    test('U6: 3 consecutive failures open the breaker (2 do not)', () {
      final breaker = makeBreaker();
      expect(breaker.state, CircuitState.closed);
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.closed);
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);
      expect(breaker.consecutiveFailures, 3);
    });

    test('U7: an open breaker transitions to half-open when the cooldown elapses (injected clock)', () async {
      final breaker = makeBreaker(cooldownWindowMs: 60000);
      breaker.recordFailure();
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);

      // Before the cooldown elapses the breaker stays open.
      await clock.sleep(59999);
      expect(breaker.state, CircuitState.open);

      // At/after the cooldown the transition to half-open happens.
      await clock.sleep(1);
      expect(breaker.state, CircuitState.halfOpen);
    });

    test('U8: a half-open probe success closes the breaker; a probe failure re-opens it', () async {
      final success = makeBreaker();
      success.recordFailure();
      success.recordFailure();
      success.recordFailure();
      await clock.sleep(60000);
      expect(success.state, CircuitState.halfOpen);
      success.recordSuccess();
      expect(success.state, CircuitState.closed);
      expect(success.consecutiveFailures, 0);

      final failure = makeBreaker();
      failure.recordFailure();
      failure.recordFailure();
      failure.recordFailure();
      await clock.sleep(60000);
      expect(failure.state, CircuitState.halfOpen);
      failure.recordFailure();
      expect(failure.state, CircuitState.open);
      expect(failure.consecutiveFailures, 1);
    });

    test('U9: attempt gating blocks while open before cooldown, allows one probe after, and health() projects ClientHealth', () async {
      final breaker = makeBreaker(cooldownWindowMs: 30000);
      // No attemptAllowed yet: compile-time member; behavior asserted below.
      expect(breaker.attemptAllowed(), isTrue); // closed -> allowed

      breaker.recordFailure();
      breaker.recordFailure();
      breaker.recordFailure();
      expect(breaker.state, CircuitState.open);
      // Open before cooldown: attempts blocked.
      expect(breaker.attemptAllowed(), isFalse);

      // After cooldown: exactly one probe is allowed (half-open).
      await clock.sleep(30000);
      expect(breaker.attemptAllowed(), isTrue);
      expect(breaker.state, CircuitState.halfOpen);

      // health() projects the breaker into a ClientHealth snapshot.
      final health = breaker.health();
      expect(health.state, 'half-open');
      expect(health.consecutiveFailures, 3);
      expect(health.cooldownWindowMs, 30000);
      expect(health.isHealthy, isFalse);
      expect(health.id, isNotEmpty);
      expect(health.lastFailureAt, isNotNull);
    });
  });
}
