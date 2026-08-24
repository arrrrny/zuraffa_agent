// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#7 (R6 — eval harness: pass@k unbiased
// estimator).
//
// Service interface for the PassAtK value object — same shape as
// ToolResultService (PR #49 / issue #31), AgentSessionService (PR #50 /
// issue #1), AgentToolService (PR #52 / issue #4), CircuitBreakerService
// (PR #53 / issue #5), and SubAgentSpecService (PR #54 / issue #6).
// Parameterless methods declare `NoParams params` so the implementing
// provider can `@override` them without ambiguity. The service surface
// is value-object-appropriate: no CRUD, no identity mutation — callers
// read the most-recently-computed pass@k snapshot and the count of
// computations logged in the active mission.

import 'package:zuraffa/zuraffa.dart';

import '../entities/pass_at_k/pass_at_k.dart';

/// Service surface for the PassAtK value object.
abstract class PassAtKService with Loggable, FailureHandler {
  /// Returns the most-recently-computed pass@k snapshot for the active
  /// mission.
  Future<PassAtK> current(NoParams params);

  /// Returns the count of pass@k computations logged in the active
  /// mission's eval ledger.
  Future<int> count(NoParams params);
}
