// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#6 (R5 — sub-agents & specs).
//
// Service interface for the SubAgentSpec value object — same shape as
// ToolResultService (PR #49 / issue #31), AgentSessionService (PR #50 /
// issue #1), AgentToolService (PR #52 / issue #4), and
// CircuitBreakerService (PR #53 / issue #5). Parameterless methods
// declare `NoParams params` so the implementing provider can `@override`
// them without ambiguity. The service surface is value-object-
// appropriate: no CRUD, no identity mutation — callers read the current
// spec and the count of registered specs.

import 'package:zuraffa/zuraffa.dart';

import '../entities/sub_agent_spec/sub_agent_spec.dart';

/// Service surface for the SubAgentSpec value object.
abstract class SubAgentSpecService with Loggable, FailureHandler {
  /// Returns the current (most-recently-registered) sub-agent spec in
  /// the active mission's spec registry.
  Future<SubAgentSpec> current(NoParams params);

  /// Returns the count of sub-agent specs currently registered in the
  /// active mission's spec registry.
  Future<int> count(NoParams params);
}
