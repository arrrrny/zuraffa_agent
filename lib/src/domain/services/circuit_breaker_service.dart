// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 — providers & fallback).
//
// Service interface for the CircuitBreaker value object — same shape as
// ToolResultService (PR #49 / issue #31) and AgentSessionService (PR #50 /
// issue #1). Parameterless methods declare `NoParams params` so the
// implementing provider can `@override` them without ambiguity. The
// service surface is value-object-appropriate: no CRUD, no identity
// mutation — callers read the current breaker snapshot and the count of
// breakers in the fallback chain.

import 'package:zuraffa/zuraffa.dart';

import '../entities/circuit_breaker/circuit_breaker.dart';

/// Service surface for the CircuitBreaker value object.
abstract class CircuitBreakerService with Loggable, FailureHandler {
  /// Returns the current (head) breaker snapshot for the active
  /// fallback chain.
  Future<CircuitBreaker> current(NoParams params);

  /// Returns the count of breakers in the active fallback chain (one
  /// per provider).
  Future<int> count(NoParams params);
}
