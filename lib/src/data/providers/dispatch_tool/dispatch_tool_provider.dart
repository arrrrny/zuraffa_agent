// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider for the DispatchTool data layer. Returns the active
// built-in dispatch tool declaration the engine exposes so the model can
// spawn isolated sub-agents. Mirrors the ProviderConfigProvider /
// EngineLoopProvider pattern (spec 052 / 045).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/dispatch_tool/dispatch_tool.dart';
import '../../../domain/services/dispatch_tool_service.dart';

class DispatchToolProvider
    with Loggable, FailureHandler
    implements DispatchToolService {
  final DispatchTool _active;

  DispatchToolProvider([DispatchTool? active])
      : _active = active ??
            const DispatchTool(
              id: 'default',
              toolName: 'dispatch',
              subAgentSpecId: 'general-purpose',
              riskTier: 'safe',
            );

  @override
  Future<DispatchTool> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
