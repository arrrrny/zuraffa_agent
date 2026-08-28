part of 'engine_event.dart';

/// Emitted by the tool dispatch layer immediately before invoking a tool
/// implementation. Pairs with [ToolCallCompleted] (issue #21) — the engine
/// correlates the two via `callId`.
final class ToolCallStarted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String toolName;
  final String callId;

  const ToolCallStarted({
    required this.emittedAt,
    required this.toolName,
    required this.callId,
  });
}
