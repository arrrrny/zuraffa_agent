part of 'engine_event.dart';

/// Published by [EngineEventBus] onto itself when a subscriber throws
/// (spec 113, issue #134): the bus's self-observation surface. Carries
/// the thrown error and the source event's runtime type — never the
/// source event itself, so error events cannot leak payloads or
/// cascade.
final class EngineEventSubscriberError extends EngineEvent {
  @override
  final DateTime emittedAt;
  final Object error;

  /// The runtime type of the event whose delivery failed.
  final Type eventType;

  const EngineEventSubscriberError({
    required this.emittedAt,
    required this.error,
    required this.eventType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EngineEventSubscriberError &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          error == other.error &&
          eventType == other.eventType);

  @override
  int get hashCode => Object.hash(emittedAt, error, eventType);

  @override
  String toString() =>
      'EngineEventSubscriberError(emittedAt: $emittedAt, eventType: '
      '$eventType, error: $error)';
}
