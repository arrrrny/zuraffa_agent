// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the ReplayCliSurface value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/replay_cli_surface/replay_cli_surface.dart';

/// Service surface for the ReplayCliSurface value object.
abstract class ReplayCliSurfaceService with Loggable, FailureHandler {
  /// Returns the current ReplayCliSurface snapshot for the active mission.
  Future<ReplayCliSurface> current(NoParams params);

  /// Returns the count of ReplayCliSurface records for the active mission.
  Future<int> count(NoParams params);
}
