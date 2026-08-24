// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Service interface for the CompactionStrategy value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/compaction_strategy/compaction_strategy.dart';

/// Service surface for the CompactionStrategy value object.
abstract class CompactionStrategyService with Loggable, FailureHandler {
  /// Returns the current CompactionStrategy snapshot for the active mission.
  Future<CompactionStrategy> current(NoParams params);

  /// Returns the count of CompactionStrategy records for the active mission.
  Future<int> count(NoParams params);
}
