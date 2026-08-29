// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/010-episodic-memory/spec.md with this attribution retained.

import '../types.dart';
import '../domain/entities/episodic_memory/episodic_memory.dart';

/// The conversation context the engine assembles for the model: the active
/// [messages] plus the [episodicMemories] created by earlier compressions
/// (spec 010 US1 AC2 / FR — "memory summaries are available for retrieval").
///
/// Spec 002's engine-loop integration consumes this value object when it
/// builds the model prompt; the summaries are surfaced without the original
/// messages so the active context stays small — the full originals are one
/// `retrieve_memory` call away (see RetrieveMemoryTool).
class AgentMessageHistory {
  /// Active (uncompressed) conversation messages, oldest first.
  final List<AgentMessage> messages;

  /// Episodic memories from earlier compressions, in insertion order
  /// (oldest first).
  final List<EpisodicMemory> episodicMemories;

  const AgentMessageHistory({
    this.messages = const [],
    this.episodicMemories = const [],
  });

  /// Memory summaries in insertion order — the compact, context-building
  /// view of [episodicMemories].
  List<String> get memorySummaries =>
      [for (final memory in episodicMemories) memory.summary];

  /// A history with additional active messages appended.
  AgentMessageHistory appendMessages(Iterable<AgentMessage> more) =>
      AgentMessageHistory(
        messages: [...messages, ...more],
        episodicMemories: episodicMemories,
      );

  /// A history truncated to the LAST [keep] active messages (oldest
  /// evicted first — context-window eviction order, spec 041 FR-004).
  /// Episodic memories ride along untouched: truncation never loses a
  /// memory summary. `keep` of 0 yields an empty active window; negative
  /// [keep] throws [ArgumentError]. Pure — the receiver is unchanged.
  AgentMessageHistory truncate(int keep) {
    if (keep < 0) {
      throw ArgumentError.value(keep, 'keep', 'must not be negative');
    }
    if (keep == 0) {
      return AgentMessageHistory(
        messages: const [],
        episodicMemories: episodicMemories,
      );
    }
    if (keep >= messages.length) {
      return AgentMessageHistory(
        messages: messages,
        episodicMemories: episodicMemories,
      );
    }
    return AgentMessageHistory(
      messages: messages.sublist(messages.length - keep),
      episodicMemories: episodicMemories,
    );
  }

  /// A history with an additional episodic memory (insertion order).
  AgentMessageHistory addMemory(EpisodicMemory memory) =>
      AgentMessageHistory(
        messages: messages,
        episodicMemories: [...episodicMemories, memory],
      );

  // --------------------------------------------------------------
  // Equality (FR-001 / FR-002) — full-field equality over messages
  // and episodicMemories. Identity short-circuits.
  // --------------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentMessageHistory &&
        runtimeType == other.runtimeType &&
        _listEquals(messages, other.messages) &&
        _listEquals(episodicMemories, other.episodicMemories);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(messages),
        Object.hashAll(episodicMemories),
      );

  // --------------------------------------------------------------
  // JSON contract (FR-003 / FR-004 / FR-005) — `toJson` produces
  // {messages: [...], episodicMemories: [...]}; `fromJson` round-trips
  // to an equal history and throws typed ArgumentError on every
  // malformed-input variant. Parity with `EpisodicMemory.fromJson`
  // and `SteeringMessage.fromJson`.
  // --------------------------------------------------------------
  Map<String, dynamic> toJson() => <String, dynamic>{
        'messages': [for (final m in messages) m.toJson()],
        'episodicMemories': [for (final em in episodicMemories) em.toJson()],
      };

  factory AgentMessageHistory.fromJson(Map<String, dynamic> json) {
    List<dynamic> requireList(String key) {
      final value = json[key];
      if (value is! List) {
        throw ArgumentError.value(
            value, key, 'AgentMessageHistory.$key must be a list');
      }
      return value;
    }

    final rawMessages = requireList('messages');
    final rawMemories = requireList('episodicMemories');

    final messages = <AgentMessage>[];
    for (var i = 0; i < rawMessages.length; i++) {
      final raw = rawMessages[i];
      if (raw is! Map<String, dynamic>) {
        throw ArgumentError.value(
            raw, 'messages[$i]', 'must be a Map<String, dynamic>');
      }
      try {
        messages.add(AgentMessage.fromJson(raw));
      } catch (e) {
        throw ArgumentError.value(
            raw, 'messages[$i]', 'AgentMessage.fromJson failed: $e');
      }
    }

    final memories = <EpisodicMemory>[];
    for (var i = 0; i < rawMemories.length; i++) {
      final raw = rawMemories[i];
      if (raw is! Map<String, dynamic>) {
        throw ArgumentError.value(
            raw, 'episodicMemories[$i]', 'must be a Map<String, dynamic>');
      }
      try {
        memories.add(EpisodicMemory.fromJson(raw));
      } catch (e) {
        throw ArgumentError.value(
            raw, 'episodicMemories[$i]', 'EpisodicMemory.fromJson failed: $e');
      }
    }

    return AgentMessageHistory(
      messages: messages,
      episodicMemories: memories,
    );
  }
}

/// Order-sensitive list equality (delegates to each element's `==`).
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
