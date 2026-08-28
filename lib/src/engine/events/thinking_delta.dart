part of 'engine_event.dart';

/// Emitted by the engine loop on every thinking-text delta chunk from the provider. Streamed; not persisted.
final class ThinkingDelta extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String delta;

  const ThinkingDelta({required this.emittedAt, required this.delta});
}
