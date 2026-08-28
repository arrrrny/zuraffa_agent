part of 'engine_event.dart';

/// Emitted when a provider call fails terminally (auth, rate-limit, network). Pairs with the fallback chain (spec-004).
final class ProviderError extends EngineEvent {
  final DateTime emittedAt;
  final String providerName;
  final String error;

  const ProviderError({required this.emittedAt, required this.providerName, required this.error});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderError &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          providerName == other.providerName &&
          error == other.error);

  @override
  int get hashCode => Object.hash(emittedAt, providerName, error);

  @override
  String toString() =>
      'ProviderError(emittedAt: $emittedAt, providerName: $providerName, error: $error)';
}
