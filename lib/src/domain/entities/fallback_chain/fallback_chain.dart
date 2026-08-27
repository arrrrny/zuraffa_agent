// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback) and
// specs/008-fallback-chain-runtime/spec.md (merged value object).
//
// FallbackChain (advance policy + state + chain configuration) value object.
// Evolved in spec 008 from the spec-053 five-field stub into a merged value
// object that also carries the runtime chain configuration
// (providerOrder/maxConsecutiveFailures/cooldownMs/policyMode/breakerStates/
// lastProviderIndex) pinned by test/domain/entities/fallback_chain_test.dart.
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.
//
// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII).

import '../client_health/client_health.dart';

/// Fallback chain — advances on connection/timeout/5xx/context-overflow/
/// repeated-429 with per-provider circuit breaker (spec 008 FR-001..FR-004).
/// Tracks current provider, last error class, advance history, and the chain
/// configuration consumed by the FallbackChainClient runtime.
class FallbackChain {
  static int _idSequence = 0;

  final String id;

  // --- spec-053 legacy field set (provider metadata view) ---
  final List<String> providerIds;
  final int currentProviderIndex;
  final int advances;
  final String? lastErrorClass;

  // --- spec-008 chain configuration field set ---
  final List<String> providerOrder;
  final int maxConsecutiveFailures;
  final int cooldownMs;
  final String policyMode;
  final List<ClientHealth> breakerStates;
  final int lastProviderIndex;

  FallbackChain({
    String? id,
    this.providerIds = const [],
    this.currentProviderIndex = 0,
    this.advances = 0,
    this.lastErrorClass,
    this.providerOrder = const [],
    this.maxConsecutiveFailures = 3,
    this.cooldownMs = 60000,
    this.policyMode = 'skip',
    this.breakerStates = const [],
    this.lastProviderIndex = 0,
  }) : id = id ?? _generateId();

  static String _generateId() {
    _idSequence += 1;
    return 'chain_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  FallbackChain copyWith({
    String? id,
    List<String>? providerIds,
    int? currentProviderIndex,
    int? advances,
    String? lastErrorClass,
    List<String>? providerOrder,
    int? maxConsecutiveFailures,
    int? cooldownMs,
    String? policyMode,
    List<ClientHealth>? breakerStates,
    int? lastProviderIndex,
  }) =>
      FallbackChain(
        id: id ?? this.id,
        providerIds: providerIds ?? this.providerIds,
        currentProviderIndex: currentProviderIndex ?? this.currentProviderIndex,
        advances: advances ?? this.advances,
        lastErrorClass: lastErrorClass ?? this.lastErrorClass,
        providerOrder: providerOrder ?? this.providerOrder,
        maxConsecutiveFailures:
            maxConsecutiveFailures ?? this.maxConsecutiveFailures,
        cooldownMs: cooldownMs ?? this.cooldownMs,
        policyMode: policyMode ?? this.policyMode,
        breakerStates: breakerStates ?? this.breakerStates,
        lastProviderIndex: lastProviderIndex ?? this.lastProviderIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerIds': providerIds,
        'currentProviderIndex': currentProviderIndex,
        'advances': advances,
        'lastErrorClass': lastErrorClass,
        'providerOrder': providerOrder,
        'maxConsecutiveFailures': maxConsecutiveFailures,
        'cooldownMs': cooldownMs,
        'policyMode': policyMode,
        'breakerStates': [for (final h in breakerStates) h.toJson()],
        'lastProviderIndex': lastProviderIndex,
      };

  factory FallbackChain.fromJson(Map<String, dynamic> json) => FallbackChain(
        id: json['id'] as String?,
        providerIds: (json['providerIds'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        currentProviderIndex:
            (json['currentProviderIndex'] as num?)?.toInt() ?? 0,
        advances: (json['advances'] as num?)?.toInt() ?? 0,
        lastErrorClass: json['lastErrorClass'] as String?,
        providerOrder: (json['providerOrder'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        maxConsecutiveFailures:
            (json['maxConsecutiveFailures'] as num?)?.toInt() ?? 3,
        cooldownMs: (json['cooldownMs'] as num?)?.toInt() ?? 60000,
        policyMode: json['policyMode'] as String? ?? 'skip',
        breakerStates: (json['breakerStates'] as List?)
                ?.map((e) =>
                    ClientHealth.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        lastProviderIndex: (json['lastProviderIndex'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FallbackChain &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _listEquals(providerIds, other.providerIds) &&
          currentProviderIndex == other.currentProviderIndex &&
          advances == other.advances &&
          lastErrorClass == other.lastErrorClass &&
          _listEquals(providerOrder, other.providerOrder) &&
          maxConsecutiveFailures == other.maxConsecutiveFailures &&
          cooldownMs == other.cooldownMs &&
          policyMode == other.policyMode &&
          _listEquals(breakerStates, other.breakerStates) &&
          lastProviderIndex == other.lastProviderIndex;

  @override
  int get hashCode => Object.hash(
      id,
      Object.hashAll(providerIds),
      currentProviderIndex,
      advances,
      lastErrorClass,
      Object.hashAll(providerOrder),
      maxConsecutiveFailures,
      cooldownMs,
      policyMode,
      Object.hashAll(breakerStates),
      lastProviderIndex);

  @override
  String toString() =>
      'FallbackChain(id: $id, providerOrder: $providerOrder, policy: '
      '$policyMode, breakers: ${breakerStates.length})';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
