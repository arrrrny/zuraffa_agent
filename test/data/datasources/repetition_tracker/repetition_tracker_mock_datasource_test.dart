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
        expect(await ds.count('tool_a@1:hash1'), equals(2));
        expect(await ds.isLooping('tool_a@1:hash1'), isFalse);
      });

      test('A2: the maxCalls-th in-window occurrence trips isLooping (inclusive)', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 3),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        for (var i = 0; i < 3; i++) {
          await ds.record('tool_a@1:hash1', at: t0.add(Duration(seconds: i)));
        }
        expect(await ds.isLooping('tool_a@1:hash1'), isTrue);
      });

      test('A3: two signatures loop independently — counts are keyed per signature', () async {
        final ds = RepetitionTrackerMockDatasource(
          config: const RepetitionTracker(id: 'rt', maxCalls: 2),
        );
        final t0 = DateTime(2026, 1, 1, 12);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_a@1:hash1', at: t0);
        await ds.record('tool_b@1:hash2', at: t0);
        expect(await ds.count('tool_a@1:hash1'), equals(2));
        expect(await ds.count('tool_b@1:hash2'), equals(1));
        expect(await ds.isLooping('tool_a@1:hash1'), isTrue);
        expect(await ds.isLooping('tool_b@1:hash2'), isFalse);
      });

      test('U8: injectable clock drives evaluation when no explicit now is passed', () async {
        var now = DateTime(2026, 1, 1, 12);
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
        final count = await ds.count('tool_a@1:hash1');
        expect(await ds.isLooping('tool_a@1:hash1'), equals(config.isRepetition(count)));
      });
    });
  });
}
