// Issue arrrrny/zuraffa_agent#132 — the LLM circuit breaker records every
// real state transition into the audit trail.
//
// Contract pinned here (mirrors the issue #133 O-2 metrics seam exactly):
//
//   - a transition is recorded once, only when the state actually changes:
//     3 consecutive failures yield ONE closed→open entry, failures under
//     the threshold yield none;
//   - a failed half-open probe re-opens: half-open→open is recorded (the
//     lazy open→half-open read flip stays unrecorded, same blind spot the
//     O-2 gauge has — documented in the PR);
//   - a recovery success records half-open→closed;
//   - without an AuditLog wired, behavior is unchanged (U6..U9 intact).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/security/audit_log.dart';

import '../security/in_memory_audit_sink.dart';
import 'fake_llm_clock.dart';

void main() {
  late FakeLlmClock clock;
  late InMemoryAuditSink sink;
  late SinkAuditLog audit;

  setUp(() {
    clock = FakeLlmClock();
    sink = InMemoryAuditSink();
    audit = SinkAuditLog(sink: sink);
  });

  CircuitBreaker makeBreaker({
    int maxConsecutiveFailures = 3,
    int cooldownWindowMs = 60000,
  }) => CircuitBreaker(
    providerId: 'provider-a',
    maxConsecutiveFailures: maxConsecutiveFailures,
    cooldownWindowMs: cooldownWindowMs,
    clock: clock,
    auditLog: audit,
  );

  group('CircuitBreaker — audit wiring', () {
    test(
      '3 consecutive failures record exactly one closed→open transition',
      () {
        final breaker = makeBreaker();
        breaker
          ..recordFailure()
          ..recordFailure()
          ..recordFailure();

        expect(breaker.state, CircuitState.open);
        expect(sink.stored, hasLength(1));
        final entry = sink.stored.single;
        expect(entry.category, AuditCategory.breaker);
        expect(entry.action, AuditActions.breakerTransitioned);
        expect(entry.details, {
          'providerId': 'provider-a',
          'from': 'closed',
          'to': 'open',
        });
      },
    );

    test('failures under the threshold record nothing', () {
      final breaker = makeBreaker();
      breaker
        ..recordFailure()
        ..recordFailure();
      expect(sink.stored, isEmpty);
    });

    test('further failures while open record no additional transitions', () {
      final breaker = makeBreaker();
      breaker
        ..recordFailure()
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();
      expect(sink.stored, hasLength(1));
    });

    test(
      'a failed half-open probe re-opens: half-open→open is recorded',
      () async {
        final breaker = makeBreaker();
        breaker
          ..recordFailure()
          ..recordFailure()
          ..recordFailure();
        await clock.sleep(60000); // cooldown elapses
        expect(breaker.attemptAllowed(), isTrue); // lazy flip to half-open
        expect(breaker.state, CircuitState.halfOpen);

        breaker.recordFailure();

        expect(breaker.state, CircuitState.open);
        expect(
          [
            for (final e in sink.stored)
              '${e.details['from']}→${e.details['to']}',
          ],
          ['closed→open', 'halfOpen→open'],
        );
      },
    );

    test('a recovery success records half-open→closed', () async {
      final breaker = makeBreaker();
      breaker
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();
      await clock.sleep(60000);
      expect(breaker.attemptAllowed(), isTrue);

      breaker.recordSuccess();

      expect(breaker.state, CircuitState.closed);
      expect(
        [
          for (final e in sink.stored)
            '${e.details['from']}→${e.details['to']}',
        ],
        ['closed→open', 'halfOpen→closed'],
      );
    });

    test('the state names are the CircuitState enum names', () async {
      final breaker = makeBreaker();
      breaker
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();
      expect(sink.stored.single.details['to'], CircuitState.open.name);
    });

    test(
      'a throwing audit sink never breaks the breaker (issue #132 review fix)',
      () async {
        final breaker = CircuitBreaker(
          providerId: 'provider-a',
          clock: clock,
          auditLog: SinkAuditLog(sink: ThrowingAuditSink()),
        );

        breaker
          ..recordFailure()
          ..recordFailure()
          ..recordFailure(); // closed→open — the audited transition
        await clock.sleep(60000);
        breaker.recordSuccess(); // half-open→closed — another audited one

        expect(breaker.state, CircuitState.closed);
        // Pump the fire-and-forget audit futures: pre-fix, their sink
        // errors reached the zone uncaught-error handler here and failed
        // this run; the breaker must stay ignorant of audit-backend
        // failures.
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
