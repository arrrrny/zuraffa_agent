// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/008-fallback-chain-runtime/spec.md with this attribution retained.
//

import 'dart:async';

import '../domain/entities/client_health/client_health.dart';
import '../observability/metrics.dart';
import '../security/audit_log.dart';
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
    this.metrics,
    this.auditLog,
  });

  /// Optional metrics seam (issue #133, O-2). When supplied, every state
  /// transition publishes the
  /// `agent_circuit_breaker_state{provider=<id>}` gauge
  /// (closed=0, half-open=1, open=2). The initial state is not published —
  /// gauges appear with the first transition.
  final Metrics? metrics;

  /// Optional audit seam (issue #132). When supplied, every REAL state
  /// transition is appended to the security audit trail as a
  /// `breaker.transitioned` entry (providerId + from + to). Mirrors the
  /// [metrics] seam exactly, including its blind spot: the lazy
  /// open→half-open read flip inside the [state] getter is not recorded.
  final AuditLog? auditLog;

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
    final previous = state; // Applies the lazy open -> half-open flip.
    _state = CircuitState.closed;
    _consecutiveFailures = 0;
    _publishState();
    _auditTransition(previous);
  }

  void recordFailure() {
    final previous = state; // Applies the lazy open -> half-open flip.
    _lastFailureAt = clock.now();
    if (_state == CircuitState.halfOpen) {
      // A failed probe re-opens immediately with a fresh count.
      _consecutiveFailures = 1;
      _state = CircuitState.open;
      _publishState();
      _auditTransition(previous);
      return;
    }
    _consecutiveFailures += 1;
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _state = CircuitState.open;
    }
    _publishState();
    _auditTransition(previous);
  }

  /// Appends one `breaker.transitioned` entry when the state actually
  /// changed (issue #132). No-op without an injection; fire-and-forget so
  /// breaker callers never wait on the audit sink.
  void _auditTransition(CircuitState previous) {
    final audit = auditLog;
    if (audit == null) return;
    final current = _state;
    if (current == previous) return;
    unawaited(
      audit.breakerTransition(
        providerId: providerId,
        from: previous.name,
        to: current.name,
      ),
    );
  }

  /// Publishes the current state to the injected [metrics]. No-op without
  /// an injection.
  void _publishState() {
    final m = metrics;
    if (m == null) return;
    final ordinal = switch (state) {
      CircuitState.closed => 0,
      CircuitState.halfOpen => 1,
      CircuitState.open => 2,
    };
    m.gauge(
      'agent_circuit_breaker_state',
      ordinal,
      labels: {'provider': providerId},
    );
  }

  /// Whether a call may be attempted right now: closed always allows;
  /// open allows nothing; half-open allows the single recovery probe.
  bool attemptAllowed() {
    final current = state; // Evaluates the lazy open -> half-open transition.
    return current == CircuitState.closed || current == CircuitState.halfOpen;
  }

  /// Projects the breaker into a [ClientHealth] snapshot value.
  ClientHealth health() {
    final current = state;
    return ClientHealth(
      state: switch (current) {
        CircuitState.closed => 'closed',
        CircuitState.open => 'open',
        CircuitState.halfOpen => 'half-open',
      },
      consecutiveFailures: _consecutiveFailures,
      cooldownWindowMs: cooldownWindowMs,
      lastFailureAt: _lastFailureAt ?? clock.now(),
      // Only a closed breaker is healthy; half-open is still probing.
      isHealthy: current == CircuitState.closed,
    );
  }
}
