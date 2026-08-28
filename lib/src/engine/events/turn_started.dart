part of 'engine_event.dart';

/// Emitted by the engine loop at the start of every turn.
///
/// Fields:
/// - `emittedAt`: when the engine began processing this turn.
/// - `turnId`: optional id of the turn record this event opened; `null` for
///   ephemeral turns (e.g. internal retries) that never persist.
final class TurnStarted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String? turnId;

  const TurnStarted({required this.emittedAt, this.turnId});
}
