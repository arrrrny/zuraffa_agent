part of 'engine_event.dart';

/// Emitted by the engine loop on every thinking-text delta chunk from the provider. Streamed; not persisted.
final class ThinkingDelta extends EngineEvent {
  final DateTime emittedAt;
  final String delta;

  const ThinkingDelta({required this.emittedAt, required this.delta});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThinkingDelta &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          delta == other.delta);

  @override
  int get hashCode => Object.hash(emittedAt, delta);

  @override
  String toString() => 'ThinkingDelta(emittedAt: $emittedAt, delta: $delta)';
}
