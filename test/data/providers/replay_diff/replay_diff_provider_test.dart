// HAND-CURATED regression tests for the ReplayDiff value object +
// ReplayDiffProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/replay_diff/replay_diff.dart';
import 'package:zuraffa_agent/src/domain/services/replay_diff_service.dart';
import 'package:zuraffa_agent/src/data/providers/replay_diff/replay_diff_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - ReplayDiff value equality', () {
    test('ReplayDiff equality is value-based across all fields', () {
      final a = ReplayDiff(id: 'id-a', missionId: 'ref-1', driftDetected: true, diffSummary: null);
      final b = ReplayDiff(id: 'id-a', missionId: 'ref-1', driftDetected: true, diffSummary: null);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ReplayDiff inequality differs when a field changes', () {
      final a = ReplayDiff(id: 'id-a', missionId: 'ref-1', driftDetected: true, diffSummary: null);
      final b = ReplayDiff(id: 'id-b', missionId: 'ref-2', driftDetected: false, diffSummary: null);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - ReplayDiff clean-arch layers', () {
    test('ReplayDiffProvider is a ReplayDiffService', () {
      final provider = ReplayDiffProvider();
      expect(provider, isA<ReplayDiffService>());
    });

    test('ReplayDiffProvider.current throws UnimplementedError on NoParams', () {
      final provider = ReplayDiffProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ReplayDiffProvider.count throws UnimplementedError on NoParams', () {
      final provider = ReplayDiffProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
