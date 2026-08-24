// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 — providers & fallback).
//
// Concrete provider stub for the CircuitBreaker data layer. Mirrors the
// ToolResultProvider pattern from PR #49 and the AgentSessionProvider
// pattern from PR #50: bodies throw UnimplementedError so the file is
// analyzable without forcing real I/O. Parameterless methods (current,
// count) declare NoParams params so the @override clause matches the
// CircuitBreakerService interface exactly.

import 'package:zuraffa/zuraffa.dart';

import '../../../domain/entities/circuit_breaker/circuit_breaker.dart';
import '../../../domain/services/circuit_breaker_service.dart';

class CircuitBreakerProvider
    with Loggable, FailureHandler
    implements CircuitBreakerService {
  CircuitBreakerProvider();

  @override
  Future<CircuitBreaker> current(NoParams params) async =>
      throw UnimplementedError('Implement CircuitBreakerProvider.current');

  @override
  Future<int> count(NoParams params) async =>
      throw UnimplementedError('Implement CircuitBreakerProvider.count');
}
