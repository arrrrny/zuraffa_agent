// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// ProviderConfig (typed openai/anthropic/gemini) value object - spec-exact from epic #1 §R4 (issue #5).
// Pattern mirrors the SteeringMessage / SteeringQueue value objects
// (PR for spec 033): plain Dart, value equality across all fields,
// no @Zorphy codegen, compiles without build_runner.

/// ProviderConfig (typed openai/anthropic/gemini) value object.
///
/// Typed provider configuration — base URL, API key reference, model list, timeouts (epic #4 §R4.1, issue #5 US1). Provider-specific subclasses carry vendor-only fields.
class ProviderConfig {
  final String id;
  final String providerKind;
  final String baseUrl;
  final List<String> models;
  final int timeoutMs;

  const ProviderConfig({
    required this.id,
    required this.providerKind,
    required this.baseUrl,
    required this.models,
    required this.timeoutMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          runtimeType == other.runtimeType && id == other.id && providerKind == other.providerKind && baseUrl == other.baseUrl && models == other.models && timeoutMs == other.timeoutMs);

  @override
  int get hashCode => Object.hash(id, providerKind, baseUrl, models, timeoutMs);

  @override
  String toString() =>
      'ProviderConfig(id: $id, providerKind: $providerKind, baseUrl: $baseUrl)';
}
