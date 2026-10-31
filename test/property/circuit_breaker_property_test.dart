// Property-based tests for both CircuitBreakers — issue #128 AC-2.
//
// Two breakers live in the repo (spec 035 value object, spec 008 runtime);
// this suite drives BOTH through randomized transition sequences and pins the
// state-machine invariants:
//
// Domain value object (lib/src/domain/entities/circuit_breaker/, immutable):
//   T1  transition table — every (state, action) outcome matches the doc
//       comment exactly (closed→closed|open, halfOpen→open|halfOpen|closed,
//       open is absorbing for recordSuccess, tryHalfOpen only fires open)
//   T2  inclusive cooldown boundary — now == openedAt + cooldown probes
//   T3  immutability — transitions never mutate the receiver snapshot
//   T4  JSON round-trip — fromJson(toJson(s)) == s for every visited snapshot
//   T5  reachability — open implies openedAt != null; closed implies
//       failureCount < failureThreshold
//
// Runtime breaker (lib/src/llm/circuit_breaker.dart, mutable, fake clock):
//   R1  trips open exactly at the threshold-th consecutive failure
//   R2  open gates attempts; after cooldown it lazily half-opens and allows
//       the probe; a failed probe re-opens with a fresh count of 1
//   R3  recordSuccess always lands closed with a zeroed failure counter
//
// All randomness is seeded (see property_harness.dart) — CI-stable.
library;

import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/circuit_breaker/circuit_breaker.dart'
    as domain;
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart' as runtime;
import 'package:zuraffa_agent/src/llm/llm_clock.dart';

import 'property_harness.dart';

/// Settable LlmClock — deterministic control over `now()` for the runtime
/// breaker (the shared FakeLlmClock advances only via sleep; the boundary
/// tests need exact positions on both sides of the cooldown edge).
class _SettableClock implements LlmClock {
  DateTime current = DateTime.utc(2026, 1, 1);

  @override
  DateTime now() => current;

  @override
  Future<void> sleep(int milliseconds) async {
    current = current.add(Duration(milliseconds: milliseconds));
  }
}

