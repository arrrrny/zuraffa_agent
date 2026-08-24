// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// HealthSnapshot (chain state) value object - spec-exact from epic #1 §R4 (issue #5).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// HealthSnapshot (chain state) value object.
///
/// Health snapshot API — exposes chain state per provider (open/closed/half-open) and last-success timestamp (epic #4 §R4.5, issue #5 US4). Used by ops dashboards and the engine's preflight check.
class HealthSnapshot {
  final String id;
  final String chainId;
  final int capturedAt;
  final int healthyProviders;
  final int trippedProviders;

  const HealthSnapshot({
    required this.id,
    required this.chainId,
    required this.capturedAt,
    required this.healthyProviders,
    required this.trippedProviders,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthSnapshot &&
          runtimeType == other.runtimeType && id == other.id && chainId == other.chainId && capturedAt == other.capturedAt && healthyProviders == other.healthyProviders && trippedProviders == other.trippedProviders);

  @override
  int get hashCode => Object.hash(id, chainId, capturedAt, healthyProviders, trippedProviders);

  @override
  String toString() =>
      'HealthSnapshot(id: $id, chainId: $chainId, capturedAt: $capturedAt)';
}
