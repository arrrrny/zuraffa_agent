// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the ReplayDiff value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/replay_diff/replay_diff.dart';

/// Service surface for the ReplayDiff value object.
abstract class ReplayDiffService with Loggable, FailureHandler {
  /// Returns the current ReplayDiff snapshot for the active mission.
  Future<ReplayDiff> current(NoParams params);

  /// Returns the count of ReplayDiff records for the active mission.
  Future<int> count(NoParams params);
}
