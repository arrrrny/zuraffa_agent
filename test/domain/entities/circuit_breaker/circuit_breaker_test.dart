// Spec 035 — CircuitBreaker recovery semantics tests (TDD cycles 1-3).
//
// Traces: tdd/test-list.md A1..A3, U1, U2 (cycle 1: shouldProbe
// recovery-readiness read), A4..A6 (cycle 2: full-cycle recovery
// regression — characterization, green-on-scaffold by design), A7..A9,
// U3..U5 (cycle 3: persistence contract).
//
// The shouldProbe and serialization tests are red against the scaffolded
// entity today: the scaffold ships the nine-field snapshot, the three
// transitions, and the state reads, but no recovery-readiness predicate
// and no toJson/fromJson — the coordinator's "when is the probe due"
// question has no API, and breaker state cannot cross the restart
// boundary. The full-cycle regression (A4..A6) composes existing
// transitions and is green on the scaffold BY DESIGN (a regression pin
// against future refactor leakage, not a bug fix).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/circuit_breaker/circuit_breaker.dart';

void main() {
  // threshold 3 / cooldown 30s / halfOpenThreshold 2 — same shape as the
  // provider regression suite.
  CircuitBreaker fresh() => CircuitBreaker(
        id: 'openai-compat',
        failureThreshold: 3,
        cooldown: const Duration(seconds: 30),
        halfOpenThreshold: 2,
      );

  final openAt = DateTime.utc(2026, 8, 24, 9, 0, 0);
  final cooldownEnd = openAt.add(const Duration(seconds: 30));

  CircuitBreaker tripped() => fresh()
      .recordFailure(at: openAt)
      .recordFailure(at: openAt)
      .recordFailure(at: openAt);

  group('spec 035 — CircuitBreaker shouldProbe recovery readiness (cycle 1)', () {
    test('A1: shouldProbe is false in closed (nothing to recover)', () {
      expect(fresh().shouldProbe(cooldownEnd), isFalse);
      // Even a closed breaker with failures on the streak.
      expect(
        fresh().recordFailure(at: openAt).recordFailure(at: openAt).shouldProbe(cooldownEnd),
        isFalse,
      );
    });

    test('A2: shouldProbe is false one tick before the cooldown boundary, true at it', () {
      final breaker = tripped();
      expect(breaker.isOpen, isTrue);
      // One tick (1ms) before the boundary: false.
      expect(breaker.shouldProbe(cooldownEnd.subtract(const Duration(milliseconds: 1))), isFalse);
      // Exactly at the boundary: true (inclusive, matching tryHalfOpen).
      expect(breaker.shouldProbe(cooldownEnd), isTrue);
      // Well after: true.
      expect(breaker.shouldProbe(cooldownEnd.add(const Duration(seconds: 5))), isTrue);
    });

    test('A3: shouldProbe is false in halfOpen (probe in flight, not due)', () {
      final halfOpen = tripped().tryHalfOpen(cooldownEnd);
      expect(halfOpen.isHalfOpen, isTrue);
      expect(halfOpen.shouldProbe(cooldownEnd.add(const Duration(seconds: 1))), isFalse);
    });

    test('U1: shouldProbe is false for an open breaker with null openedAt (defensive)', () {
      final unanchoredOpen = CircuitBreaker(
        id: 'openai-compat',
        failureThreshold: 3,
        cooldown: const Duration(seconds: 30),
        halfOpenThreshold: 2,
        state: CircuitBreakerState.open,
        failureCount: 3,
        halfOpenSuccesses: 0,
      );
      expect(unanchoredOpen.shouldProbe(cooldownEnd), isFalse);
    });

    test('U2: shouldProbe never transitions the breaker (read-only)', () {
      final breaker = tripped();
      breaker.shouldProbe(cooldownEnd.add(const Duration(minutes: 1)));
      expect(breaker.state, CircuitBreakerState.open, reason: 'the read must not transition');
      expect(breaker.isHalfOpen, isFalse);
      expect(breaker.halfOpenSuccesses, 0);
    });
  });

  group('spec 035 — CircuitBreaker full recovery cycle regression (cycle 2, characterization)', () {
    test('A4: a recovered breaker next single failure stays closed on a fresh streak', () {
      // Trip, cool down, probe, recover.
      final recovered = tripped().tryHalfOpen(cooldownEnd).recordSuccess().recordSuccess();
      expect(recovered.isClosed, isTrue);
      expect(recovered.failureCount, 0);
      // One failure after recovery: fresh streak of 1, NOT a re-trip.
      final afterFailure = recovered.recordFailure(at: cooldownEnd.add(const Duration(seconds: 10)));
      expect(afterFailure.isClosed, isTrue, reason: 'the old streak did not survive recovery');
      expect(afterFailure.failureCount, 1);
    });

    test('A5: fresh-threshold failures after recovery re-trip the breaker open', () {
      final recovered = tripped().tryHalfOpen(cooldownEnd).recordSuccess().recordSuccess();
      final retripAt = DateTime.utc(2026, 8, 24, 9, 5, 0);
      final reTripped = recovered
          .recordFailure(at: retripAt)
          .recordFailure(at: retripAt)
          .recordFailure(at: retripAt);
      expect(reTripped.isOpen, isTrue);
      expect(reTripped.failureCount, 3);
      expect(reTripped.openedAt, retripAt);
    });

    test('A6: a half-open failure re-trips open with probes reset and openedAt stamped', () {
      final halfOpen = tripped().tryHalfOpen(cooldownEnd);
      // Partial probe success.
      final probing = halfOpen.recordSuccess();
      expect(probing.halfOpenSuccesses, 1);
      final failAt = DateTime.utc(2026, 8, 24, 9, 1, 0);
      final reTripped = probing.recordFailure(at: failAt);
      expect(reTripped.isOpen, isTrue);
      expect(reTripped.halfOpenSuccesses, 0, reason: 'probe counters reset on re-trip');
      expect(reTripped.openedAt, failAt);
    });
  });

  group('spec 035 — CircuitBreaker persistence contract (cycle 3)', () {
    test('A7: every state round-trips JSON field-exactly (closed/open/halfOpen)', () {
      // Closed with counters and a failure timestamp.
      final closed = fresh().recordFailure(at: openAt).recordFailure(at: openAt);
      expect(CircuitBreaker.fromJson(closed.toJson()), equals(closed));
      // Open with timestamps.
      final open = tripped();
      expect(CircuitBreaker.fromJson(open.toJson()), equals(open));
      // Half-open mid-probe.
      final halfOpen = tripped().tryHalfOpen(cooldownEnd).recordSuccess();
      expect(CircuitBreaker.fromJson(halfOpen.toJson()), equals(halfOpen));
    });

    test('A8: a restored open breaker continues its cooldown from the original openedAt', () {
      final open = tripped(); // openedAt = openAt, cooldown 30s
      final restored = CircuitBreaker.fromJson(open.toJson());
      // One tick before the boundary (against the ORIGINAL openedAt): false.
      expect(restored.shouldProbe(cooldownEnd.subtract(const Duration(milliseconds: 1))), isFalse);
      // At the boundary: true — the cooldown did not restart at parse time.
      expect(restored.shouldProbe(cooldownEnd), isTrue);
      expect(restored.openedAt, openAt);
    });

    test('A9: mid-probe halfOpen resumes with partial halfOpenSuccesses after round-trip', () {
      // halfOpenSuccesses 1 of threshold 2.
      final probing = tripped().tryHalfOpen(cooldownEnd).recordSuccess();
      final restored = CircuitBreaker.fromJson(probing.toJson());
      expect(restored.isHalfOpen, isTrue);
      expect(restored.halfOpenSuccesses, 1);
      // One more success closes it — the probe RESUMES, not restarts.
      final closed = restored.recordSuccess();
      expect(closed.isClosed, isTrue);
    });

    test('U3: malformed JSON throws ArgumentError naming the field', () {
      expect(
        () => CircuitBreaker.fromJson(const {'failureThreshold': 3, 'cooldown': 30000000, 'halfOpenThreshold': 2}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'id')),
        reason: 'missing id',
      );
      expect(
        () => CircuitBreaker.fromJson(const {'id': 'b', 'cooldown': 30000000, 'halfOpenThreshold': 2}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'failureThreshold')),
        reason: 'missing failureThreshold',
      );
      expect(
        () => CircuitBreaker.fromJson(const {
          'id': 'b',
          'failureThreshold': 3,
          'cooldown': 30000000,
          'halfOpenThreshold': 2,
          'failureCount': 0,
          'halfOpenSuccesses': 0,
          'state': 'exploded',
        }),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'state')),
        reason: 'unknown state',
      );
      expect(
        () => CircuitBreaker.fromJson(const {'id': 'b', 'failureThreshold': 0, 'cooldown': 30000000, 'halfOpenThreshold': 2}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'failureThreshold')),
        reason: 'threshold below 1',
      );
      expect(
        () => CircuitBreaker.fromJson(const {'id': 'b', 'failureThreshold': 3, 'cooldown': 0, 'halfOpenThreshold': 2, 'failureCount': 0, 'halfOpenSuccesses': 0}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'cooldown')),
        reason: 'non-positive cooldown',
      );
      expect(
        () => CircuitBreaker.fromJson(const {'id': 'b', 'failureThreshold': 3, 'cooldown': 30000000, 'halfOpenThreshold': 2, 'failureCount': -1}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'failureCount')),
        reason: 'negative counter',
      );
      expect(
        () => CircuitBreaker.fromJson(const {
          'id': 'b',
          'failureThreshold': 3,
          'cooldown': 30000000,
          'halfOpenThreshold': 2,
          'failureCount': 0,
          'halfOpenSuccesses': 0,
          'openedAt': 'not-a-timestamp',
        }),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'openedAt')),
        reason: 'unparseable timestamp',
      );
    });

    test('U4: openedAt/lastFailureAt serialize only when non-null', () {
      final freshJson = fresh().toJson();
      expect(freshJson.containsKey('openedAt'), isFalse);
      expect(freshJson.containsKey('lastFailureAt'), isFalse);
      final openJson = tripped().toJson();
      expect(openJson.containsKey('openedAt'), isTrue);
      expect(openJson.containsKey('lastFailureAt'), isTrue);
    });

    test('U5: cooldown duration round-trips exactly as microseconds (no drift)', () {
      final odd = CircuitBreaker(
        id: 'b',
        failureThreshold: 3,
        cooldown: const Duration(milliseconds: 15729), // 15,729,000 µs — not a whole second
        halfOpenThreshold: 2,
      );
      final restored = CircuitBreaker.fromJson(odd.toJson());
      expect(restored.cooldown, const Duration(milliseconds: 15729));
      expect(restored.cooldown.inMicroseconds, 15729000);
    });
  });
}
