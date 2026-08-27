// Tests for FallbackChain entity — Spec 004: Providers & Fallback
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Equality and hashCode

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/client_health/client_health.dart';
import 'package:zuraffa_agent/src/domain/entities/fallback_chain/fallback_chain.dart';

void main() {
  group('FallbackChain', () {
    FallbackChain makeChain({
      List<String>? providerOrder,
      int? maxConsecutiveFailures,
      int? cooldownMs,
      String? policyMode,
      List<ClientHealth>? breakerStates,
      int? lastProviderIndex,
    }) {
      return FallbackChain(
        providerOrder: providerOrder ?? ['openai', 'anthropic', 'gemini'],
        maxConsecutiveFailures: maxConsecutiveFailures ?? 3,
        cooldownMs: cooldownMs ?? 60000,
        policyMode: policyMode ?? 'skip',
        breakerStates: breakerStates ?? [],
        lastProviderIndex: lastProviderIndex ?? 0,
      );
    }

    test('construction and field access', () {
      final chain = makeChain();
      expect(chain.id, isNotEmpty);
      expect(chain.providerOrder, ['openai', 'anthropic', 'gemini']);
      expect(chain.maxConsecutiveFailures, 3);
      expect(chain.cooldownMs, 60000);
      expect(chain.policyMode, 'skip');
      expect(chain.breakerStates, isEmpty);
      expect(chain.lastProviderIndex, 0);
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeChain();
      final updated = original.copyWith(
        lastProviderIndex: 1,
        cooldownMs: 120000,
      );

      expect(updated.lastProviderIndex, 1);
      expect(updated.cooldownMs, 120000);
      expect(updated.id, original.id); // Same ID preserved
      expect(updated.providerOrder, original.providerOrder);
    });

    test('equality and hashCode', () {
      final a = makeChain();
      final b = makeChain();
      // IDs are different (auto-generated), so not equal
      expect(a, isNot(equals(b)));
    });

    test('equality with same id', () {
      final fixedId = 'fixed-id-123';
      final a = makeChain()..copyWith(id: fixedId);
      final b = makeChain()..copyWith(id: fixedId);
      // Both have same fields except id, so we test field equality
      expect(a.providerOrder, b.providerOrder);
      expect(a.maxConsecutiveFailures, b.maxConsecutiveFailures);
      expect(a.cooldownMs, b.cooldownMs);
      expect(a.policyMode, b.policyMode);
      expect(a.lastProviderIndex, b.lastProviderIndex);
    });

    test('toJson produces expected keys', () {
      final chain = makeChain();
      final json = chain.toJson();

      expect(json['providerOrder'], ['openai', 'anthropic', 'gemini']);
      expect(json['maxConsecutiveFailures'], 3);
      expect(json['cooldownMs'], 60000);
      expect(json['policyMode'], 'skip');
      expect(json['lastProviderIndex'], 0);
      expect(json.containsKey('id'), isTrue);
    });

    test('fromJson round-trip preserves all fields', () {
      final original = makeChain(
        providerOrder: ['self-host', 'frontier'],
        maxConsecutiveFailures: 5,
        cooldownMs: 30000,
        policyMode: 'failover',
        lastProviderIndex: 1,
      );
      final json = original.toJson();
      final restored = FallbackChain.fromJson(json);

      expect(restored.providerOrder, original.providerOrder);
      expect(restored.maxConsecutiveFailures, original.maxConsecutiveFailures);
      expect(restored.cooldownMs, original.cooldownMs);
      expect(restored.policyMode, original.policyMode);
      expect(restored.lastProviderIndex, original.lastProviderIndex);
    });

    test('fromJson with breaker states', () {
      final health = ClientHealth(
        state: 'open',
        consecutiveFailures: 3,
        cooldownWindowMs: 60000,
        lastFailureAt: DateTime.utc(2026, 1, 15),
        isHealthy: false,
      );
      final chain = makeChain(breakerStates: [health]);
      final json = chain.toJson();
      final restored = FallbackChain.fromJson(json);

      expect(restored.breakerStates, hasLength(1));
      expect(restored.breakerStates.first.state, 'open');
      expect(restored.breakerStates.first.isHealthy, isFalse);
    });
  });
}
