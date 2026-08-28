import 'package:test/test.dart';

import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event_log.dart';

void main() {
  final t1 = DateTime.utc(2026, 8, 24, 7, 30, 0);
  final t2 = DateTime.utc(2026, 8, 24, 8, 0, 0);
  final t3 = DateTime.utc(2026, 8, 24, 9, 15, 0);

  // Fixtures: distinct payloads + emission times so every projection's
  // result is unambiguous. Same-instance assertions (same(...)) keep this
  // suite independent of spec 066's operator == work.
  final missionStarted = MissionStarted(
    emittedAt: t1,
    missionId: 'm-7',
    startedAt: t1,
  );
  final turnStarted = TurnStarted(emittedAt: t1, turnId: 't-1');
  final providerError = ProviderError(
    emittedAt: t2,
    providerName: 'openai',
    error: '429 rate-limited',
  );
  final missionCompleted = MissionCompleted(
    emittedAt: t3,
    missionId: 'm-7',
    status: 'success',
    summary: null,
  );

  group('EngineEventLog', () {
    test('add/addAll preserve insertion order', () {
      final log = EngineEventLog();
      log.add(missionStarted);
      log.addAll([providerError, turnStarted, missionCompleted]);
      final events = log.events;
      expect(events.length, 4);
      expect(events[0], same(missionStarted));
      expect(events[1], same(providerError));
      expect(events[2], same(turnStarted));
      expect(events[3], same(missionCompleted));
    });

    test('events is an unmodifiable snapshot', () {
      final log = EngineEventLog();
      log.add(turnStarted);
      final snapshot = log.events;
      expect(() => snapshot.add(providerError), throwsUnsupportedError);
      expect(() => snapshot.remove(turnStarted), throwsUnsupportedError);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      expect(() => snapshot[0] = providerError, throwsUnsupportedError);
      // The log itself is unaffected by attempted mutations of the snapshot.
      expect(log.length, 1);
      expect(log.events.first, same(turnStarted));
      // Non-aliasing: each read is a fresh, independent copy, not a live view
      // into the log. A second read returns a distinct instance, and appending
      // to the log after the read does not mutate the already-returned snapshot.
      final secondRead = log.events;
      expect(identical(snapshot, secondRead), isFalse);
      log.add(providerError);
      expect(
        snapshot.length,
        1,
        reason: 'snapshot is a held copy and must not reflect later appends',
      );
      expect(secondRead.length, 1);
      expect(log.length, 2);
    });

    test('length and emptiness track appends', () {
      final log = EngineEventLog();
      expect(log.isEmpty, isTrue);
      expect(log.isNotEmpty, isFalse);
      expect(log.length, 0);
      log.add(turnStarted);
      expect(log.isEmpty, isFalse);
      expect(log.isNotEmpty, isTrue);
      expect(log.length, 1);
      log.addAll(const []); // empty iterable is a no-op
      expect(log.length, 1);
    });

    test('byType filters by exact type, insertion order', () {
      final secondStart = MissionStarted(
        emittedAt: t2,
        missionId: 'm-8',
        startedAt: t2,
      );
      final log = EngineEventLog();
      log.add(missionStarted); // m-7 @ t1
      log.add(turnStarted);
      log.add(secondStart); // m-8 @ t2
      log.add(providerError);
      final starts = log.byType<MissionStarted>();
      expect(starts.length, 2);
      expect(starts[0], same(missionStarted));
      expect(starts[1], same(secondStart));
      expect(log.byType<MissionCompleted>(), isEmpty);
      expect(log.byType<ProviderError>().single, same(providerError));
    });

    test('firstOfType and lastOfType', () {
      final secondStart = MissionStarted(
        emittedAt: t2,
        missionId: 'm-8',
        startedAt: t2,
      );
      final log = EngineEventLog();
      log.add(missionStarted);
      log.add(turnStarted);
      log.add(secondStart);
      expect(log.firstOfType<MissionStarted>(), same(missionStarted));
      expect(log.lastOfType<MissionStarted>(), same(secondStart));
      expect(log.firstOfType<ProviderError>(), isNull);
      expect(log.lastOfType<MissionCompleted>(), isNull);
    });

    test(
      'since filters by emission time with inclusive/exclusive boundary',
      () {
        final log = EngineEventLog();
        log.add(missionStarted); // t1
        log.add(providerError); // t2
        log.add(missionCompleted); // t3
        // Default is inclusive: an event emitted exactly AT the cutoff counts.
        final sinceT2 = log.since(t2);
        expect(sinceT2.length, 2);
        expect(sinceT2[0], same(providerError));
        expect(sinceT2[1], same(missionCompleted));
        // Exclusive: the boundary event is dropped.
        expect(log.since(t2, inclusive: false).single, same(missionCompleted));
        expect(log.since(t3).single, same(missionCompleted));
        // Future cutoff: empty, does not throw.
        expect(log.since(DateTime.utc(2026, 8, 25)), isEmpty);
      },
    );

    test(
      'before filters by emission time with inclusive/exclusive boundary',
      () {
        final log = EngineEventLog();
        log.add(missionStarted); // t1
        log.add(providerError); // t2
        log.add(missionCompleted); // t3
        // Default is exclusive: an event emitted exactly AT the cutoff is out.
        expect(log.before(t2).single, same(missionStarted));
        // Inclusive: the boundary event counts (emittedAt <= cutoff).
        final beforeT3 = log.before(t3, inclusive: true);
        expect(beforeT3.length, 3);
        expect(beforeT3[0], same(missionStarted));
        expect(beforeT3[1], same(providerError));
        expect(beforeT3[2], same(missionCompleted));
        expect(log.before(t1), isEmpty);
        expect(log.before(t1, inclusive: true).single, same(missionStarted));
      },
    );

    test('empty log behaves as empty', () {
      final log = EngineEventLog();
      expect(log.events, isEmpty);
      expect(log.byType<MissionStarted>(), isEmpty);
      expect(log.firstOfType<MissionStarted>(), isNull);
      expect(log.lastOfType<MissionStarted>(), isNull);
      expect(log.since(t1), isEmpty);
      expect(log.before(t1), isEmpty);
    });
  });
}
