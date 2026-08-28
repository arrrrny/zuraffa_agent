// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#4 (R3 - tools & mcp).
//
// Concrete provider for the ToolRegistry data layer. Returns the active
// single-namespace registry snapshot (DDA + generated + remote-MCP tools
// behind one lookup). Mirrors the ProviderConfigProvider /
// EngineLoopProvider pattern (spec 052 / 045).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/tool_registry/tool_registry.dart';
import '../../../domain/services/tool_registry_service.dart';

class ToolRegistryProvider
    with Loggable, FailureHandler
    implements ToolRegistryService {
  final ToolRegistry _active;

  ToolRegistryProvider([ToolRegistry? active])
      : _active = active ??
            const ToolRegistry(
              id: 'default',
              toolNames: ['fs.read', 'fs.write', 'dispatch'],
              ddToolCount: 2,
              generatedToolCount: 1,
              mcpToolCount: 0,
            );

  @override
  Future<ToolRegistry> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
