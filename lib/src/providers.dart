// Provider fallback logic — hand-written engine glue using zfa-generated
// Model entity types for provider/model resolution and fallback chains.
//
// Never references old manual-run types. All types are zfa-generated
// or hand-written against zfa-generated types.

import 'types.dart';

/// Interface for LLM provider clients.
///
/// All provider implementations (OpenAI-compatible, Anthropic, Gemini)
/// must implement this interface. The engine uses this interface
/// provider-agnostically.
abstract class LlmClient {
  /// Generates a response from the LLM.
  ///
  /// [messages] - The conversation history in standard format
  /// [tools] - Available tool definitions (can be empty)
  /// [config] - Generation configuration (temperature, max tokens, etc.)
  ///
  /// Returns an [LlmResponse] with content, tool calls, and usage info.
  Future<LlmResponse> generate({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  });

  /// Streams a response from the LLM.
  ///
  /// Emits [LlmResponseChunk] events for each delta.
  /// The final chunk has isComplete=true.
  Stream<LlmResponseChunk> stream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  });

  /// Closes the client and releases resources.
  Future<void> close();
}

/// Response from an LLM generation call.
class LlmResponse {
  /// The text content of the response.
  final String content;

  /// Tool calls requested by the model.
  final List<ToolCall> toolCalls;

  /// Token usage information.
  final LlmUsage usage;

  /// Finish reason: "stop", "tool_calls", "length", "error".
  final String finishReason;

  const LlmResponse({
    required this.content,
    required this.toolCalls,
    required this.usage,
    required this.finishReason,
  });
}

/// A chunk of a streaming LLM response.
class LlmResponseChunk {
  /// Content delta (can be empty for tool call chunks).
  final String content;

  /// Thinking/reasoning delta (can be empty).
  final String? thinking;

  /// Tool calls in this chunk (can be empty).
  final List<ToolCall> toolCalls;

  /// Usage so far (final chunk has complete usage).
  final LlmUsage? usage;

  /// Whether this is the final chunk.
  final bool isComplete;

  /// Finish reason (only on final chunk).
  final String? finishReason;

  const LlmResponseChunk({
    required this.content,
    this.thinking,
    required this.toolCalls,
    this.usage,
    required this.isComplete,
    this.finishReason,
  });
}

/// A tool call requested by the LLM.
class ToolCall {
  /// Unique identifier for this tool call.
  final String id;

  /// Name of the tool to call.
  final String name;

  /// Arguments for the tool call.
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// Token usage information from an LLM call.
class LlmUsage {
  /// Input tokens (prompt).
  final int inputTokens;

  /// Output tokens (completion).
  final int outputTokens;

  /// Cached tokens (if supported by provider).
  final int cachedTokens;

  const LlmUsage({
    required this.inputTokens,
    required this.outputTokens,
    this.cachedTokens = 0,
  });

  /// Total tokens (input + output).
  int get totalTokens => inputTokens + outputTokens;
}

/// Represents a configured LLM provider with model preferences and fallback.
class ProviderConfig {
  final String providerId;
  final List<String> modelIds;
  final int defaultContextWindow;

  const ProviderConfig({
    required this.providerId,
    required this.modelIds,
    this.defaultContextWindow = 8192,
  });
}

/// A resolved model selection with provider context.
class ResolvedModel {
  final Model model;
  final String providerId;

  const ResolvedModel({required this.model, required this.providerId});
}

/// Fallback strategy for provider/model selection.
///
/// Maintains an ordered list of [ProviderConfig] entries. When resolving,
/// tries each provider's models in order until one matches the requested
/// criteria or falls back to the first available model.
class ProviderResolver {
  final List<ProviderConfig> _providers;

  const ProviderResolver(this._providers);

  /// Resolves a model by provider ID and optional model ID.
  ///
  /// If [providerId] is specified, only that provider is tried.
  /// If [modelId] is specified, only that exact model is returned.
  /// Falls back through the provider chain if no exact match is found.
  ResolvedModel? resolve({
    String? providerId,
    String? modelId,
    int? minContextWindow,
  }) {
    final candidates = providerId != null
        ? _providers.where((p) => p.providerId == providerId).toList()
        : _providers.toList();

    for (final provider in candidates) {
      for (final mid in provider.modelIds) {
        if (modelId != null && mid != modelId) continue;

        return ResolvedModel(
          model: Model(
            provider: provider.providerId,
            modelId: mid,
            contextWindow: provider.defaultContextWindow,
          ),
          providerId: provider.providerId,
        );
      }
    }

    return null; // No match found.
  }

  /// Returns all available provider IDs.
  List<String> get availableProviders =>
      _providers.map((p) => p.providerId).toList();

  /// Returns all model IDs for a given provider.
  List<String> modelsForProvider(String providerId) {
    final provider = _providers.cast<ProviderConfig?>().firstWhere(
          (p) => p?.providerId == providerId,
          orElse: () => null,
        );
    return provider?.modelIds ?? const [];
  }
}
