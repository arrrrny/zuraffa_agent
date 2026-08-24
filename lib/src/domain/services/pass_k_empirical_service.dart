// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 - eval harness).
//
// Service interface for the PassKEmpirical value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/pass_k_empirical/pass_k_empirical.dart';

/// Service surface for the PassKEmpirical value object.
abstract class PassKEmpiricalService with Loggable, FailureHandler {
  /// Returns the current PassKEmpirical snapshot for the active mission.
  Future<PassKEmpirical> current(NoParams params);

  /// Returns the count of PassKEmpirical records for the active mission.
  Future<int> count(NoParams params);
}
