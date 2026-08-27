// Spec 25 — RepetitionTracker entity parity tests (TDD cycle 1).
//
// Traces: tdd/test-list.md U1..U6 (FR-001, FR-002, FR-008, SC-004, edge-1).
// The entity is the loop-detection policy value object: id + maxCalls (N)
// + window (M) + pure isRepetition predicate.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/repetition_tracker/repetition_tracker.dart';

void main() {
  group('RepetitionTracker value object (U1..U6)', () {
    test('U1: value equality across id, maxCalls and window', () {
      const a = RepetitionTracker(id: 'default', maxCalls: 3, window: Duration(seconds: 30));
      const b = RepetitionTracker(id: 'default', maxCalls: 3, window: Duration(seconds: 30));
      expect(a, equals(b));
    });

    test('U2: equal instances have equal hashCodes', () {
      const a = RepetitionTracker(id: 'rt-1', maxCalls: 5, window: Duration(seconds: 60));
      const b = RepetitionTracker(id: 'rt-1', maxCalls: 5, window: Duration(seconds: 60));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('U3: differing id, maxCalls or window makes instances unequal', () {
      const base = RepetitionTracker(id: 'rt-1', maxCalls: 5, window: Duration(seconds: 60));
      const otherId = RepetitionTracker(id: 'rt-2', maxCalls: 5, window: Duration(seconds: 60));
      const otherMaxCalls = RepetitionTracker(id: 'rt-1', maxCalls: 6, window: Duration(seconds: 60));
      const otherWindow = RepetitionTracker(id: 'rt-1', maxCalls: 5, window: Duration(seconds: 61));
      expect(base, isNot(equals(otherId)));
      expect(base, isNot(equals(otherMaxCalls)));
      expect(base, isNot(equals(otherWindow)));
    });

    test('U4: isRepetition is false at maxCalls-1 and true at maxCalls', () {
      const tracker = RepetitionTracker(id: 'rt-1', maxCalls: 3, window: Duration(seconds: 60));
      expect(tracker.isRepetition(0), isFalse);
      expect(tracker.isRepetition(2), isFalse);
      expect(tracker.isRepetition(3), isTrue);
      expect(tracker.isRepetition(4), isTrue);
    });

    test('U5: defaults are maxCalls=5 and window=60s when omitted', () {
      const tracker = RepetitionTracker(id: 'default');
      expect(tracker.maxCalls, equals(5));
      expect(tracker.window, equals(const Duration(seconds: 60)));
    });

    test('U6: constructor rejects maxCalls < 1', () {
      expect(
        () => RepetitionTracker(id: 'bad', maxCalls: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => RepetitionTracker(id: 'bad', maxCalls: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
