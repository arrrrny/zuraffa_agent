// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the GraderSealed value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/grader_sealed/grader_sealed.dart';

/// Service surface for the GraderSealed value object.
abstract class GraderSealedService with Loggable, FailureHandler {
  /// Returns the current GraderSealed snapshot for the active mission.
  Future<GraderSealed> current(NoParams params);

  /// Returns the count of GraderSealed records for the active mission.
  Future<int> count(NoParams params);
}
