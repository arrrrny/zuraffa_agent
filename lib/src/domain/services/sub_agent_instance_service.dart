// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Service interface for the SubAgentInstance value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/sub_agent_instance/sub_agent_instance.dart';

/// Service surface for the SubAgentInstance value object.
abstract class SubAgentInstanceService with Loggable, FailureHandler {
  /// Returns the current SubAgentInstance snapshot for the active mission.
  Future<SubAgentInstance> current(NoParams params);

  /// Returns the count of SubAgentInstance records for the active mission.
  Future<int> count(NoParams params);
}
