// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 - sub-agents & declarative).
//
// Concrete provider for the SubAgentContext data layer. Returns the active
// isolated context snapshot for the running mission. Backed by an in-memory
// repository of contexts; current() returns the active (most-recent) context
// and count() returns the number of tracked contexts. Replaces the previous
// stub (spec 033).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/sub_agent_context/sub_agent_context.dart';
import '../../../domain/services/sub_agent_context_service.dart';

class SubAgentContextProvider
    with Loggable, FailureHandler
    implements SubAgentContextService {
  final List<SubAgentContext> _contexts;

  SubAgentContextProvider([SubAgentContext? active])
      : _contexts = [
          active ??
              const SubAgentContext(
                id: 'ctx-default',
                subAgentSpecId: 'spec-default',
                sessionId: 'session-default',
                toolAllowlist: [],
                budgetTurns: 10,
              ),
        ];

  @override
  Future<SubAgentContext> current(NoParams params) async => _contexts.last;

  @override
  Future<int> count(NoParams params) async => _contexts.length;
}
