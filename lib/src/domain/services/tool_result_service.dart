// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// Service interface for the ToolResult value object — same shape as
// ArtifactService (PR #32 / issue #11). Parameterless methods declare
// `NoParams params` so the implementing provider can `@override` them
// without ambiguity. The service surface is value-object-appropriate:
// no CRUD, no identity.

// `ToolResult` is hidden because zuraffa >=6.2.0's agent runtime
// (src/agent/policy/policy_hook.dart) exports its own; spec 031's ToolResult
// value object is the one in scope here.
import 'package:zuraffa/zuraffa.dart' hide ToolResult;

import '../entities/tool_result/tool_result.dart';

/// Service surface for the ToolResult value object.
abstract class ToolResultService with Loggable, FailureHandler {
  /// Returns the last-emitted [ToolResult] for the current mission.
  Future<ToolResult> current(NoParams params);

  /// Returns the count of tool results emitted in the current mission.
  Future<int> count(NoParams params);
}
