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
enum CompressionStrategy {
  /// No compression ran; the transcript fit as-is.
  none,

  /// An LLM summarizer call produced the compaction.
  llm,

  /// The built-in heuristic produced the compaction (no LLM call).
  heuristic,
}

/// Configurable compression triggers (spec 009 US3).
class ContextCompressionSettings {
  /// Estimated-token threshold above which compression triggers (FR-001).
  final int tokenThreshold;

  /// How many recent messages are preserved verbatim (FR-004).
  final int keepRecentMessages;

  /// Optional message-count trigger (US3).
  final int? messageCountThreshold;

  /// Creates a context compression settings.
  const ContextCompressionSettings({
    this.tokenThreshold = 64000,
    this.keepRecentMessages = 10,
    this.messageCountThreshold,
  });
}

/// Result of one compression pass (spec 009 Key Entities).
class CompressionResult {
  /// The snapshot.
  final String snapshot;

  /// Recent messages preserved verbatim after the snapshot. Must not begin
  /// with orphaned tool results — tool rows whose assistant predecessor was
  /// compacted away (see [ContextCompressor]).
  final List<AgentMessage> preservedMessages;

  /// The compressed messages.
  final List<AgentMessage> compressedMessages;

  /// The memory.
  final EpisodicMemory? memory;

  /// The strategy.
  final CompressionStrategy strategy;

  /// Creates a compression result.
  const CompressionResult({
    required this.snapshot,
    required this.preservedMessages,
    required this.compressedMessages,
    this.memory,
    required this.strategy,
  });
}

/// Context compression contract (spec 009 Key Entities).
///
/// [compress] may receive the caller's own pre-flight estimate for
/// [messages] as [estimatedTokens] (issue #138): when supplied, the
/// implementation SHOULD gate on it instead of re-deriving a count with
/// its own convention, so the pre-flight trigger and the compressor's gate
/// cannot disagree about the same transcript.
///
/// Preserved-tail invariant (issue #138 review): the returned
/// [CompressionResult.preservedMessages] must never BEGIN with orphaned
/// tool results — tool rows whose predecessor assistant row was compacted
/// away. Callers drop leading tool rows defensively (the pre-flight's
/// transcript rebuild), but the compressor owns the invariant.
abstract interface class ContextCompressor {
  /// Compresses the transcript to fit the token budget, preserving the
  /// tail per the invariant above.
  Future<CompressionResult> compress(
    List<AgentMessage> messages, {
    int? estimatedTokens,
  });
}

/// LLM-powered context compressor (spec 009 US1/US3).
class LLMBasedContextCompressor implements ContextCompressor {
  /// The client.
  final LlmClient client;

  /// The settings.
  final ContextCompressionSettings settings;

  /// The store.
  final EpisodicMemoryStore store;

  /// The fallback summarizer.
  final CompactionSummarizer fallbackSummarizer;

  /// Creates an LLM based context compressor.
  LLMBasedContextCompressor({
    required this.client,
    this.settings = const ContextCompressionSettings(),
    EpisodicMemoryStore? store,
    CompactionSummarizer? fallbackSummarizer,
  }) : store = store ?? EpisodicMemoryStore(),
       fallbackSummarizer = fallbackSummarizer ?? const HeuristicSummarizer();

  @override
  Future<CompressionResult> compress(
    List<AgentMessage> messages, {
    int? estimatedTokens,
  }) async {
    final needsCompression = _shouldCompress(messages, estimatedTokens);
    if (!needsCompression) {
      return CompressionResult(
        snapshot: '',
        preservedMessages: List.unmodifiable(messages),
        compressedMessages: const [],
        strategy: CompressionStrategy.none,
      );
    }
    final compressed = messages.sublist(
      0,
      messages.length - settings.keepRecentMessages,
    );
    final preserved = messages.sublist(
      messages.length - settings.keepRecentMessages,
    );

    try {
      final response = await client.generate(
        LlmRequest(systemPrompt: _snapshotSystemPrompt, messages: compressed),
      );
      final snapshot = response.content;
      if (!_isValidSnapshot(snapshot)) {
        return await _heuristicFallback(compressed, preserved);
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
      return await _heuristicFallback(compressed, preserved);
    }
  }

  static const _snapshotSystemPrompt =
      'You are a context compressor. '
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

  EpisodicMemory _storeSnapshot(
    String snapshot,
    List<AgentMessage> compressed,
  ) {
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
    final now = DateTime.now().toUtc();
    final entries = [
      for (var i = 0; i < compressed.length; i++)
        MessageEntry(
          id: 'heuristic_$i',
          timestamp: now,
          message: compressed[i],
        ),
    ];
    final summary = await fallbackSummarizer.summarize(
      cutEntries: entries,
      keptEntries: const [],
    );
    final snapshot = StringBuffer('<state_snapshot>');
    snapshot.write('<overall_goal>continue the mission</overall_goal>');
    snapshot.write(
      '<key_knowledge>${summary.decisions.join('; ')}</key_knowledge>',
    );
    snapshot.write('<file_system_state>see key knowledge</file_system_state>');
    snapshot.write('<recent_actions>');
    snapshot.write([...summary.toolNames, ...summary.keyResults].join('; '));
    snapshot.write('</recent_actions>');
    snapshot.write(
      '<current_plan>${summary.planState ?? 'continue'}</current_plan>',
    );
    snapshot.write('</state_snapshot>');

    final memory = _storeSnapshot(snapshot.toString(), compressed);
    return CompressionResult(
      snapshot: snapshot.toString(),
      preservedMessages: List.unmodifiable(preserved),
      compressedMessages: List.unmodifiable(compressed),
      memory: memory,
      strategy: CompressionStrategy.heuristic,
    );
  }

  bool _shouldCompress(List<AgentMessage> messages, int? estimatedTokens) {
    if (messages.length <= settings.keepRecentMessages) return false;
    if (settings.messageCountThreshold != null &&
        messages.length > settings.messageCountThreshold!) {
      return true;
    }
    // Trust the caller's pre-flight estimate when supplied (issue #138
    // review): it counts with the estimator's convention — a
    // TiktokenEstimator's BPE tokens, not this class's chars/4
    // re-derivation — so the pre-flight trigger and this gate agree.
    final tokens = estimatedTokens ?? estimateContextTokens(messages);
    return tokens > settings.tokenThreshold;
  }
}
