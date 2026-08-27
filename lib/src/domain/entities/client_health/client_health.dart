// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See specs/008-fallback-chain-runtime/spec.md (US3) and the spec-004 lineage
// test test/domain/entities/client_health_test.dart (committed before this
// implementation — the test-first contract for this entity).
//
// ClientHealth value object - plain Dart, value equality across all fields,
// toJson/fromJson round-trip, no @Zorphy codegen, compiles without
// build_runner (pattern of specs 051/053/054).
//
// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII).

/// Health of one provider in the fallback chain: breaker state, consecutive
/// failures, cooldown window, and last failure time (spec 008 US3 / FR-005).
class ClientHealth {
  static int _idSequence = 0;

  final String id;
  final String state;
  final int consecutiveFailures;
  final int cooldownWindowMs;
  final DateTime lastFailureAt;
  final bool isHealthy;

  ClientHealth({
    String? id,
    this.state = 'closed',
    this.consecutiveFailures = 0,
    this.cooldownWindowMs = 60000,
    DateTime? lastFailureAt,
    this.isHealthy = true,
  })  : id = id ?? _generateId(),
        lastFailureAt = lastFailureAt ?? DateTime.utc(2026, 1, 15);

  static String _generateId() {
    _idSequence += 1;
    return 'health_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  ClientHealth copyWith({
    String? id,
    String? state,
    int? consecutiveFailures,
    int? cooldownWindowMs,
    DateTime? lastFailureAt,
    bool? isHealthy,
  }) =>
      ClientHealth(
        id: id ?? this.id,
        state: state ?? this.state,
        consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
        cooldownWindowMs: cooldownWindowMs ?? this.cooldownWindowMs,
        lastFailureAt: lastFailureAt ?? this.lastFailureAt,
        isHealthy: isHealthy ?? this.isHealthy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': state,
        'consecutiveFailures': consecutiveFailures,
        'cooldownWindowMs': cooldownWindowMs,
        'lastFailureAt': lastFailureAt.toIso8601String(),
        'isHealthy': isHealthy,
      };

  factory ClientHealth.fromJson(Map<String, dynamic> json) => ClientHealth(
        id: json['id'] as String?,
        state: json['state'] as String? ?? 'closed',
        consecutiveFailures:
            (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
        cooldownWindowMs: (json['cooldownWindowMs'] as num?)?.toInt() ?? 60000,
        lastFailureAt: json['lastFailureAt'] is String
            ? DateTime.parse(json['lastFailureAt'] as String)
            : null,
        isHealthy: json['isHealthy'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientHealth &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          state == other.state &&
          consecutiveFailures == other.consecutiveFailures &&
          cooldownWindowMs == other.cooldownWindowMs &&
          lastFailureAt == other.lastFailureAt &&
          isHealthy == other.isHealthy;

  @override
  int get hashCode =>
      Object.hash(id, state, consecutiveFailures, cooldownWindowMs,
          lastFailureAt, isHealthy);

  @override
  String toString() =>
      'ClientHealth(id: $id, state: $state, failures: $consecutiveFailures, '
      'healthy: $isHealthy)';
}
