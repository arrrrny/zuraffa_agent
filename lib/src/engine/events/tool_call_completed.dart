part of 'engine_event.dart';

/// Emitted by the tool dispatch layer when a tool implementation returns (success or error). Pairs with ToolCallStarted (issue #22). Correlated via callId.
final class ToolCallCompleted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String toolName;
  final String callId;
  final bool ok;

  const ToolCallCompleted({required this.emittedAt, required this.toolName, required this.callId, required this.ok});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ToolCallCompleted &&
          runtimeType == other.runtimeType &&
          emittedAt == other.emittedAt &&
          toolName == other.toolName &&
          callId == other.callId &&
          ok == other.ok);

  @override
  int get hashCode => Object.hash(emittedAt, toolName, callId, ok);

  @override
  String toString() =>
      'ToolCallCompleted(emittedAt: $emittedAt, toolName: $toolName, callId: $callId, ok: $ok)';
}
