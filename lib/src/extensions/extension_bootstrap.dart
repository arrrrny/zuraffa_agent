/// Composes installed [ZuraffaExtension]s into one [AgentExtensionHooks] value
/// (FR-009, contracts/governance-hooks.md).
///
/// Composition rules:
///  - Zero extensions -> all-null hooks; the runtime behaves exactly as pi.
///  - Hooks compose in installation order.
///  - A hook that returns a non-null result short-circuits the chain for that
///    hook (pi's own contract: a non-null `BeforeToolCallResult` replaces the
///    tool call).
library;

import 'package:pi/pi.dart';

import 'agent_extension_hooks.dart';
import 'zuraffa_extension.dart';

/// Builds the composed hook set from [extensions] in installation order.
class ExtensionBootstrap {
  const ExtensionBootstrap();

  /// Composes [extensions] into a single [AgentExtensionHooks].
  AgentExtensionHooks compose(List<ZuraffaExtension> extensions) {
    final before = _composeBefore(extensions);
    final after = _composeAfter(extensions);
    final transform = _composeTransform(extensions);
    final convert = _composeConvert(extensions);
    return AgentExtensionHooks(
      beforeToolCall: before,
      afterToolCall: after,
      transformContext: transform,
      convertToLlm: convert,
    );
  }

  BeforeToolCallHook? _composeBefore(List<ZuraffaExtension> extensions) {
    final hooks = extensions
        .map((e) => e.beforeToolCall)
        .whereType<BeforeToolCallHook>()
        .toList();
    if (hooks.isEmpty) return null;
    return (ctx, {isAborted}) async {
      for (final hook in hooks) {
        final result = await hook(ctx, isAborted: isAborted);
        if (result != null) return result; // non-null short-circuits (pi).
      }
      return null;
    };
  }

  AfterToolCallHook? _composeAfter(List<ZuraffaExtension> extensions) {
    final hooks = extensions
        .map((e) => e.afterToolCall)
        .whereType<AfterToolCallHook>()
        .toList();
    if (hooks.isEmpty) return null;
    return (ctx, {isAborted}) async {
      for (final hook in hooks) {
        final result = await hook(ctx, isAborted: isAborted);
        if (result != null) return result;
      }
      return null;
    };
  }

  Future<List<AgentMessage>> Function(
    List<AgentMessage>, {
    bool Function()? isAborted,
  })?
  _composeTransform(List<ZuraffaExtension> extensions) {
    final hooks = extensions
        .map((e) => e.transformContext)
        .whereType<
          Future<List<AgentMessage>> Function(
            List<AgentMessage>, {
            bool Function()? isAborted,
          })
        >()
        .toList();
    if (hooks.isEmpty) return null;
    return (messages, {isAborted}) async {
      var current = messages;
      for (final hook in hooks) {
        current = await hook(current, isAborted: isAborted);
      }
      return current;
    };
  }

  Future<List<Map<String, dynamic>>> Function(List<AgentMessage>)?
  _composeConvert(List<ZuraffaExtension> extensions) {
    // convertToLlm maps messages -> provider JSON; chaining its map output back
    // through another converter is not meaningful, so the first non-null hook
    // wins. (Governance PII scrubbing rides transformContext, not this seam.)
    for (final extension in extensions) {
      final hook = extension.convertToLlm;
      if (hook != null) return hook;
    }
    return null;
  }
}
