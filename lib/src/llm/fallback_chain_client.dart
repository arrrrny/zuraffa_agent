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
    Object? lastError;
    for (final p in providers) {
      final breaker = _breakers[p.id]!;
      try {
        final response = await p.client.generate(request);
        breaker.recordSuccess();
        return response;
      } catch (error) {
        breaker.recordFailure();
        if (error is LlmNetworkException) {
          lastError = error;
          continue; // Advance to the next provider.
        }
        rethrow; // Non-advance errors fail fast.
      }
    }
    throw lastError ?? StateError('fallback chain is empty');
  }

  @override
  Stream<LlmResponseChunk> stream(LlmRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {
    for (final p in providers) {
      await p.client.close();
    }
  }

  Map<String, ClientHealth> healthSnapshot() => throw UnimplementedError();
}
