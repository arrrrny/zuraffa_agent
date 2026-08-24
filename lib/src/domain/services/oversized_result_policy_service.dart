// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Service interface for the OversizedResultPolicy value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/oversized_result_policy/oversized_result_policy.dart';

/// Service surface for the OversizedResultPolicy value object.
abstract class OversizedResultPolicyService with Loggable, FailureHandler {
  /// Returns the current OversizedResultPolicy snapshot for the active mission.
  Future<OversizedResultPolicy> current(NoParams params);

  /// Returns the count of OversizedResultPolicy records for the active mission.
  Future<int> count(NoParams params);
}
