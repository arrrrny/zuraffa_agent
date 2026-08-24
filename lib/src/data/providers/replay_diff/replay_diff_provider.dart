// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Concrete provider stub for the ReplayDiff data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/replay_diff/replay_diff.dart';
import '../../../domain/services/replay_diff_service.dart';

class ReplayDiffProvider
    with Loggable, FailureHandler
    implements ReplayDiffService {
  ReplayDiffProvider();

  @override
  Future<ReplayDiff> current(NoParams params) async =>
      throw UnimplementedError('Implement ReplayDiffProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement ReplayDiffProvider.count');
}
