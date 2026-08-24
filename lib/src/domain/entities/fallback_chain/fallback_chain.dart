// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// FallbackChain (advance policy + state) value object - spec-exact from epic #1 §R4 (issue #5).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// FallbackChain (advance policy + state) value object.
///
/// Fallback chain — advances on connection/timeout/5xx/context-overflow/repeated-429 with per-provider circuit breaker (epic #4 §R4.4, issue #5 US3). Tracks current provider, last error class, advance history.
class FallbackChain {
  final String id;
  final List<String> providerIds;
  final int currentProviderIndex;
  final int advances;
  final String? lastErrorClass;

  const FallbackChain({
    required this.id,
    required this.providerIds,
    required this.currentProviderIndex,
    required this.advances,
    this.lastErrorClass,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FallbackChain &&
          runtimeType == other.runtimeType && id == other.id && providerIds == other.providerIds && currentProviderIndex == other.currentProviderIndex && advances == other.advances && lastErrorClass == other.lastErrorClass);

  @override
  int get hashCode => Object.hash(id, providerIds, currentProviderIndex, advances, lastErrorClass);

  @override
  String toString() =>
      'FallbackChain(id: $id, providerIds: $providerIds, currentProviderIndex: $currentProviderIndex)';
}
