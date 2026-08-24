part of 'engine_event.dart';

/// Emitted by the engine loop when a turn finishes.
///
/// `reason` is `null` on a normal completion; set to a short string
/// (`cancelled`, `max-tokens-reached`, `tool-error-limit`, etc.) when the
/// turn terminated early.
final class TurnCompleted extends EngineEvent {
  final DateTime emittedAt;
  final String? reason;

  const TurnCompleted({required this.emittedAt, this.reason});
}
