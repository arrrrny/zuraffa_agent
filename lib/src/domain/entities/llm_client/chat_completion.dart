// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// ChatCompletion value object - a parsed assistant response from an
// OpenAI-compatible gateway. Plain Dart, value equality, no @Zorphy codegen.

/// Token accounting for a single completion.
class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? json;
    return TokenUsage(
      promptTokens: usage['prompt_tokens'] as int? ?? 0,
      completionTokens: usage['completion_tokens'] as int? ?? 0,
      totalTokens: usage['total_tokens'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TokenUsage &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens);

  @override
  int get hashCode => Object.hash(promptTokens, completionTokens, totalTokens);

  @override
  String toString() =>
      'TokenUsage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';
}

/// A parsed assistant completion returned by an LLM gateway.
class ChatCompletion {
  final String content;
  final String? reasoning;
  final String finishReason;
  final TokenUsage usage;

  const ChatCompletion({
    required this.content,
    this.reasoning,
    required this.finishReason,
    required this.usage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatCompletion &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          reasoning == other.reasoning &&
          finishReason == other.finishReason &&
          usage == other.usage);

  @override
  int get hashCode => Object.hash(content, reasoning, finishReason, usage);

  @override
  String toString() =>
      'ChatCompletion(finish: $finishReason, usage: $usage, content: "${content.length > 24 ? "${content.substring(0, 24)}…" : content}")';
}
