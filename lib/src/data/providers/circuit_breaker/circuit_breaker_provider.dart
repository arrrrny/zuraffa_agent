// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// Concrete provider for the CircuitBreaker data layer. Returns the current
// (head) breaker snapshot for the active fallback chain. This replaces the
// previous throwing stub (spec 045 / R4.3).

import 'package:zuraffa/zuraffa.dart' hide CompactionStrategy;

import '../../../domain/entities/circuit_breaker/circuit_breaker.dart';
import '../../../domain/services/circuit_breaker_service.dart';

class CircuitBreakerProvider
    with Loggable, FailureHandler
    implements CircuitBreakerService {
  final CircuitBreaker _active;

  CircuitBreakerProvider([CircuitBreaker? active])
      : _active = active ??
            const CircuitBreaker(
              id: 'openai-compat',
              failureThreshold: 3,
              cooldown: Duration(seconds: 30),
              halfOpenThreshold: 2,
            );

  @override
  Future<CircuitBreaker> current(NoParams params) async => _active;

  @override
  Future<int> count(NoParams params) async => 1;
}
