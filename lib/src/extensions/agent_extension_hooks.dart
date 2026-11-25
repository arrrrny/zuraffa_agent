/// The bootstrap's output: the four composed, nullable pi hooks (FR-009).
///
/// Each field is handed straight to pi's `AgentOptions` by the runtime adapter;
/// the bootstrap composes, the adapter does not decide. With no extension
/// installed every field is `null` and the runtime behaves exactly as pi does.
library;

import 'package:pi/pi.dart';

/// The composed hook set installed into the opened pi runtime.
class AgentExtensionHooks {
  final BeforeToolCallHook? beforeToolCall;
  final AfterToolCallHook? afterToolCall;
  final Future<List<AgentMessage>> Function(
    List<AgentMessage>, {
    bool Function()? isAborted,
  })?
  transformContext;
  final Future<List<Map<String, dynamic>>> Function(List<AgentMessage>)?
  convertToLlm;

  const AgentExtensionHooks({
    this.beforeToolCall,
    this.afterToolCall,
    this.transformContext,
    this.convertToLlm,
  });

  /// The all-null hook set — what the bootstrap yields for zero extensions.
  static const none = AgentExtensionHooks();

  /// Whether every hook is null (the wrapper contributed nothing).
  bool get isEmpty =>
      beforeToolCall == null &&
      afterToolCall == null &&
      transformContext == null &&
      convertToLlm == null;
}
