part of 'engine_event.dart';

/// Emitted by the tool dispatch layer when a tool implementation returns (success or error). Pairs with ToolCallStarted (issue #22). Correlated via callId.
final class ToolCallCompleted extends EngineEvent {
  @override
  final DateTime emittedAt;
  final String toolName;
  final String callId;
  final bool ok;

  const ToolCallCompleted({required this.emittedAt, required this.toolName, required this.callId, required this.ok});
}
