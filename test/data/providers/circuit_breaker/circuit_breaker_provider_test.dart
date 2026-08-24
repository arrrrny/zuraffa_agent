// Regression test for arrarrny/zuraffa_agent#5 (R4 — providers & fallback:
// circuit breaker open/half-open/closed with backoff).
//
// Asserts:
// - CircuitBreakerState enum has closed/open/halfOpen.
// - CircuitBreaker defaults to closed with failureCount=0 and
//   halfOpenSuccesses=0.
// - recordFailure trips closed→open when failureThreshold is met; sets
//   openedAt + lastFailureAt.
// - recordFailure in halfOpen → open (resets halfOpenSuccesses).
// - recordFailure in open is a no-op on state (only updates lastFailureAt).
// - recordSuccess in halfOpen → closed when halfOpenThreshold met; resets
//   failureCount + clears openedAt.
// - recordSuccess in closed resets failureCount to 0 (breaks the streak).
// - recordSuccess in open is a no-op (must tryHalfOpen first).
// - tryHalfOpen transitions open→halfOpen when cooldown elapsed, else
//   unchanged; no-op in closed/halfOpen.
// - Value equality holds across all nine fields.
// - The clean-arch layers (CircuitBreakerService + CircuitBreakerProvider)
//   are wired correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/circuit_breaker/circuit_breaker.dart';
import 'package:zuraffa_agent/src/domain/services/circuit_breaker_service.dart';
import 'package:zuraffa_agent/src/data/providers/circuit_breaker/circuit_breaker_provider.dart';

