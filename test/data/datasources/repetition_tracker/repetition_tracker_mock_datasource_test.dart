// Spec 25 — RepetitionTracker datasource pair tests (TDD cycles 2-4).
//
// Traces: tdd/test-list.md A1..A3 (loop detection MVP), U7 (compile parity,
// issues #25/#26), U8 (injectable clock), U9 (derived signal).
// Supersedes the pre-refinement stub assertions (UnimplementedError) — the
// refined spec ships real in-memory behavior (spec.md Assumptions).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/datasources/repetition_tracker/repetition_tracker_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart';
import 'package:zuraffa_agent/src/domain/entities/repetition_tracker/repetition_tracker.dart';

void main() {
  group('spec 025 — RepetitionTracker datasource pair', () {
    test('U7: RepetitionTrackerMockDatasource is a RepetitionTrackerDatasource', () {
      expect(RepetitionTrackerMockDatasource(), isA<RepetitionTrackerDatasource>());
    });

    group('A1..A3 loop detection (cycle 2)', () {
      test('A1: recording maxCalls-1 times keeps isLooping false and count tracks', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 3),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        expect(await ds.record('tool_a@1:hash1', at: t0), equals(1));
        expect(await ds.record('tool_a@1:hash1', at: t0.add(const Duration(seconds: 1))), equals(2));
        final inWindow = t0.add(const Duration(seconds: 2));
        expect(await ds.count('tool_a@1:hash1', now: inWindow), equals(2));
        expect(await ds.isLooping('tool_a@1:hash1', now: inWindow), isFalse);
      });

      test('A2: the maxCalls-th in-window occurrence trips isLooping (inclusive)', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 3),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        for (var i = 0; i < 3; i++) {
          await ds.record('tool_a@1:hash1', at: t0.add(Duration(seconds: i)));
        }
        expect(await ds.isLooping('tool_a@1:hash1', now: t0.add(const Duration(seconds: 3))), isTrue);
      });

      test('A3: two signatures loop independently — counts are keyed per signature', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_b@1:hash2', at: t0);
        expect(await ds.count('tool_a@1:hash1', now: t0), equals(2));
        expect(await ds.count('tool_b@1:hash2', now: t0), equals(1));
        expect(await ds.isLooping('tool_a@1:hash1', now: t0), isTrue);
        expect(await ds.isLooping('tool_b@1:hash2', now: t0), isFalse);
      });

      test('U8: injectable clock drives evaluation when no explicit now is passed', () async {
        final now = DateTime(2026, 1, 1, 12);
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2),
          clock: () => now,
        );
        await ds.record('tool_a@1:hash1');
        await ds.record('tool_a@1:hash1');
        expect(await ds.isLooping('tool_a@1:hash1'), isTrue);
      });

      test('U9: isLooping equals current().isRepetition(count) for every signature', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('tool_a@1:hash1', at: t0);
        final config = await ds.current();
        final count = await ds.count('tool_a@1:hash1', now: t0);
        expect(await ds.isLooping('tool_a@1:hash1', now: t0), equals(config.isRepetition(count)));
      });
    });

    group('A4..A5 + U10..U11 window expiry (cycle 3)', () {
      test('A4: after the window passes, count is 0 and isLooping reverts to false', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2, window: Duration(seconds: 60)),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_a@1:hash1', at: t0);
        expect(await ds.isLooping('tool_a@1:hash1', now: t0.add(const Duration(seconds: 30))), isTrue);

        final afterWindow = t0.add(const Duration(seconds: 61));
        expect(await ds.count('tool_a@1:hash1', now: afterWindow), equals(0));
        expect(await ds.isLooping('tool_a@1:hash1', now: afterWindow), isFalse);
      });

      test('A5: boundary — a record exactly window-old is expired, strictly inside is alive', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 1, window: Duration(seconds: 60)),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('expired@1:h', at: t0);
        await ds.record('alive@1:h', at: t0.add(const Duration(seconds: 1)));

        // Exactly window old -> expired.
        expect(await ds.count('expired@1:h', now: t0.add(const Duration(seconds: 60))), equals(0));
        // Strictly inside the window -> alive.
        expect(await ds.count('alive@1:h', now: t0.add(const Duration(seconds: 60))), equals(1));
      });

      test('U10: record with an explicit at-timestamp is respected for window pruning', () async {
        final now = DateTime(2026, 1, 1, 12);
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 5, window: Duration(seconds: 60)),
          clock: () => now,
        );
        // Recorded "61s ago" via explicit at: the write path must prune it
        // once the window has passed it by.
        final beforeWindow = now.subtract(const Duration(seconds: 61));
        expect(await ds.record('tool_a@1:hash1', at: beforeWindow), equals(1));
        expect(await ds.record('tool_a@1:hash1', at: now), equals(1));
      });

      test('U11: a late record older than the window is pruned on first evaluation', () async {
        final now = DateTime(2026, 1, 1, 12);
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 5, window: Duration(seconds: 60)),
          clock: () => now,
        );
        // Out-of-order, older than the window: dead on arrival.
        await ds.record('tool_a@1:hash1', at: now.subtract(const Duration(seconds: 120)));
        expect(await ds.count('tool_a@1:hash1'), equals(0));
        expect(await ds.record('tool_a@1:hash1'), equals(1));
      });
    });

    group('A6..A7 persistence contract + reset (cycle 4)', () {
      test('A6: reset() zeroes all counts, clears every loop signal, preserves current() config', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_b@1:hash2', at: t0);
        expect(await ds.isLooping('tool_a@1:hash1', now: t0), isTrue);

        await ds.reset();

        expect(await ds.count('tool_a@1:hash1', now: t0), equals(0));
        expect(await ds.count('tool_b@1:hash2', now: t0), equals(0));
        expect(await ds.isLooping('tool_a@1:hash1', now: t0), isFalse);
        expect(await ds.current(), equals(const RepetitionTracker(id: 'rt', maxCalls: 2)));
      });

      test('A7: record() returns the post-record in-window count (read-after-write)', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 5),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        expect(await ds.record('fresh@1:h', at: t0), equals(1));
        expect(await ds.record('fresh@1:h', at: t0.add(const Duration(seconds: 1))), equals(2));
        // A record outside the window does not inflate the returned count.
        expect(await ds.record('fresh@1:h', at: t0.add(const Duration(seconds: 120))), equals(1));
      });
    });
  });
}
