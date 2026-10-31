part of 'engine_event.dart';

/// Emitted by the engine loop on every assistant content-text delta chunk
/// from the provider while a streaming turn is in flight (issue #123).
/// Streamed; not persisted. The transcript and MissionCompleted.summary
/// still carry the assembled text — this event is the live cursor.
final class ContentDelta extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String delta;

  const ContentDelta({required this.emittedAt, required this.delta});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentDelta &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          delta == other.delta);

  @override
  int get hashCode => Object.hash(emittedAt, delta);

  @override
  String toString() => 'ContentDelta(emittedAt: $emittedAt, delta: $delta)';
}