void main() {
  group('CircuitBreaker (spec 035 value object) properties', () {
    /// Drives one random action from [breaker], asserting the transition
    /// table (T1) and the reachability invariants (T5) after every step.
    /// Returns the successor snapshot for the next walk step.
    domain.CircuitBreaker step(
      domain.CircuitBreaker breaker,
      Random rnd,
      int trial,
    ) {
      // T3 evidence: re-serializing the receiver after the transition must
      // reproduce the pre-transition bytes — no field was mutated in place.
      final beforeJson = jsonEncode(breaker.toJson());
      final now = randomDateTime(rnd);
      final domain.CircuitBreaker next;

      switch (rnd.nextInt(3)) {
        case 0: // recordFailure
          next = breaker.recordFailure(at: now);
          switch (breaker.state) {
            case domain.CircuitBreakerState.closed:
              final trips =
                  breaker.failureCount + 1 >= breaker.failureThreshold;
              expect(
                next.state,
                trips
                    ? domain.CircuitBreakerState.open
                    : domain.CircuitBreakerState.closed,
                reason: 'trial $trial: closed + failure (T1)',
              );
              expect(
                next.failureCount,
                breaker.failureCount + 1,
                reason: 'trial $trial',
              );
              expect(
                next.openedAt,
                trips ? now : null,
                reason: 'trial $trial: openedAt set iff tripped',
              );
            case domain.CircuitBreakerState.halfOpen:
              expect(
                next.state,
                domain.CircuitBreakerState.open,
                reason: 'trial $trial: halfOpen + failure re-opens (T1)',
              );
              expect(
                next.halfOpenSuccesses,
                0,
                reason: 'trial $trial: failed probe resets successes',
              );
              expect(next.openedAt, now, reason: 'trial $trial');
            case domain.CircuitBreakerState.open:
              expect(
                next.state,
                domain.CircuitBreakerState.open,
                reason: 'trial $trial: open + failure stays open (T1)',
              );
              expect(
                next.openedAt,
                breaker.openedAt,
                reason: 'trial $trial: openedAt anchor is preserved',
              );
          }
          expect(next.lastFailureAt, now, reason: 'trial $trial');
        case 1: // recordSuccess
          next = breaker.recordSuccess();
          switch (breaker.state) {
            case domain.CircuitBreakerState.open:
              expect(
                identical(next, breaker),
                isTrue,
                reason:
                    'trial $trial: successes in open are no-ops (T1) — the '
                    'same instance must come back',
              );
              return breaker; // nothing further to check
            case domain.CircuitBreakerState.closed:
              expect(
                next.state,
                domain.CircuitBreakerState.closed,
                reason: 'trial $trial',
              );
              expect(
                next.failureCount,
                0,
                reason: 'trial $trial: success breaks the streak',
              );
              expect(next.openedAt, isNull, reason: 'trial $trial');
            case domain.CircuitBreakerState.halfOpen:
              final closes =
                  breaker.halfOpenSuccesses + 1 >= breaker.halfOpenThreshold;
              expect(
                next.state,
                closes
                    ? domain.CircuitBreakerState.closed
                    : domain.CircuitBreakerState.halfOpen,
                reason: 'trial $trial: halfOpen + success (T1)',
              );
              if (closes) {
                expect(next.failureCount, 0, reason: 'trial $trial');
                expect(next.openedAt, isNull, reason: 'trial $trial');
              } else {
                expect(
                  next.halfOpenSuccesses,
                  breaker.halfOpenSuccesses + 1,
                  reason: 'trial $trial',
                );
              }
          }
        default: // tryHalfOpen
          next = breaker.tryHalfOpen(now);
          final due =
              breaker.state == domain.CircuitBreakerState.open &&
              breaker.openedAt != null &&
              now.difference(breaker.openedAt!) >= breaker.cooldown;
          if (!due) {
            expect(
              identical(next, breaker),
              isTrue,
              reason:
                  'trial $trial: tryHalfOpen on a not-due/non-open breaker is '
                  'a no-op returning the same instance (T1)',
            );
            return breaker;
          }
          expect(
            next.state,
            domain.CircuitBreakerState.halfOpen,
            reason: 'trial $trial: due probe transitions (T1)',
          );
          expect(next.halfOpenSuccesses, 0, reason: 'trial $trial');
      }

      // T3 — the receiver was never mutated by the transition.
      expect(
        jsonEncode(breaker.toJson()),
        beforeJson,
        reason: 'trial $trial: T3 immutability of the receiver',
      );

      // T5 — reachability invariants.
      if (next.state == domain.CircuitBreakerState.open) {
        expect(
          next.openedAt,
          isNotNull,
          reason: 'trial $trial: T5 open requires an openedAt anchor',
        );
      }
      if (next.state == domain.CircuitBreakerState.closed) {
        expect(
          next.failureCount,
          lessThan(next.failureThreshold),
          reason: 'trial $trial: T5 a closed breaker is below threshold',
        );
      }

      // T4 — persistence round-trip on every visited snapshot.
      final restored = domain.CircuitBreaker.fromJson(
        jsonDecode(jsonEncode(next.toJson())) as Map<String, dynamic>,
      );
      expect(restored, equals(next), reason: 'trial $trial: T4 round-trip');

      return next;
    }

    test('T1..T5: randomized transition walk over 300 sequences', () {
      check('breaker transition walk', (rnd, trial) {
        var breaker = domain.CircuitBreaker(
          id: 'p-$trial',
          failureThreshold: intBetween(rnd, 1, 4),
          cooldown: Duration(milliseconds: intBetween(rnd, 1, 5000)),
          halfOpenThreshold: intBetween(rnd, 1, 4),
        );
        final walkLength = intBetween(rnd, 3, 14);
        for (var i = 0; i < walkLength; i++) {
          breaker = step(breaker, rnd, trial);
        }
      }, iterations: 300);
    });

    test(
      'T2: the cooldown boundary is inclusive (now == openedAt + cooldown)',
      () {
        check('T2 inclusive boundary', (rnd, trial) {
          final cooldownMs = intBetween(rnd, 1, 100000);
          final openedAt = randomDateTime(rnd);
          final breaker = domain.CircuitBreaker(
            id: 'p-$trial',
            failureThreshold: 1,
            cooldown: Duration(milliseconds: cooldownMs),
            halfOpenThreshold: 1,
            state: domain.CircuitBreakerState.open,
            openedAt: openedAt,
          );
          final boundary = openedAt.add(Duration(milliseconds: cooldownMs));
          expect(
            breaker.tryHalfOpen(boundary).state,
            domain.CircuitBreakerState.halfOpen,
            reason: 'trial $trial: exactly at the boundary must probe',
          );
          expect(
            breaker.shouldProbe(boundary),
            isTrue,
            reason: 'trial $trial: shouldProbe mirrors tryHalfOpen',
          );
          expect(
            breaker
                .tryHalfOpen(boundary.subtract(const Duration(microseconds: 1)))
                .state,
            domain.CircuitBreakerState.open,
            reason: 'trial $trial: one microsecond early stays open',
          );
        }, iterations: 200);
      },
    );
  });

  group('CircuitBreaker (spec 008 runtime, mutable) properties', () {
    test('R1: trips open exactly at the threshold-th consecutive failure', () {
      check('R1 trip threshold', (rnd, trial) {
        final threshold = intBetween(rnd, 1, 5);
        final clock = _SettableClock();
        final breaker = runtime.CircuitBreaker(
          providerId: 'p-$trial',
          maxConsecutiveFailures: threshold,
          cooldownWindowMs: intBetween(rnd, 1, 60000),
          clock: clock,
        );
        for (var i = 1; i < threshold; i++) {
          breaker.recordFailure();
          expect(
            breaker.state,
            runtime.CircuitState.closed,
            reason: 'trial $trial: failure $i of $threshold stays closed',
          );
          expect(breaker.consecutiveFailures, i, reason: 'trial $trial');
        }
        breaker.recordFailure();
        expect(
          breaker.state,
          runtime.CircuitState.open,
          reason: 'trial $trial: threshold-th failure must trip open',
        );
      }, iterations: 200);
    });

    test('R2: open gates, cooldown half-opens, failed probe re-opens at 1', () {
      check('R2 recovery cycle', (rnd, trial) {
        final cooldownMs = intBetween(rnd, 2, 10000);
        final clock = _SettableClock();
        final breaker = runtime.CircuitBreaker(
          providerId: 'p-$trial',
          maxConsecutiveFailures: 1,
          cooldownWindowMs: cooldownMs,
          clock: clock,
        );
        breaker.recordFailure(); // -> open
        expect(
          breaker.attemptAllowed(),
          isFalse,
          reason: 'trial $trial: an open breaker gates attempts',
        );

        // Just before the cooldown boundary: still open, still gated.
        clock.current = clock.current.add(
          Duration(milliseconds: cooldownMs - 1),
        );
        expect(
          breaker.state,
          runtime.CircuitState.open,
          reason: 'trial $trial: cooldown not yet elapsed',
        );
        expect(breaker.attemptAllowed(), isFalse, reason: 'trial $trial');

        // At the boundary: lazy half-open transition, probe allowed.
        clock.current = clock.current.add(const Duration(milliseconds: 1));
        expect(
          breaker.state,
          runtime.CircuitState.halfOpen,
          reason: 'trial $trial: boundary is inclusive',
        );
        expect(breaker.attemptAllowed(), isTrue, reason: 'trial $trial');

        // A failed probe re-opens immediately with a FRESH count of 1.
        breaker.recordFailure();
        expect(
          breaker.state,
          runtime.CircuitState.open,
          reason: 'trial $trial: failed probe re-opens',
        );
        expect(
          breaker.consecutiveFailures,
          1,
          reason: 'trial $trial: fresh count after a failed probe',
        );
      }, iterations: 200);
    });

    test('R3: recordSuccess always lands closed with a zeroed counter', () {
      check('R3 success lands closed', (rnd, trial) {
        final cooldownMs = intBetween(rnd, 2, 10000);
        final clock = _SettableClock();
        final breaker = runtime.CircuitBreaker(
          providerId: 'p-$trial',
          maxConsecutiveFailures: intBetween(rnd, 1, 4),
          cooldownWindowMs: cooldownMs,
          clock: clock,
        );
        // Random walk into any state, then a success.
        final failures = intBetween(rnd, 0, 5);
        for (var i = 0; i < failures; i++) {
          breaker.recordFailure();
        }
        if (breaker.state == runtime.CircuitState.open && rnd.nextBool()) {
          clock.current = clock.current.add(Duration(milliseconds: cooldownMs));
          expect(breaker.state, runtime.CircuitState.halfOpen);
        }
        breaker.recordSuccess();
        expect(
          breaker.state,
          runtime.CircuitState.closed,
          reason: 'trial $trial',
        );
        expect(breaker.consecutiveFailures, 0, reason: 'trial $trial');
        expect(breaker.attemptAllowed(), isTrue, reason: 'trial $trial');
      }, iterations: 200);
    });
  });
}
