part of 'engine_event.dart';

/// Emitted by the engine loop when a turn finishes.
///
/// `reason` is `null` on a normal completion; set to a short string
/// (`cancelled`, `max-tokens-reached`, `tool-error-limit`, etc.) when the
/// turn terminated early.
final class TurnCompleted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String? reason;

  const TurnCompleted({required this.emittedAt, this.reason});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnCompleted &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          reason == other.reason);

  @override
  int get hashCode => Object.hash(emittedAt, reason);

  @override
  String toString() => 'TurnCompleted(emittedAt: $emittedAt, reason: $reason)';
}
