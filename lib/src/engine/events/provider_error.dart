part of 'engine_event.dart';

/// Emitted when a provider call fails terminally (auth, rate-limit, network). Pairs with the fallback chain (spec-004).
final class ProviderError extends EngineEvent {
  final DateTime emittedAt;
  final String providerName;
  final String error;

  const ProviderError({required this.emittedAt, required this.providerName, required this.error});
}
