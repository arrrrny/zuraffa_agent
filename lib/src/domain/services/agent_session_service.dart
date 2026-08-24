// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#1 (R2 — state & sessions).
//
// Service interface for the AgentSession root entity — same shape as
// ToolResultService (PR #49 / issue #31) and ArtifactService (PR #32 /
// issue #11). Parameterless methods declare `NoParams params` so the
// implementing provider can `@override` them without ambiguity. The
// service surface is value-object-appropriate: no CRUD, no identity
// mutation — callers read the current session head and the count of
// sessions in the active mission.

import 'package:zuraffa/zuraffa.dart';

import '../entities/agent_session/agent_session.dart';

/// Service surface for the AgentSession root entity.
abstract class AgentSessionService with Loggable, FailureHandler {
  /// Returns the current (head) session for the active mission.
  Future<AgentSession> current(NoParams params);

  /// Returns the count of sessions in the active mission (primary + any
  /// branches/forks).
  Future<int> count(NoParams params);
}
