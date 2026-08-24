// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Service interface for the YamlAgentSpec value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/yaml_agent_spec/yaml_agent_spec.dart';

/// Service surface for the YamlAgentSpec value object.
abstract class YamlAgentSpecService with Loggable, FailureHandler {
  /// Returns the current YamlAgentSpec snapshot for the active mission.
  Future<YamlAgentSpec> current(NoParams params);

  /// Returns the count of YamlAgentSpec records for the active mission.
  Future<int> count(NoParams params);
}
