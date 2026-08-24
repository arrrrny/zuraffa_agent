// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 — tools & MCP client).
//
// Concrete provider stub for the AgentTool data layer. Mirrors the
// ToolResultProvider pattern from PR #49 and the AgentSessionProvider
// pattern from PR #50: bodies throw UnimplementedError so the file is
// analyzable without forcing real I/O. Parameterless methods (current,
// count) declare NoParams params so the @override clause matches the
// AgentToolService interface exactly.

// Hide `AgentTool` (the @Zorphy annotation from zorphy_annotation, re-exported
// via zuraffa.dart) so it does not clash with our hand-curated AgentTool
// value object in the entities import below.
import 'package:zuraffa/zuraffa.dart' hide AgentTool;

import '../../../domain/entities/agent_tool/agent_tool.dart';
import '../../../domain/services/agent_tool_service.dart';

class AgentToolProvider
    with Loggable, FailureHandler
    implements AgentToolService {
  AgentToolProvider();

  @override
  Future<AgentTool> current(NoParams params) async =>
      throw UnimplementedError('Implement AgentToolProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement AgentToolProvider.count');
}
