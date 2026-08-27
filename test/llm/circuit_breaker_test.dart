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
  });
}
