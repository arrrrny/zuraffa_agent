// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#2 (R2 - engine core loop).
//
// Service interface for the EngineLoop value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/engine_loop/engine_loop.dart';

/// Service surface for the EngineLoop value object.
abstract class EngineLoopService with Loggable, FailureHandler {
  /// Returns the current EngineLoop snapshot for the active mission.
  Future<EngineLoop> current(NoParams params);

  /// Returns the count of EngineLoop records for the active mission.
  Future<int> count(NoParams params);
}
