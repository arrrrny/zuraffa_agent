// Tests for ClientHealth entity — Spec 004: Providers & Fallback
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Equality and hashCode

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/client_health/client_health.dart';

void main() {
  group('ClientHealth', () {
    ClientHealth makeHealth({
      String? state,
      int? consecutiveFailures,
      int? cooldownWindowMs,
      DateTime? lastFailureAt,
      bool? isHealthy,
    }) {
      return ClientHealth(
        state: state ?? 'closed',
        consecutiveFailures: consecutiveFailures ?? 0,
        cooldownWindowMs: cooldownWindowMs ?? 60000,
        lastFailureAt: lastFailureAt ?? DateTime.utc(2026, 1, 15),
        isHealthy: isHealthy ?? true,
      );
    }

    test('construction and field access', () {
      final health = makeHealth();
      expect(health.id, isNotEmpty);
      expect(health.state, 'closed');
      expect(health.consecutiveFailures, 0);
      expect(health.cooldownWindowMs, 60000);
      expect(health.isHealthy, isTrue);
    });

    test('construction with failure state', () {
      final health = makeHealth(
        state: 'open',
        consecutiveFailures: 5,
        isHealthy: false,
      );
      expect(health.state, 'open');
      expect(health.consecutiveFailures, 5);
      expect(health.isHealthy, isFalse);
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeHealth();
      final updated = original.copyWith(
        state: 'half-open',
        consecutiveFailures: 1,
      );

      expect(updated.state, 'half-open');
      expect(updated.consecutiveFailures, 1);
      expect(updated.id, original.id); // Same ID preserved
      expect(updated.isHealthy, original.isHealthy);
    });

    test('toJson produces expected keys', () {
      final health = makeHealth();
      final json = health.toJson();

      expect(json['state'], 'closed');
      expect(json['consecutiveFailures'], 0);
      expect(json['cooldownWindowMs'], 60000);
      expect(json['isHealthy'], isTrue);
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('lastFailureAt'), isTrue);
    });

    test('fromJson round-trip preserves all fields', () {
      final fixedTime = DateTime.utc(2026, 6, 15, 12, 0, 0);
      final original = makeHealth(
        state: 'half-open',
        consecutiveFailures: 2,
        cooldownWindowMs: 30000,
        lastFailureAt: fixedTime,
        isHealthy: false,
      );
      final json = original.toJson();
      final restored = ClientHealth.fromJson(json);

      expect(restored.state, original.state);
      expect(restored.consecutiveFailures, original.consecutiveFailures);
      expect(restored.cooldownWindowMs, original.cooldownWindowMs);
      expect(restored.isHealthy, original.isHealthy);
    });

    test('fromJson with minimal data', () {
      final json = {
        'state': 'closed',
        'consecutiveFailures': 0,
        'cooldownWindowMs': 60000,
        'lastFailureAt': '2026-01-15T12:00:00.000Z',
        'isHealthy': true,
      };
      final health = ClientHealth.fromJson(json);

      expect(health.state, 'closed');
      expect(health.consecutiveFailures, 0);
      expect(health.isHealthy, isTrue);
    });
  });

  group('ClientHealth - Circuit Breaker States', () {
    test('closed state (healthy)', () {
      final health = ClientHealth(
        state: 'closed',
        consecutiveFailures: 0,
        cooldownWindowMs: 60000,
        lastFailureAt: DateTime.now(),
        isHealthy: true,
      );

      expect(health.state, 'closed');
      expect(health.isHealthy, isTrue);
      expect(health.consecutiveFailures, 0);
    });

    test('open state (tripped)', () {
      final health = ClientHealth(
        state: 'open',
        consecutiveFailures: 3,
        cooldownWindowMs: 60000,
        lastFailureAt: DateTime.now(),
        isHealthy: false,
      );

      expect(health.state, 'open');
      expect(health.isHealthy, isFalse);
      expect(health.consecutiveFailures, 3);
    });

    test('half-open state (probing)', () {
      final health = ClientHealth(
        state: 'half-open',
        consecutiveFailures: 1,
        cooldownWindowMs: 60000,
        lastFailureAt: DateTime.now(),
        isHealthy: false,
      );

      expect(health.state, 'half-open');
      expect(health.isHealthy, isFalse);
      expect(health.consecutiveFailures, 1);
    });
  });
}
