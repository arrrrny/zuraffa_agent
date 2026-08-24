// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Service interface for the SubAgentContext value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/sub_agent_context/sub_agent_context.dart';

/// Service surface for the SubAgentContext value object.
abstract class SubAgentContextService with Loggable, FailureHandler {
  /// Returns the current SubAgentContext snapshot for the active mission.
  Future<SubAgentContext> current(NoParams params);

  /// Returns the count of SubAgentContext records for the active mission.
  Future<int> count(NoParams params);
}
