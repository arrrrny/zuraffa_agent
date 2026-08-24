// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Service interface for the LoopSafetyRails value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/loop_safety_rails/loop_safety_rails.dart';

/// Service surface for the LoopSafetyRails value object.
abstract class LoopSafetyRailsService with Loggable, FailureHandler {
  /// Returns the current LoopSafetyRails snapshot for the active mission.
  Future<LoopSafetyRails> current(NoParams params);

  /// Returns the count of LoopSafetyRails records for the active mission.
  Future<int> count(NoParams params);
}
