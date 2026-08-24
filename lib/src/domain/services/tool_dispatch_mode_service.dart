// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Service interface for the ToolDispatchMode value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/tool_dispatch_mode/tool_dispatch_mode.dart';

/// Service surface for the ToolDispatchMode value object.
abstract class ToolDispatchModeService with Loggable, FailureHandler {
  /// Returns the current ToolDispatchMode snapshot for the active mission.
  Future<ToolDispatchMode> current(NoParams params);

  /// Returns the count of ToolDispatchMode records for the active mission.
  Future<int> count(NoParams params);
}
