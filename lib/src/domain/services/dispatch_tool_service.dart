// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Service interface for the DispatchTool value object - same shape as
// SteeringQueueService (spec 033) and ToolResultService (spec 031):
// parameterless methods declare NoParams params so the implementing
// provider can @override them without ambiguity.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../entities/dispatch_tool/dispatch_tool.dart';

/// Service surface for the DispatchTool value object.
abstract class DispatchToolService with Loggable, FailureHandler {
  /// Returns the current DispatchTool snapshot for the active mission.
  Future<DispatchTool> current(NoParams params);

  /// Returns the count of DispatchTool records for the active mission.
  Future<int> count(NoParams params);
}
