// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (R2 — state & sessions).
//
// Concrete provider for the AgentSession data layer. Returns the active
// session. Replaces the previous UnimplementedError stub (spec 032).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/agent_session/agent_session.dart';
import '../../../domain/services/agent_session_service.dart';

class AgentSessionProvider
    with Loggable, FailureHandler
    implements AgentSessionService {
  final AgentSession _active;

  AgentSessionProvider([AgentSession? active])
      : _active = active ??
            AgentSession(
              id: 'default',
              rootEntryId: 'root',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

  @override
  Future<AgentSession> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
