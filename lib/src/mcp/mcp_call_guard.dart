// HAND-CURATED — spec 108 (issue arrrrny/zuraffa_agent#120).
//
// McpCallGuard — per-server call-level resilience for the MCP clients: a
// mutable holder over the immutable `CircuitBreaker` (spec 035) with an
// injectable clock. Open guard → typed `circuit-open` call error WITHOUT
// invoking the wire (fail-fast errors never feed the breaker). Transport
// throws count as failures AND propagate so the spec 082 reconnect policy
// still sees drops. Timeouts surface as `timeout` call errors (see
// `McpCallOptions`).
//
// Also home to the per-call options (`McpCallOptions`) and the breaker/retry
// configs.

import 'dart:async';

import '../domain/entities/circuit_breaker/circuit_breaker.dart';
import 'mcp_call_result.dart';

/// Per-server breaker settings for an MCP client.
class McpBreakerConfig {
  /// Consecutive failures (call errors or transport throws) that open the
  /// breaker.
  final int failureThreshold;

  /// How long an open breaker stays open before the next call probes
  /// (half-open).
  final Duration cooldown;

  const McpBreakerConfig({
    this.failureThreshold = 5,
    this.cooldown = const Duration(seconds: 30),
  });
}

/// Opt-in retry settings for read-only tool calls.
class McpRetryConfig {
  /// Total attempts per call (1 = no retry).
  final int maxAttempts;

  /// Delay before each retry (injected delay functions keep tests
  /// hermetic).
  final Duration backoff;

  const McpRetryConfig({
    this.maxAttempts = 3,
    this.backoff = const Duration(milliseconds: 100),
  });
}

/// Per-call options for `McpClient.callTool`.
class McpCallOptions {
  /// The call timeout. `null` means the [defaultTimeout] (30s) applies.
  final Duration? timeout;

  /// Mark the call read-only — required for retry eligibility.
  final bool readOnly;

  /// Opt-in retry settings; `null` = never retry.
  final McpRetryConfig? retry;

  static const Duration defaultTimeout = Duration(seconds: 30);

  const McpCallOptions({this.timeout, this.readOnly = false, this.retry});

  /// The effective timeout for a call with these options.
  Duration get effectiveTimeout => timeout ?? defaultTimeout;
}

/// Call error codes this stack treats as transient (retry-eligible for
/// read-only calls).
const transientCallCodes = <String>{
  'transport-error',
  'unavailable',
  'server-error',
};

/// Per-server breaker holder over the immutable [CircuitBreaker].
class McpCallGuard {
  final McpBreakerConfig config;
  final DateTime Function() _now;
  CircuitBreaker _breaker;

  McpCallGuard({
    McpBreakerConfig config = const McpBreakerConfig(),
    DateTime Function()? now,
  }) : config = config,
       _now = now ?? DateTime.now,
       _breaker = CircuitBreaker(
         id: 'mcp-call-guard',
         failureThreshold: config.failureThreshold,
         cooldown: config.cooldown,
         halfOpenThreshold: 1,
       );

  CircuitBreakerState get state => _breaker.state;
  bool get isOpen => _breaker.isOpen;
  bool get isClosed => _breaker.isClosed;

  /// Runs [action] under the breaker:
  /// - open (cooldown elapsed) → probe via `tryHalfOpen`;
  /// - open (cooldown not elapsed) → typed `circuit-open` error WITHOUT
  ///   invoking [action];
  /// - success → `recordSuccess`; call error → `recordFailure`; thrown →
  ///   `recordFailure` + rethrow (spec 082 reconnect contract).
  Future<McpCallResult> call(Future<McpCallResult> Function() action) async {
    if (_breaker.shouldProbe(_now())) {
      _breaker = _breaker.tryHalfOpen(_now());
    }
    if (_breaker.isOpen) {
      // Fail fast — and deliberately NOT a breaker observation: the
      // short-circuit itself must not churn the state.
      return const McpCallError(
        code: 'circuit-open',
        message:
            'McpCallGuard: the circuit is open (server failing); '
            'retry after the cooldown',
      );
    }
    try {
      final result = await action();
      if (result is McpCallOk) {
        _breaker = _breaker.recordSuccess();
      } else {
        _breaker = _breaker.recordFailure(at: _now());
      }
      return result;
    } on Object {
      _breaker = _breaker.recordFailure(at: _now());
      rethrow;
    }
  }
}
