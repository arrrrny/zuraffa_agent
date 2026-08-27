// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/008-fallback-chain-runtime/spec.md with this attribution retained.
//

import '../domain/entities/client_health/client_health.dart';
import 'llm_clock.dart';

/// Breaker states (spec 008 US2): closed -> open -> half-open -> closed.
enum CircuitState { closed, open, halfOpen }

/// Independent per-provider circuit breaker (spec 008 FR-002).
class CircuitBreaker {
  final String providerId;
  final int maxConsecutiveFailures;
  final int cooldownWindowMs;
  final LlmClock clock;

  CircuitBreaker({
    required this.providerId,
    this.maxConsecutiveFailures = 3,
    this.cooldownWindowMs = 60000,
    required this.clock,
  });

  CircuitState _state = CircuitState.closed;
  int _consecutiveFailures = 0;
  DateTime? _lastFailureAt;

  CircuitState get state {
    if (_state == CircuitState.open && _cooldownElapsed) {
      _state = CircuitState.halfOpen;
    }
    return _state;
  }

  bool get _cooldownElapsed {
    final lastFailure = _lastFailureAt;
    if (lastFailure == null) return false;
    return clock.now().difference(lastFailure).inMilliseconds >=
        cooldownWindowMs;
  }
  int get consecutiveFailures => _consecutiveFailures;

  void recordSuccess() {
    _state = CircuitState.closed;
    _consecutiveFailures = 0;
  }

  void recordFailure() {
    _lastFailureAt = clock.now();
    if (_state == CircuitState.halfOpen) {
      // A failed probe re-opens immediately with a fresh count.
      _consecutiveFailures = 1;
      _state = CircuitState.open;
      return;
    }
    _consecutiveFailures += 1;
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _state = CircuitState.open;
    }
  }

  ClientHealth health() => throw UnimplementedError();
}
