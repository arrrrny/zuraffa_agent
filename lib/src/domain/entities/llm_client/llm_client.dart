// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// LlmClient interface + LlmRequest/LlmResponse value object - spec-exact from epic #1 §R4 (issue #5).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// LlmClient interface + LlmRequest/LlmResponse value object.
///
/// Provider-agnostic LlmClient interface + typed LlmRequest/LlmResponse value objects (epic #4 §R4.1, issue #5 US1). All OpenAI/Anthropic/Gemini clients implement this; the engine consumes one type.
class LlmClient {
  final String id;
  final String providerName;
  final String model;
  final bool supportsStreaming;
  final bool supportsThinking;

  const LlmClient({
    required this.id,
    required this.providerName,
    required this.model,
    required this.supportsStreaming,
    required this.supportsThinking,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LlmClient &&
          runtimeType == other.runtimeType && id == other.id && providerName == other.providerName && model == other.model && supportsStreaming == other.supportsStreaming && supportsThinking == other.supportsThinking);

  @override
  int get hashCode => Object.hash(id, providerName, model, supportsStreaming, supportsThinking);

  @override
  String toString() =>
      'LlmClient(id: $id, providerName: $providerName, model: $model)';
}
