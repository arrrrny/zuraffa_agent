// Spec 27 — StopPolicy entity tests (TDD cycle 1).
//
// Traces: tdd/test-list.md U1..U3 (FR-001, SC-002).
// Pins the canonical default policy as a single source of truth and the
// value-object semantics across all five fields.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/stop_policy/stop_policy.dart';

void main() {
  group('StopPolicy value object (U1..U3)', () {
    test('U1: defaultPolicy carries the documented values', () {
      const d = StopPolicy.defaultPolicy;
      expect(d.id, equals('default'));
      expect(d.maxTurns, equals(100));
      expect(d.wallClockTimeout, equals(Duration.zero));
      expect(d.repetitionThreshold, equals(5));
      expect(d.enabled, isTrue);
    });

    test('U2: value equality across all five fields', () {
      const a = StopPolicy(
        id: 'p1',
        maxTurns: 10,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
        enabled: false,
      );
      const b = StopPolicy(
        id: 'p1',
        maxTurns: 10,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
        enabled: false,
      );
      expect(a, equals(b));
    });

    test('U3: equal instances have equal hashCodes', () {
      const a = StopPolicy(
        id: 'p1',
        maxTurns: 10,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
      );
      const b = StopPolicy(
        id: 'p1',
        maxTurns: 10,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
      );
      expect(a.hashCode, equals(b.hashCode));
      const other = StopPolicy(
        id: 'p1',
        maxTurns: 11,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
      );
      expect(a, isNot(equals(other)));
    });

    test('U4: inequality is detected per field (equality is not silently dropped)', () {
      // Each pair differs in exactly one field; if `operator ==` ever stops
      // comparing that field, the corresponding `isNot(equals(...))` fails.
      const base = StopPolicy(
        id: 'p1',
        maxTurns: 10,
        wallClockTimeout: Duration(seconds: 30),
        repetitionThreshold: 3,
        enabled: true,
      );
      expect(
        base,
        isNot(equals(const StopPolicy(
          id: 'p2',
          maxTurns: 10,
          wallClockTimeout: Duration(seconds: 30),
          repetitionThreshold: 3,
          enabled: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const StopPolicy(
          id: 'p1',
          maxTurns: 11,
          wallClockTimeout: Duration(seconds: 30),
          repetitionThreshold: 3,
          enabled: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const StopPolicy(
          id: 'p1',
          maxTurns: 10,
          wallClockTimeout: Duration(seconds: 31),
          repetitionThreshold: 3,
          enabled: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const StopPolicy(
          id: 'p1',
          maxTurns: 10,
          wallClockTimeout: Duration(seconds: 30),
          repetitionThreshold: 4,
          enabled: true,
        ))),
      );
      expect(
        base,
        isNot(equals(const StopPolicy(
          id: 'p1',
          maxTurns: 10,
          wallClockTimeout: Duration(seconds: 30),
          repetitionThreshold: 3,
          enabled: false,
        ))),
      );
    });
  });
}
