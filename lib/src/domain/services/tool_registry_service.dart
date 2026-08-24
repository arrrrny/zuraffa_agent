// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Service interface for the ToolRegistry value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/tool_registry/tool_registry.dart';

/// Service surface for the ToolRegistry value object.
abstract class ToolRegistryService with Loggable, FailureHandler {
  /// Returns the current ToolRegistry snapshot for the active mission.
  Future<ToolRegistry> current(NoParams params);

  /// Returns the count of ToolRegistry records for the active mission.
  Future<int> count(NoParams params);
}
