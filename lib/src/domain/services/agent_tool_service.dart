// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 — tools & MCP client).
//
// Service interface for the AgentTool value object — same shape as
// ToolResultService (PR #49 / issue #31) and AgentSessionService (PR #50 /
// issue #1). Parameterless methods declare `NoParams params` so the
// implementing provider can `@override` them without ambiguity. The
// service surface is value-object-appropriate: no CRUD, no identity
// mutation — callers read the current registered tool and the count of
// registered tools.

// Hide `AgentTool` (the @Zorphy annotation from zorphy_annotation, re-exported
// via zuraffa.dart) so it does not clash with our hand-curated AgentTool
// value object in the entities import below.
import 'package:zuraffa/zuraffa.dart' hide AgentTool;

import '../entities/agent_tool/agent_tool.dart';

/// Service surface for the AgentTool declaration entity.
abstract class AgentToolService with Loggable, FailureHandler {
  /// Returns the current (most-recently-registered) tool in the active
  /// mission's tool registry.
  Future<AgentTool> current(NoParams params);

  /// Returns the count of tools currently registered in the active
  /// mission's tool registry.
  Future<int> count(NoParams params);
}
