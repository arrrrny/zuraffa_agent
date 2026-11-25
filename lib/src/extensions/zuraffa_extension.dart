/// The one extension-installation seam (FR-009, data-model.md).
///
/// A [ZuraffaExtension] carries hook bodies, never policy. The bootstrap
/// composes the non-null hooks of every installed extension into the opened pi
/// runtime's `AgentOptions`. Governance policy (allowlists, argument guards,
/// risk tiers, minimization, PII scrubbing, audit) is issue #205 and arrives as
/// one such extension — this package defines none of it.
///
/// The function types are pi's own (`package:pi`); the wrapper aliases nothing.
library;

import 'package:pi/pi.dart';

/// A capability extension composed into pi's real hook surfaces.
///
/// Every field is nullable: an extension contributes only the hooks it needs.
class ZuraffaExtension {
  /// Stable extension identifier for diagnostics.
  final String id;

  /// Composed into `AgentOptions.beforeToolCall` (denial before execution).
  final BeforeToolCallHook? beforeToolCall;

  /// Composed into `AgentOptions.afterToolCall` (sees tool results).
  final AfterToolCallHook? afterToolCall;

  /// Composed into `AgentOptions.transformContext` (last touch before the
  /// provider call — where "the model never receives unredacted content" is
  /// actually enforceable).
  final Future<List<AgentMessage>> Function(
    List<AgentMessage>, {
    bool Function()? isAborted,
  })?
  transformContext;

  /// Composed into `AgentOptions.convertToLlm`.
  final Future<List<Map<String, dynamic>>> Function(List<AgentMessage>)?
  convertToLlm;

  const ZuraffaExtension({
    required this.id,
    this.beforeToolCall,
    this.afterToolCall,
    this.transformContext,
    this.convertToLlm,
  });
}
