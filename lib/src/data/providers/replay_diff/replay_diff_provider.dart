// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider for the ReplayDiff data layer. Returns the active
// replay-diff snapshot (input drift detection) as a constructed default
// (spec 052).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/replay_diff/replay_diff.dart';
import '../../../domain/services/replay_diff_service.dart';

class ReplayDiffProvider
    with Loggable, FailureHandler
    implements ReplayDiffService {
  final ReplayDiff _active;

  ReplayDiffProvider([ReplayDiff? active])
      : _active = active ??
            const ReplayDiff(
              id: 'default',
              missionId: 'mission-0',
              driftDetected: false,
              diffSummary: null,
            );

  @override
  Future<ReplayDiff> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
