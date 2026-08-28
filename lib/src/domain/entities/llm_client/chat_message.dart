// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#5 (R4 - providers & fallback).
//
// ChatMessage value object - one turn of a chat-completion request.
// Plain Dart, value equality, no @Zorphy codegen (matches the LlmClient
// and ProviderConfig hand-curated value objects for issue #5).

/// A single chat message sent to / received from an LLM gateway.
class ChatMessage {
  final String role;
  final String content;

  /// The assistant's thinking/reasoning block for this message, when the
  /// provider produced one.
  ///
  /// Spec 002 FR-002: assistant messages carry thinking blocks alongside tool
  /// calls and context assembly preserves them across turns, so a thinking
  /// model's reasoning is never silently stripped between turns. Null on every
  /// non-assistant message and on assistant turns with no reasoning.
  final String? thinking;

  const ChatMessage({
    required this.role,
    required this.content,
    this.thinking,
  });

  /// Wire form for the gateway request.
  ///
  /// `thinking` is emitted only when present, so a message without reasoning
  /// serializes byte-identically to how it did before the field existed.
  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (thinking != null) 'thinking': thinking,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          content == other.content &&
          thinking == other.thinking);

  @override
  int get hashCode => Object.hash(role, content, thinking);

  @override
  String toString() => 'ChatMessage(role: $role, content: "${content.length > 24 ? "${content.substring(0, 24)}…" : content}")';
}