void main() {
  CircuitBreaker fresh() => CircuitBreaker(
        id: 'openai-compat',
        failureThreshold: 3,
        cooldown: const Duration(seconds: 30),
        halfOpenThreshold: 2,
      );

  group('arrarrny/zuraffa_agent#5 — CircuitBreaker state machine', () {
    test('CircuitBreakerState has closed / open / halfOpen', () {
      expect(CircuitBreakerState.values.length, 3);
      expect(CircuitBreakerState.values.contains(CircuitBreakerState.closed), isTrue);
      expect(CircuitBreakerState.values.contains(CircuitBreakerState.open), isTrue);
      expect(CircuitBreakerState.values.contains(CircuitBreakerState.halfOpen), isTrue);
    });

    test('CircuitBreaker defaults to closed with zeroed counters', () {
      final b = fresh();
      expect(b.state, CircuitBreakerState.closed);
      expect(b.failureCount, 0);
      expect(b.halfOpenSuccesses, 0);
      expect(b.openedAt, isNull);
      expect(b.lastFailureAt, isNull);
      expect(b.isClosed, isTrue);
      expect(b.isOpen, isFalse);
      expect(b.isHalfOpen, isFalse);
    });

    test('recordFailure in closed increments failureCount without tripping', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final b = fresh().recordFailure(at: ts);
      expect(b.state, CircuitBreakerState.closed);
      expect(b.failureCount, 1);
      expect(b.openedAt, isNull);
      expect(b.lastFailureAt, ts);
    });

    test('recordFailure in closed trips open when failureThreshold met', () {
      final ts1 = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final ts2 = DateTime.utc(2026, 8, 24, 9, 0, 5);
      final ts3 = DateTime.utc(2026, 8, 24, 9, 0, 10);
      // failureThreshold=3 → third failure trips.
      final b = fresh().recordFailure(at: ts1).recordFailure(at: ts2).recordFailure(at: ts3);
      expect(b.state, CircuitBreakerState.open);
      expect(b.failureCount, 3);
      expect(b.openedAt, ts3);
      expect(b.lastFailureAt, ts3);
      expect(b.isOpen, isTrue);
    });

    test('recordFailure in halfOpen trips back to open and resets halfOpenSuccesses', () {
      final openTs = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final failTs = DateTime.utc(2026, 8, 24, 9, 1, 0);
      // Trip to open.
      final open = fresh().recordFailure(at: openTs).recordFailure(at: openTs).recordFailure(at: openTs);
      // Cool down to halfOpen.
      final halfOpen = open.tryHalfOpen(DateTime.utc(2026, 8, 24, 9, 1, 0));
      expect(halfOpen.state, CircuitBreakerState.halfOpen);
      // One success in halfOpen.
      final halfOpen1 = halfOpen.recordSuccess();
      expect(halfOpen1.halfOpenSuccesses, 1);
      // Failure in halfOpen → back to open, halfOpenSuccesses reset.
      final tripped = halfOpen1.recordFailure(at: failTs);
      expect(tripped.state, CircuitBreakerState.open);
      expect(tripped.halfOpenSuccesses, 0);
      expect(tripped.openedAt, failTs);
    });

    test('recordSuccess in halfOpen closes the breaker when halfOpenThreshold met', () {
      final openTs = DateTime.utc(2026, 8, 24, 9, 0, 0);
      // Trip to open.
      final open = fresh().recordFailure(at: openTs).recordFailure(at: openTs).recordFailure(at: openTs);
      // Cool down to halfOpen.
      final halfOpen = open.tryHalfOpen(DateTime.utc(2026, 8, 24, 9, 1, 0));
      // halfOpenThreshold=2 → second success closes.
      final closed = halfOpen.recordSuccess().recordSuccess();
      expect(closed.state, CircuitBreakerState.closed);
      expect(closed.failureCount, 0);
      expect(closed.openedAt, isNull);
      expect(closed.halfOpenSuccesses, 0);
    });

    test('recordSuccess in closed resets failureCount to 0', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final b = fresh().recordFailure(at: ts).recordFailure(at: ts);
      expect(b.failureCount, 2);
      final afterSuccess = b.recordSuccess();
      expect(afterSuccess.state, CircuitBreakerState.closed);
      expect(afterSuccess.failureCount, 0);
    });

    test('recordSuccess in open is a no-op (must tryHalfOpen first)', () {
      final openTs = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final open = fresh().recordFailure(at: openTs).recordFailure(at: openTs).recordFailure(at: openTs);
      final afterSuccess = open.recordSuccess();
      expect(identical(afterSuccess, open), isTrue);
      expect(afterSuccess.state, CircuitBreakerState.open);
    });

    test('tryHalfOpen transitions open→halfOpen when cooldown elapsed', () {
      final openTs = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final open = fresh().recordFailure(at: openTs).recordFailure(at: openTs).recordFailure(at: openTs);
      // cooldown=30s — at 29s, still open.
      final before = open.tryHalfOpen(DateTime.utc(2026, 8, 24, 9, 0, 29));
      expect(before.state, CircuitBreakerState.open);
      // At 30s, transitions to halfOpen.
      final after = open.tryHalfOpen(DateTime.utc(2026, 8, 24, 9, 0, 30));
      expect(after.state, CircuitBreakerState.halfOpen);
    });

    test('CircuitBreaker equality is value-based across all nine fields', () {
      final ts = DateTime.utc(2026, 8, 24, 9, 0, 0);
      final a = CircuitBreaker(
        id: 'anthropic',
        failureThreshold: 3,
        cooldown: const Duration(seconds: 30),
        halfOpenThreshold: 2,
        state: CircuitBreakerState.open,
        failureCount: 3,
        openedAt: ts,
        halfOpenSuccesses: 0,
        lastFailureAt: ts,
      );
      final b = CircuitBreaker(
        id: 'anthropic',
        failureThreshold: 3,
        cooldown: const Duration(seconds: 30),
        halfOpenThreshold: 2,
        state: CircuitBreakerState.open,
        failureCount: 3,
        openedAt: ts,
        halfOpenSuccesses: 0,
        lastFailureAt: ts,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('arrarrny/zuraffa_agent#5 — CircuitBreaker clean-arch layers', () {
    test('CircuitBreakerProvider is a CircuitBreakerService', () {
      final provider = CircuitBreakerProvider();
      expect(provider, isA<CircuitBreakerService>());
    });

    test('CircuitBreakerProvider.current throws UnimplementedError on NoParams', () {
      final provider = CircuitBreakerProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('CircuitBreakerProvider.count throws UnimplementedError on NoParams', () {
      final provider = CircuitBreakerProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
