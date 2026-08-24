// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#3 (R1 - state & sessions).
//
// Service interface for the AgentMessage value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/agent_message/agent_message.dart';

/// Service surface for the AgentMessage value object.
abstract class AgentMessageService with Loggable, FailureHandler {
  /// Returns the current AgentMessage snapshot for the active mission.
  Future<AgentMessage> current(NoParams params);

  /// Returns the count of AgentMessage records for the active mission.
  Future<int> count(NoParams params);
}
