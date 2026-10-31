part of 'engine_event.dart';

/// Emitted when a provider call fails terminally (auth, rate-limit, network).
/// Pairs with the fallback chain (spec-004).
final class ProviderError extends EngineEvent {
  @override
  final DateTime emittedAt;

  /// The provider name.
  final String providerName;

  /// The error.
  final String error;

  /// Creates a provider error.
  const ProviderError({
    required this.emittedAt,
    required this.providerName,
    required this.error,
  });

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
      'ProviderError(emittedAt: $emittedAt, providerName: $providerName, '
      'error: $error)';
}
