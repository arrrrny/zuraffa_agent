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
  /// The provider name.
  String get providerName;

  /// The model.
  String get model;

  /// Generates the request.
  Future<LlmResponse> generate(LlmRequest request);

  /// Streams the request.
  Stream<LlmResponseChunk> stream(LlmRequest request);

  /// Closes the client and releases provider resources.
  Future<void> close();
}

/// A tool definition advertised to the model.
class LlmToolSpec {
  /// The name.
  final String name;

  /// The description.
  final String description;

  /// The parameters.
  final Map<String, dynamic> parameters;

  /// Creates an LLM tool spec.
  const LlmToolSpec({
    required this.name,
    this.description = '',
    this.parameters = const {},
  });
}

/// A provider-agnostic completion request.
class LlmRequest {
  /// The system prompt.
  final String? systemPrompt;

  /// The messages.
  final List<AgentMessage> messages;

  /// The tools.
  final List<LlmToolSpec>? tools;

  /// The temperature.
  final double? temperature;

  /// The max tokens.
  final int? maxTokens;

  /// The tool choice.
  final String? toolChoice;

  /// The parallel tool calls.
  final bool? parallelToolCalls;

  /// OpenAI-compatible `response_format` passthrough (e.g.
  /// `{'type': 'json_object'}` for JSON mode). Emitted verbatim into the
  /// request body when set; providers without support ignore it.
  final Map<String, dynamic>? responseFormat;

  /// Extra HTTP headers merged into every outbound request (issue #133,
  /// O-1). Intended for W3C trace-context propagation — build it from
  /// `Spans.propagationHeaders()` so the current span's `traceparent`
  /// reaches the model vendor's edge. Explicit request headers win over
  /// the client's defaults (they can override `authorization`).
  final Map<String, String> headers;

  /// Creates an LLM request.
  const LlmRequest({
    this.systemPrompt,
    required this.messages,
    this.tools,
    this.temperature,
    this.maxTokens,
    this.toolChoice,
    this.parallelToolCalls,
    this.responseFormat,
    this.headers = const {},
  });
}

/// Usage accounting (spec 007 FR-005).
class LlmUsage {
  /// The input tokens.
  final int inputTokens;

  /// The output tokens.
  final int outputTokens;

  /// The cached tokens.
  final int cachedTokens;

  /// The thought tokens.
  final int thoughtTokens;

  /// Creates an LLM usage.
  const LlmUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedTokens = 0,
    this.thoughtTokens = 0,
  });

  /// Returns a copy of this LLM usage with the given fields replaced.
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
  /// The identifier.
  final String id;

  /// The name.
  final String name;

  /// The arguments.
  final Map<String, dynamic> arguments;

  /// Creates an LLM tool call.
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
  /// The content.
  final String content;

  /// The thinking.
  final String? thinking;

  /// The tool calls.
  final List<LlmToolCall> toolCalls;

  /// The usage.
  final LlmUsage usage;

  /// The finish reason.
  final String finishReason;

  /// Creates an LLM response.
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
  int get hashCode => Object.hash(
    content,
    thinking,
    Object.hashAll(toolCalls),
    usage,
    finishReason,
  );

  @override
  String toString() =>
      'LlmResponse(content: ${content.length} chars, toolCalls: '
      '${toolCalls.length}, finishReason: $finishReason)';
}

/// One streaming delta.
class LlmResponseChunk {
  /// The content.
  final String? content;

  /// The thinking.
  final String? thinking;

  /// The tool calls.
  final List<LlmToolCall> toolCalls;

  /// The usage.
  final LlmUsage? usage;

  /// Whether complete.
  final bool isComplete;

  /// The finish reason.
  final String? finishReason;

  /// Creates an LLM response chunk.
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
    finishReason,
  );

  @override
  String toString() =>
      'LlmResponseChunk(content: ${content == null ? "null" : content!.length} '
      'chars, complete: $isComplete)';
}

/// Typed error for a non-2xx provider response (spec 007 AC-3): carries the
/// provider label, HTTP status code, response body, and response headers.
class LlmHttpException implements Exception {
  /// The provider.
  final String provider;

  /// The status code.
  final int statusCode;

  /// The body.
  final String body;

  /// The headers.
  final Map<String, String> headers;

  /// How many attempts were made when this error surfaced (spec 084
  /// FR-005). Defaults to 1 — single-shot constructions keep their
  /// meaning; the retry loop sets it to the attempt count on exhaustion
  /// so a blip (1) and an outage (maxAttempts) are distinguishable.
  final int attempts;

  /// Creates an LLM HTTP exception.
  const LlmHttpException({
    required this.provider,
    required this.statusCode,
    required this.body,
    this.headers = const {},
    this.attempts = 1,
  });

  @override
  String toString() => attempts > 1
      ? 'LlmHttpException: $provider returned HTTP $statusCode: $body '
            '(after $attempts attempts)'
      : 'LlmHttpException: $provider returned HTTP $statusCode: $body';
}

/// Connection-level failure (no HTTP status arrived) — retryable class.
class LlmNetworkException implements Exception {
  /// The provider.
  final String provider;

  /// The cause.
  final Object cause;

  /// How many attempts were made when this error surfaced (spec 084
  /// FR-005). Defaults to 1 outside the retry loop; the retry loop sets
  /// it on the terminal throw so exhaustion is visible without counting
  /// logs.
  final int attempts;

  /// Creates an LLM network exception.
  const LlmNetworkException({
    required this.provider,
    required this.cause,
    this.attempts = 1,
  });

  @override
  String toString() => attempts > 1
      ? 'LlmNetworkException: $provider: $cause (after $attempts attempts)'
      : 'LlmNetworkException: $provider: $cause';
}
