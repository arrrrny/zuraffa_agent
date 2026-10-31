// HAND-CURATED regression tests for the ReplayDiff value object +
// ReplayDiffProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/replay_diff/replay_diff_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/replay_diff/replay_diff.dart';
import 'package:zuraffa_agent/src/domain/services/replay_diff_service.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - ReplayDiff value equality', () {
    test('ReplayDiff equality is value-based across all fields', () {
      const a = ReplayDiff(
        id: 'id-a',
        missionId: 'ref-1',
        driftDetected: true,
        diffSummary: null,
      );
      const b = ReplayDiff(
        id: 'id-a',
        missionId: 'ref-1',
        driftDetected: true,
        diffSummary: null,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ReplayDiff inequality differs when a field changes', () {
      const a = ReplayDiff(
        id: 'id-a',
        missionId: 'ref-1',
        driftDetected: true,
        diffSummary: null,
      );
      const b = ReplayDiff(
        id: 'id-b',
        missionId: 'ref-2',
        driftDetected: false,
        diffSummary: null,
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - ReplayDiff clean-arch layers', () {
    test('ReplayDiffProvider is a ReplayDiffService', () {
      final provider = ReplayDiffProvider();
      expect(provider, isA<ReplayDiffService>());
    });

    test('ReplayDiffProvider.current returns the active replay diff', () async {
      final provider = ReplayDiffProvider();
      final diff = await provider.current(const NoParams());
      expect(diff, isA<ReplayDiff>());
      expect(diff.id, 'default');
      expect(diff.missionId, 'mission-0');
      expect(diff.driftDetected, isFalse);
    });

    test('ReplayDiffProvider.count returns 1', () async {
      final provider = ReplayDiffProvider();
      expect(await provider.count(const NoParams()), 1);
    });

    test('ReplayDiffProvider honours an injected value object', () async {
      const custom = ReplayDiff(
        id: 'custom',
        missionId: 'mission-x',
        driftDetected: true,
        diffSummary: 'bytes differ',
      );
      final provider = ReplayDiffProvider(custom);
      final diff = await provider.current(const NoParams());
      expect(diff.id, 'custom');
      expect(diff.driftDetected, isTrue);
      expect(diff.diffSummary, 'bytes differ');
    });
  });
}
