// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/008-fallback-chain-runtime/spec.md with this attribution retained.
//
// STUB (TDD red phase for U10) — failover runtime not implemented yet.

import 'circuit_breaker.dart';
import 'llm_client.dart';
import 'llm_clock.dart';
import '../domain/entities/client_health/client_health.dart';

/// One provider slot in the chain.
typedef FallbackProvider = ({String id, LlmClient client});

/// Thrown when every provider in the chain failed (or is gated open).
class LlmFallbackExhaustedException implements Exception {
  final Map<String, Object> errorsByProvider;

  LlmFallbackExhaustedException(this.errorsByProvider);

  @override
  String toString() =>
      'LlmFallbackExhaustedException: all providers failed '
      '(${errorsByProvider.keys.join(', ')})';
}

/// Ordered provider chain with automatic failover (spec 008 FR-001..FR-005).
class FallbackChainClient implements LlmClient {
  final List<FallbackProvider> providers;
  final String policyMode;
  final LlmClock clock;
  final Map<String, CircuitBreaker> _breakers = {};

  FallbackChainClient({
    required this.providers,
    this.policyMode = 'restart',
    int maxConsecutiveFailures = 3,
    int cooldownMs = 60000,
    required this.clock,
  }) {
    for (final p in providers) {
      _breakers[p.id] = CircuitBreaker(
        providerId: p.id,
        maxConsecutiveFailures: maxConsecutiveFailures,
        cooldownWindowMs: cooldownMs,
        clock: clock,
      );
    }
  }

  @override
  String get providerName => 'fallback-chain';

  @override
  String get model => providers.first.client.model;

  @override
  Future<LlmResponse> generate(LlmRequest request) async {
    final errors = <String, Object>{};
    for (final p in providers) {
      final breaker = _breakers[p.id]!;
      if (!breaker.attemptAllowed()) {
        errors[p.id] = StateError('circuit open');
        continue; // Open breaker: skip this provider entirely.
      }
      try {
        final response = await p.client.generate(request);
        breaker.recordSuccess();
        return response;
      } catch (error) {
        breaker.recordFailure();
        if (_shouldAdvance(error)) {
          errors[p.id] = error;
          continue; // Advance to the next provider.
        }
        rethrow; // Non-advance errors fail fast.
      }
    }
    throw LlmFallbackExhaustedException(errors);
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) async* {
    final errors = <String, Object>{};
    for (final p in providers) {
      final breaker = _breakers[p.id]!;
      if (!breaker.attemptAllowed()) {
        errors[p.id] = StateError('circuit open');
        continue;
      }
      var emitted = 0;
      try {
        await for (final chunk in p.client.stream(request)) {
          emitted += 1;
          yield chunk;
        }
        breaker.recordSuccess();
        return; // Stream completed on this provider.
      } catch (error) {
        breaker.recordFailure();
        if (!_shouldAdvance(error)) rethrow;
        if (emitted > 0 && policyMode == 'skip') {
          // Configurable mid-stream policy (FR-004): skip propagates the
          // error after the partial chunks instead of restarting.
          rethrow;
        }
        // Default restart policy: mid-stream failures restart on the next
        // provider; the consumer keeps the partial chunks and receives a
        // complete stream — never silent truncation.
        errors[p.id] = error;
      }
    }
    throw LlmFallbackExhaustedException(errors);
  }

  @override
  Future<void> close() async {
    for (final p in providers) {
      await p.client.close();
    }
  }

  /// Live health snapshot (spec 008 FR-005 / US3): one [ClientHealth] per
  /// provider, reflecting breaker states at the moment of the call.
  Map<String, ClientHealth> healthSnapshot() => {
        for (final p in providers) p.id: _breakers[p.id]!.health(),
      };

  /// Context-overflow detection: a 400 whose body indicates the request
  /// exceeded the model's context window — a smaller/other model may fit.
  static final RegExp _contextOverflowPattern = RegExp(
      r'context length|context_window|maximum context|too long|too many tokens',
      caseSensitive: false);

  static bool _isContextOverflow(LlmHttpException error) {
    if (error.statusCode != 400 && error.statusCode != 413) return false;
    return _contextOverflowPattern.hasMatch(error.body);
  }

  /// Advance-class errors (spec 008 FR-003): connection/timeout
  /// ([LlmNetworkException]), 5xx, a 429 that exhausted the client's retry
  /// budget, and context overflow. Other 4xx (auth, bad request) fail fast.
  static bool _shouldAdvance(Object error) {
    if (error is LlmNetworkException) return true;
    if (error is LlmHttpException) {
      if (error.statusCode >= 500) return true;
      if (error.statusCode == 429) return true;
      if (_isContextOverflow(error)) return true;
      return false;
    }
    return false;
  }
}
