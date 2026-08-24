// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 — sub-agents & specs).
//
// Concrete provider stub for the SubAgentSpec data layer. Mirrors the
// ToolResultProvider pattern from PR #49, the AgentSessionProvider from
// PR #50, the AgentToolProvider from PR #52, and the
// CircuitBreakerProvider from PR #53: bodies throw UnimplementedError
// so the file is analyzable without forcing real I/O. Parameterless
// methods (current, count) declare NoParams params so the @override
// clause matches the SubAgentSpecService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/sub_agent_spec/sub_agent_spec.dart';
import '../../../domain/services/sub_agent_spec_service.dart';

class SubAgentSpecProvider
    with Loggable, FailureHandler
    implements SubAgentSpecService {
  SubAgentSpecProvider();

  @override
  Future<SubAgentSpec> current(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentSpecProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement SubAgentSpecProvider.count');
}
