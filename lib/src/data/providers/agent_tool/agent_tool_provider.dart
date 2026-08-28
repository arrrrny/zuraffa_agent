// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 — tools & MCP client).
//
// Concrete provider for the AgentTool data layer. Holds the active
// mission's registered tool declarations in memory: `current` returns the
// most-recently-registered tool (or a constructed built-in default when
// nothing has been registered) and `count` returns the registry size.
// Mirrors the ProviderConfigProvider / EngineLoopProvider pattern
// (spec 052 / 045).

// Hide `AgentTool` (the @Zorphy annotation from zorphy_annotation, re-exported
// via zuraffa.dart) so it does not clash with our hand-curated AgentTool
// value object in the entities import below.
import 'package:zuraffa/zuraffa.dart' hide AgentTool;

import '../../../domain/entities/agent_tool/agent_tool.dart';
import '../../../domain/services/agent_tool_service.dart';

class AgentToolProvider
    with Loggable, FailureHandler
    implements AgentToolService {
  /// Built-in default declaration returned when no tool is registered.
  static const AgentTool defaultTool = AgentTool(
    id: 'fs.read',
    description: 'Read a file from the local workspace.',
    riskTier: RiskTier.safe,
    executionMode: ExecutionMode.sequential,
  );

  final List<AgentTool> _tools;

  AgentToolProvider([List<AgentTool>? tools])
      : _tools = List<AgentTool>.of(tools ?? const <AgentTool>[]);

  /// Registers [tool] in the in-memory registry and returns it.
  AgentTool register(AgentTool tool) {
    _tools.add(tool);
    return tool;
  }

  @override
  Future<AgentTool> current(NoParams params) async =>
      _tools.isEmpty ? defaultTool : _tools.last;

  @override
  Future<int> count(NoParams params) async => _tools.length;
}
