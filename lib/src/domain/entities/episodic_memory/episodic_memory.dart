// HAND-CURATED - DO NOT REGENERATE VIA zfa.
// See specs/009-context-compression-llm/spec.md (US2) and the hand-curated
// conversational-model precedent: agent_message.dart, llm_client.dart,
// fallback_chain.dart ("plain Dart, value equality, no @Zorphy codegen,
// compiles without build_runner"). EpisodicMemory embeds List<AgentMessage>
// from lib/src/types.dart (the hand-curated conversational model), so a
// Zorphy wrapper would need custom converters for a non-Zorphy type; the
// documented precedent applies instead.
//
// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII).

import '../../../types.dart';

/// A compressed slice of conversation history: the XML snapshot that replaced
/// it plus the original messages (spec 009 FR-003 / US2).
class EpisodicMemory {
  final String id;
  final String summary;
  final List<AgentMessage> messages;

  const EpisodicMemory({
    required this.id,
    required this.summary,
    this.messages = const [],
  });

  EpisodicMemory copyWith({
    String? id,
    String? summary,
    List<AgentMessage>? messages,
  }) =>
      EpisodicMemory(
        id: id ?? this.id,
        summary: summary ?? this.summary,
        messages: messages ?? this.messages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'summary': summary,
        'messages': [for (final m in messages) m.toJson()],
      };

  factory EpisodicMemory.fromJson(Map<String, dynamic> json) => EpisodicMemory(
        id: json['id'] as String,
        summary: json['summary'] as String,
        messages: [
          for (final m in (json['messages'] as List? ?? const []))
            AgentMessage.fromJson(Map<String, dynamic>.from(m as Map)),
        ],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodicMemory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          summary == other.summary &&
          _listEquals(messages, other.messages);

  @override
  int get hashCode => Object.hash(id, summary, Object.hashAll(messages));

  @override
  String toString() =>
      'EpisodicMemory(id: $id, messages: ${messages.length}, '
      'summary: ${summary.length} chars)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
