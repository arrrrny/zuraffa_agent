part of 'engine_event.dart';

/// Emitted by the tool dispatch layer immediately before invoking a tool
/// implementation. Pairs with [ToolCallCompleted] (issue #21) — the engine
/// correlates the two via `callId`.
final class ToolCallStarted extends EngineEvent {
  final DateTime emittedAt;
  final String toolName;
  final String callId;

  const ToolCallStarted({
    required this.emittedAt,
    required this.toolName,
    required this.callId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolCallStarted &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          toolName == other.toolName &&
          callId == other.callId);

  @override
  int get hashCode => Object.hash(emittedAt, toolName, callId);

  @override
  String toString() =>
      'ToolCallStarted(emittedAt: $emittedAt, toolName: $toolName, callId: $callId)';
}
