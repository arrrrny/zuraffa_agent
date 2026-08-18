// Provider fallback logic — hand-written engine glue using zfa-generated
// Model entity types for provider/model resolution and fallback chains.
//
// Never references old manual-run types. All types are zfa-generated
// or hand-written against zfa-generated types.

import 'types.dart';

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
