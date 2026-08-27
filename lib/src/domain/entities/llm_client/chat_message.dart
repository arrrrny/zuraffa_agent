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

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          runtimeType == other.runtimeType &&
          role == other.role &&
          content == other.content);

  @override
  int get hashCode => Object.hash(role, content);

  @override
  String toString() => 'ChatMessage(role: $role, content: "${content.length > 24 ? "${content.substring(0, 24)}…" : content}")';
}
