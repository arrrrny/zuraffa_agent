// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/009-context-compression-llm/spec.md with this attribution retained.
//
// STUB (TDD red phase for U3) — compressor not implemented yet.

import '../compaction.dart'
    show CompactionSummarizer, HeuristicSummarizer, estimateContextTokens;
import '../domain/entities/episodic_memory/episodic_memory.dart';
import '../types.dart';
import 'episodic_memory_store.dart';
import 'llm_client.dart';

/// Which path produced a compression result (spec 009).
enum CompressionStrategy { none, llm, heuristic }

/// Configurable compression triggers (spec 009 US3).
class ContextCompressionSettings {
  /// Estimated-token threshold above which compression triggers (FR-001).
  final int tokenThreshold;

  /// How many recent messages are preserved verbatim (FR-004).
  final int keepRecentMessages;

  /// Optional message-count trigger (US3).
  final int? messageCountThreshold;

  const ContextCompressionSettings({
    this.tokenThreshold = 64000,
    this.keepRecentMessages = 10,
    this.messageCountThreshold,
  });
}

/// Result of one compression pass (spec 009 Key Entities).
class CompressionResult {
  final String snapshot;
  final List<AgentMessage> preservedMessages;
  final List<AgentMessage> compressedMessages;
  final EpisodicMemory? memory;
  final CompressionStrategy strategy;

  const CompressionResult({
    required this.snapshot,
    required this.preservedMessages,
    required this.compressedMessages,
    this.memory,
    required this.strategy,
  });
}

/// Context compression contract (spec 009 Key Entities).
abstract interface class ContextCompressor {
  Future<CompressionResult> compress(List<AgentMessage> messages);
}

/// LLM-powered context compressor (spec 009 US1/US3).
class LLMBasedContextCompressor implements ContextCompressor {
  final LlmClient client;
  final ContextCompressionSettings settings;
  final EpisodicMemoryStore store;
  final CompactionSummarizer fallbackSummarizer;

  LLMBasedContextCompressor({
    required this.client,
    this.settings = const ContextCompressionSettings(),
    EpisodicMemoryStore? store,
    CompactionSummarizer? fallbackSummarizer,
  })  : store = store ?? EpisodicMemoryStore(),
        fallbackSummarizer = fallbackSummarizer ?? const HeuristicSummarizer();

  @override
  Future<CompressionResult> compress(List<AgentMessage> messages) async {
    final needsCompression = _shouldCompress(messages);
    if (!needsCompression) {
      return CompressionResult(
        snapshot: '',
        preservedMessages: List.unmodifiable(messages),
        compressedMessages: const [],
        strategy: CompressionStrategy.none,
      );
    }
    final compressed =
        messages.sublist(0, messages.length - settings.keepRecentMessages);
    final preserved =
        messages.sublist(messages.length - settings.keepRecentMessages);

    try {
      final response = await client.generate(LlmRequest(
        systemPrompt: _snapshotSystemPrompt,
        messages: compressed,
      ));
      final snapshot = response.content;
      if (!_isValidSnapshot(snapshot)) {
        return _heuristicFallback(compressed, preserved);
      }
      final memory = _storeSnapshot(snapshot, compressed);
      return CompressionResult(
        snapshot: snapshot,
        preservedMessages: List.unmodifiable(preserved),
        compressedMessages: List.unmodifiable(compressed),
        memory: memory,
        strategy: CompressionStrategy.llm,
      );
    } catch (_) {
      return _heuristicFallback(compressed, preserved);
    }
  }

  static const _snapshotSystemPrompt = 'You are a context compressor. '
      'Summarize the conversation so far into a single XML <state_snapshot> '
      'document with exactly these five sections, each preserving key '
      'decisions, file state, and plan progress: <overall_goal>, '
      '<key_knowledge>, <file_system_state>, <recent_actions>, '
      '<current_plan>.';

  static const _sectionTags = [
    '<overall_goal>',
    '<key_knowledge>',
    '<file_system_state>',
    '<recent_actions>',
    '<current_plan>',
  ];

  bool _isValidSnapshot(String snapshot) =>
      snapshot.contains('<state_snapshot') &&
      _sectionTags.every(snapshot.contains);

  EpisodicMemory _storeSnapshot(String snapshot, List<AgentMessage> compressed) {
    final memory = EpisodicMemory(
      id: 'mem_${DateTime.now().microsecondsSinceEpoch}',
      summary: snapshot,
      messages: compressed,
    );
    store.add(memory);
    return memory;
  }

  Future<CompressionResult> _heuristicFallback(
    List<AgentMessage> compressed,
    List<AgentMessage> preserved,
  ) async {
    throw UnimplementedError();
  }

  bool _shouldCompress(List<AgentMessage> messages) {
    if (messages.length <= settings.keepRecentMessages) return false;
    if (settings.messageCountThreshold != null &&
        messages.length > settings.messageCountThreshold!) {
      return true;
    }
    return estimateContextTokens(messages) > settings.tokenThreshold;
  }
}
