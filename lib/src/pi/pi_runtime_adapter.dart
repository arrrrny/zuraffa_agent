/// The only file that **constructs** pi's runtime (FR-005,
/// contracts/pi-runtime-adapter.md).
///
/// It builds pi's [Conversation] from the wrapper's config, ports, and composed
/// extension hooks, and absorbs construction/lifecycle drift in pi's API — a pi
/// signature change touches this adapter, not every host. It is **not** a type
/// boundary: the package returns and re-exports pi's own types; nothing here
/// aliases a pi type into a wrapper-owned one.
///
/// pi#12's durable surface (submissions, watches, tasks, outcomes, scheduler)
/// is absent from the published pi this builds against, so `open` returns
/// pi's [Conversation] and no durable verb is stubbed (FR-010).
library;

import 'package:pi/pi.dart';

import '../config/agent_port_registry.dart';
import '../domain/entities/agent_runtime_config/agent_runtime_config.dart';
import '../extensions/agent_extension_hooks.dart';

/// Builds and opens pi's runtime.
abstract class PiRuntimeAdapter {
  /// Opens pi's runtime and returns pi's own [Conversation].
  Future<Conversation> open(
    AgentRuntimeConfig config,
    AgentPortRegistry ports,
    AgentExtensionHooks hooks,
  );
}

/// The default [PiRuntimeAdapter], building a pi [Conversation] over the
/// injected storage and credentials and installing the composed hooks.
class DefaultPiRuntimeAdapter implements PiRuntimeAdapter {
  /// Context window (tokens) stamped onto the pi [Model]. The wrapper's config
  /// carries no context window (data-model.md), so the adapter picks pi's own
  /// default — a construction detail this boundary absorbs (FR-005).
  static const int defaultContextWindow = 128000;

  const DefaultPiRuntimeAdapter();

  @override
  Future<Conversation> open(
    AgentRuntimeConfig config,
    AgentPortRegistry ports,
    AgentExtensionHooks hooks,
  ) async {
    final storage = await ports.storage.open();
    final conversation = await Conversation.create(
      storage,
      model: Model(
        provider: config.modelProvider,
        modelId: config.modelId,
        contextWindow: defaultContextWindow,
      ),
      systemPrompt: config.systemPrompt,
      thinkingLevel: _parseThinkingLevel(config.thinkingLevel),
      getApiKey: ports.credentials.resolveApiKey,
    );

    // Conversation.create exposes convertToLlm/beforeToolCall/afterToolCall but
    // not transformContext; the Agent setters cover all four uniformly, so the
    // composed seam is installed through one code path.
    conversation.agent
      ..convertToLlm = hooks.convertToLlm
      ..transformContext = hooks.transformContext
      ..beforeToolCall = hooks.beforeToolCall
      ..afterToolCall = hooks.afterToolCall;

    return conversation;
  }

  ThinkingLevel? _parseThinkingLevel(String? name) {
    if (name == null) return null;
    for (final level in ThinkingLevel.values) {
      if (level.name == name) return level;
    }
    throw ArgumentError.value(
      name,
      'thinkingLevel',
      'unknown pi ThinkingLevel',
    );
  }
}
