// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (R2 — state & sessions).
//
// Concrete provider stub for the AgentSession data layer. Mirrors the
// ToolResultProvider pattern from PR #49: bodies throw UnimplementedError
// so the file is analyzable without forcing real I/O. Parameterless
// methods (current, count) declare NoParams params so the @override
// clause matches the AgentSessionService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/agent_session/agent_session.dart';
import '../../../domain/services/agent_session_service.dart';

class AgentSessionProvider
    with Loggable, FailureHandler
    implements AgentSessionService {
  AgentSessionProvider();

  @override
  Future<AgentSession> current(NoParams params) async =>
      throw UnimplementedError('Implement AgentSessionProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement AgentSessionProvider.count');
}
