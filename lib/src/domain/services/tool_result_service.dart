// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#31.
//
// Service interface for the ToolResult value object — same shape as
// ArtifactService (PR #32 / issue #11). Parameterless methods declare
// `NoParams params` so the implementing provider can `@override` them
// without ambiguity. The service surface is value-object-appropriate:
// no CRUD, no identity.

import 'package:zuraffa/zuraffa.dart';

import '../entities/tool_result/tool_result.dart';

/// Service surface for the ToolResult value object.
abstract class ToolResultService with Loggable, FailureHandler {
  /// Returns the last-emitted [ToolResult] for the current mission.
  Future<ToolResult> current(NoParams params);

  /// Returns the count of tool results emitted in the current mission.
  Future<int> count(NoParams params);
}
