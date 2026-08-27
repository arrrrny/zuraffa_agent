// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.
//
// STUB replaced by implementation in the U1 green step.

import '../types.dart';

/// Deep list equality for value semantics (no package:collection dependency).
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Deep map equality for value semantics.
bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

/// Provider-agnostic LLM client contract (spec 007 FR-001).
abstract interface class LlmClient {
  String get providerName;
  String get model;
  Future<LlmResponse> generate(LlmRequest request);
  Stream<LlmResponseChunk> stream(LlmRequest request);
  Future<void> close();
}

/// A tool definition advertised to the model.
class LlmToolSpec {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const LlmToolSpec({
    required this.name,
    this.description = '',
    this.parameters = const {},
  });
}

/// A provider-agnostic completion request.
class LlmRequest {
  final String? systemPrompt;
  final List<AgentMessage> messages;
  final List<LlmToolSpec>? tools;
  final double? temperature;
  final int? maxTokens;
  final String? toolChoice;
  final bool? parallelToolCalls;

  const LlmRequest({
    this.systemPrompt,
    required this.messages,
    this.tools,
    this.temperature,
    this.maxTokens,
    this.toolChoice,
    this.parallelToolCalls,
  });
}

/// Usage accounting (spec 007 FR-005).
class LlmUsage {
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;
  final int thoughtTokens;

  const LlmUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedTokens = 0,
    this.thoughtTokens = 0,
  });

  LlmUsage copyWith({
    int? inputTokens,
    int? outputTokens,
    int? cachedTokens,
    int? thoughtTokens,
  }) {
    return LlmUsage(
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cachedTokens: cachedTokens ?? this.cachedTokens,
      thoughtTokens: thoughtTokens ?? this.thoughtTokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmUsage &&
          runtimeType == other.runtimeType &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          cachedTokens == other.cachedTokens &&
          thoughtTokens == other.thoughtTokens;

  @override
  int get hashCode =>
      Object.hash(inputTokens, outputTokens, cachedTokens, thoughtTokens);

  @override
  String toString() =>
      'LlmUsage(input: $inputTokens, output: $outputTokens, cached: '
      '$cachedTokens, thought: $thoughtTokens)';
}

/// An assembled tool invocation.
class LlmToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const LlmToolCall({
    required this.id,
    required this.name,
    this.arguments = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmToolCall &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          _mapEquals(arguments, other.arguments);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(arguments.values));

  @override
  String toString() => 'LlmToolCall(id: $id, name: $name)';
}

/// A complete, non-streaming response.
class LlmResponse {
  final String content;
  final String? thinking;
  final List<LlmToolCall> toolCalls;
  final LlmUsage usage;
  final String finishReason;

  const LlmResponse({
    this.content = '',
    this.thinking,
    this.toolCalls = const [],
    this.usage = const LlmUsage(),
    this.finishReason = 'stop',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmResponse &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          thinking == other.thinking &&
          _listEquals(toolCalls, other.toolCalls) &&
          usage == other.usage &&
          finishReason == other.finishReason;

  @override
  int get hashCode =>
      Object.hash(content, thinking, Object.hashAll(toolCalls), usage,
          finishReason);

  @override
  String toString() =>
      'LlmResponse(content: ${content.length} chars, toolCalls: '
      '${toolCalls.length}, finishReason: $finishReason)';
}

/// One streaming delta.
class LlmResponseChunk {
  final String? content;
  final String? thinking;
  final List<LlmToolCall> toolCalls;
  final LlmUsage? usage;
  final bool isComplete;
  final String? finishReason;

  const LlmResponseChunk({
    this.content,
    this.thinking,
    this.toolCalls = const [],
    this.usage,
    this.isComplete = false,
    this.finishReason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmResponseChunk &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          thinking == other.thinking &&
          _listEquals(toolCalls, other.toolCalls) &&
          usage == other.usage &&
          isComplete == other.isComplete &&
          finishReason == other.finishReason;

  @override
  int get hashCode => Object.hash(
      content,
      thinking,
      Object.hashAll(toolCalls),
      usage,
      isComplete,
      finishReason);

  @override
  String toString() =>
      'LlmResponseChunk(content: ${content == null ? "null" : content!.length} '
      'chars, complete: $isComplete)';
}

/// Typed error for a non-2xx provider response (spec 007 AC-3): carries the
/// provider label, HTTP status code, response body, and response headers.
class LlmHttpException implements Exception {
  final String provider;
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  const LlmHttpException({
    required this.provider,
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  @override
  @override
  String toString() =>
      'LlmHttpException: $provider returned HTTP $statusCode: $body';
}

/// Connection-level failure (no HTTP status arrived) — retryable class.
class LlmNetworkException implements Exception {
  final String provider;
  final Object cause;

  const LlmNetworkException({required this.provider, required this.cause});

  @override
  String toString() => 'LlmNetworkException: $provider: $cause';
}
