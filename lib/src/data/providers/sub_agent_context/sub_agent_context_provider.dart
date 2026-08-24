// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider stub for the SubAgentContext data layer. Mirrors the
// SteeringQueueProvider pattern (spec 033) and ToolResultProvider
// (spec 031): bodies throw UnimplementedError so the file is analyzable
// without forcing real I/O.

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/sub_agent_context/sub_agent_context.dart';
import '../../../domain/services/sub_agent_context_service.dart';

class SubAgentContextProvider
    with Loggable, FailureHandler
    implements SubAgentContextService {
  SubAgentContextProvider();

  @override
  Future<SubAgentContext> current(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentContextProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentContextProvider.count');
}
