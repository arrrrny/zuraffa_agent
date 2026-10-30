// Issue #135 — EngineEventLog.prune: the append-only event log gets the
// same retention axes (maxAge by emittedAt, maxCount, maxBytes by the
// event's rendered size).

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event.dart';
import 'package:zuraffa_agent/src/engine/events/engine_event_log.dart';
import 'package:zuraffa_agent/src/retention.dart';

EngineEvent event(DateTime at, String id) =>
    TurnStarted(emittedAt: at, turnId: 'turn-$id');

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 5);
  final t2 = DateTime.utc(2026, 1, 10);
  final now = DateTime.utc(2026, 1, 16);

  EngineEventLog seeded() {
    final log = EngineEventLog();
    log.add(event(t0, 'a'));
    log.add(event(t1, 'b'));
    log.add(event(t2, 'c'));
    return log;
  }

  test('maxAge drops events emitted before the cutoff', () {
    final log = seeded();

    final result = log.prune(
      const RetentionPolicy(maxAge: Duration(days: 6)),
      now: now,
    );

    expect(result.removedCount, 2);
    expect(log.events.map((e) => (e as TurnStarted).turnId), ['turn-c']);
  });

  test('maxCount keeps the newest events', () {
    final log = seeded();

    log.prune(const RetentionPolicy(maxCount: 1), now: now);

    expect(log.length, 1);
    expect((log.events.single as TurnStarted).turnId, 'turn-c');
  });

  test('maxBytes drops oldest events until the rendered size fits', () {
    final log = EngineEventLog();
    log.add(
      MissionCompleted(
        emittedAt: t0,
        missionId: 'm',
        status: 'completed',
        summary: 'a fairly long summary that dominates the byte budget',
      ),
    );
    log.add(event(t2, 'tiny'));

    final result = log.prune(const RetentionPolicy(maxBytes: 150), now: now);

    expect(result.removedCount, 1);
    expect(log.length, 1);
    expect(log.events.single, isA<TurnStarted>());
  });

  test('unlimited policy prunes nothing', () {
    final log = seeded();

    final result = log.prune(const RetentionPolicy.unlimited(), now: now);

    expect(result.removedCount, 0);
    expect(log.length, 3);
  });
}
