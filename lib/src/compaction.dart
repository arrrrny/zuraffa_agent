// Compaction orchestration — hand-written engine glue using zfa-generated
// CompactionSummary, CompactionEntry entities and the typed entry list.
//
// Never references HeuristicSummarizer from old manual-run lineage.
// All types are zfa-generated or hand-written against zfa-generated types.

import 'types.dart';

/// Configuration governing context compaction thresholds and reserves.
class CompactionSettings {
  /// Whether selective compaction is enabled.
  final bool enabled;

  /// Tokens reserved for the model's response and system prompt buffer.
  final int reserveTokens;

  /// Target number of recent tokens to preserve uncompacted.
  final int keepRecentTokens;

  /// Ratio of usable window that triggers compaction (default: 0.85).
  final double triggerThresholdRatio;

  const CompactionSettings({
    this.enabled = true,
    this.reserveTokens = 16384,
    this.keepRecentTokens = 20000,
    this.triggerThresholdRatio = 0.85,
  });
}

/// Abstract contract for generating structured compaction summaries.
abstract interface class CompactionSummarizer {
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
  });
}

/// Abstract contract for resolving preserved [ArtifactRef] instances.
abstract interface class ArtifactResolver {
  Future<Object?> resolve(ArtifactRef ref);
}

/// Slices of entries after compaction point calculation.
class CompactionPreparation {
  /// Entries to be compacted (older, to be summarized).
  final List<SessionTreeEntry> cutEntries;

  /// Entries to keep uncompacted (recent).
  final List<SessionTreeEntry> keptEntries;

  const CompactionPreparation({
    required this.cutEntries,
    required this.keptEntries,
  });
}

/// Estimates total tokens for a list of [AgentMessage] instances.
///
/// Uses a simple heuristic: ~4 characters per token for English text.
int estimateContextTokens(List<AgentMessage> messages) {
  var totalChars = 0;
  for (final msg in messages) {
    totalChars += _messageCharCount(msg);
  }
  return (totalChars / 4).ceil();
}

/// Estimates total tokens for a list of [SessionTreeEntry] instances.
///
/// Uses recorded [UsageLedgerEntry] values when available, falling back
/// to heuristic character-based estimation.
int estimateEntriesTokens(List<SessionTreeEntry> entries) {
  var total = 0;
  for (final entry in entries) {
    switch (entry) {
      case UsageEntry():
        total += entry.record.inputTokens + entry.record.outputTokens;
      case MessageEntry():
        total += (estimateContextTokens([entry.message]) * 1.0).ceil();
      case ToolInvocationEntry():
        // Estimate ~100 tokens per tool invocation overhead.
        total += 100;
      case CompactionTreeEntry():
        // Compaction summary is compact; estimate conservatively.
        total += 200;
      default:
        total += 50; // Minimal overhead for metadata entries.
    }
  }
  return total;
}

/// Evaluates whether context usage has crossed the compaction threshold.
bool shouldCompact(
  List<AgentMessage> messages,
  int contextWindow, {
  CompactionSettings settings = const CompactionSettings(),
}) {
  if (!settings.enabled) return false;
  final tokens = estimateContextTokens(messages);
  final usableTokens = contextWindow - settings.reserveTokens;
  return tokens > (usableTokens * settings.triggerThresholdRatio).floor();
}

/// Finds the split index separating entries to be compacted from entries to keep.
///
/// Returns `null` if no cut point is needed (everything fits).
int? findCutPoint(List<SessionTreeEntry> rootFirstEntries, int keepTokens) {
  var tokensFromEnd = 0;
  for (var i = rootFirstEntries.length - 1; i >= 0; i--) {
    final entryTokens = _estimateSingleEntryTokens(rootFirstEntries[i]);
    tokensFromEnd += entryTokens;
    if (tokensFromEnd >= keepTokens) {
      // Return the index of the first entry to keep (one past the cut).
      return i;
    }
  }
  return null; // Everything fits within keepTokens.
}

/// Prepares the cut and kept entry slices prior to summarization.
CompactionPreparation prepareCompaction(
  List<SessionTreeEntry> rootFirstEntries,
  int keepTokens,
) {
  final cutIdx = findCutPoint(rootFirstEntries, keepTokens);
  if (cutIdx == null) {
    return CompactionPreparation(
      cutEntries: const [],
      keptEntries: rootFirstEntries,
    );
  }
  return CompactionPreparation(
    cutEntries: rootFirstEntries.sublist(0, cutIdx),
    keptEntries: rootFirstEntries.sublist(cutIdx),
  );
}

/// Result of a compaction operation: the entry to append and its summary.
class CompactionResult {
  final CompactionEntry entry;
  final CompactionSummary summary;

  const CompactionResult({required this.entry, required this.summary});
}

/// Executes selective compaction across the active branch entries.
///
/// Returns a [CompactionResult] containing the [CompactionEntry] to append
/// to the session tree and the [CompactionSummary] for the tree wrapper.
Future<CompactionResult> compact(
  List<SessionTreeEntry> rootFirstEntries,
  int contextWindow, {
  required CompactionSummarizer summarizer,
  CompactionSettings settings = const CompactionSettings(),
}) async {
  final keepTokens = settings.keepRecentTokens;
  final preparation = prepareCompaction(rootFirstEntries, keepTokens);
  final now = DateTime.now().toUtc();

  // If nothing to compact, still create a minimal compaction entry.
  if (preparation.cutEntries.isEmpty) {
    final entry = CompactionEntry(
      id: 'comp_${now.microsecondsSinceEpoch}',
      parentId: null,
      timestamp: now,
      firstKeptEntryId: preparation.keptEntries.isNotEmpty
          ? preparation.keptEntries.first.id
          : '',
      tokensBefore: estimateEntriesTokens(rootFirstEntries),
      tokensAfter: estimateEntriesTokens(rootFirstEntries),
    );
    return CompactionResult(
      entry: entry,
      summary: CompactionSummary(
        decisions: [],
        toolNames: [],
        keyResults: [],
      ),
    );
  }

  final compactionSummary = await summarizer.summarize(
    cutEntries: preparation.cutEntries,
    keptEntries: preparation.keptEntries,
  );

  final tokensBefore = estimateEntriesTokens(rootFirstEntries);
  final tokensAfter = estimateEntriesTokens(preparation.keptEntries) + 200;

  final entry = CompactionEntry(
    id: 'comp_${now.microsecondsSinceEpoch}',
    parentId: null,
    timestamp: now,
    firstKeptEntryId: preparation.keptEntries.isNotEmpty
        ? preparation.keptEntries.first.id
        : '',
    tokensBefore: tokensBefore,
    tokensAfter: tokensAfter,
  );

  return CompactionResult(entry: entry, summary: compactionSummary);
}

/// Built-in rule-based summarizer extracting decisions, tools, and outputs.
class HeuristicSummarizer implements CompactionSummarizer {
  final int maxKeyResultLength;

  const HeuristicSummarizer({this.maxKeyResultLength = 300});

  @override
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
  }) async {
    final decisions = <String>[];
    final toolNames = <String>{};
    final keyResults = <String>[];
    String? planState;

    for (final entry in cutEntries) {
      switch (entry) {
        case MessageEntry():
          final text = _extractText(entry.message);
          if (text != null) {
            // Extract lines starting with "Decision:" or "Plan:".
            for (final line in text.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.toLowerCase().startsWith('decision:')) {
                decisions.add(trimmed.substring(9).trim());
              } else if (trimmed.toLowerCase().startsWith('plan:')) {
                planState = trimmed.substring(5).trim();
              }
            }
          }

        case ToolInvocationEntry():
          toolNames.add(entry.record.toolName);
          if (entry.record.resultEntryId != null) {
            // Key result: tool name + truncated result reference.
            keyResults.add(
              '${entry.record.toolName}: result ${entry.record.resultEntryId}',
            );
          }

        case CompactionTreeEntry():
          // Merge with previous compaction summary if present.
          toolNames.addAll(entry.summary.toolNames);
          decisions.addAll(entry.summary.decisions);
          if (entry.summary.planState != null) {
            planState = entry.summary.planState;
          }

        default:
          break;
      }
    }

    // Truncate key results to maxKeyResultLength.
    final truncatedResults = keyResults.map((r) {
      if (r.length > maxKeyResultLength) {
        return '${r.substring(0, maxKeyResultLength)}…';
      }
      return r;
    }).toList();

    // Merge with previous summary if present.
    final mergedDecisions = [
      ...?previousSummary?.decisions,
      ...decisions,
    ];
    final mergedToolNames = {
      ...?previousSummary?.toolNames,
      ...toolNames,
    }.toList();
    final mergedResults = [
      ...?previousSummary?.keyResults,
      ...truncatedResults,
    ];

    return CompactionSummary(
      decisions: mergedDecisions,
      toolNames: mergedToolNames,
      keyResults: mergedResults,
      planState: planState ?? previousSummary?.planState,
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

int _messageCharCount(AgentMessage msg) {
  var count = 0;
  switch (msg) {
    case UserMessage():
      for (final block in msg.content) {
        count += _blockCharCount(block);
      }
    case AssistantMessage():
      for (final block in msg.content) {
        count += _blockCharCount(block);
      }
    case ToolResultMessage():
      count += msg.content.length;
    case CustomMessage():
      count += msg.payload.length * 8; // Rough estimate for map values.
  }
  return count;
}

int _blockCharCount(ContentBlock block) {
  switch (block) {
    case TextBlock():
      return block.text.length;
    case ImageBlock():
      return block.data.length;
    case AudioBlock():
      return block.data.length;
    case DocumentBlock():
      return block.data.length;
    case ToolCallBlock():
      return block.arguments.toString().length;
    case ThinkingBlock():
      return block.thinking.length;
  }
}

int _estimateSingleEntryTokens(SessionTreeEntry entry) {
  switch (entry) {
    case UsageEntry():
      return entry.record.inputTokens + entry.record.outputTokens;
    case MessageEntry():
      return (estimateContextTokens([entry.message]) * 1.0).ceil();
    case ToolInvocationEntry():
      return 100;
    case CompactionTreeEntry():
      return 200;
    default:
      return 50;
  }
}

String? _extractText(AgentMessage msg) {
  switch (msg) {
    case AssistantMessage():
      final buf = StringBuffer();
      for (var i = 0; i < msg.content.length; i++) {
        final block = msg.content[i];
        if (block is TextBlock) {
          if (buf.isNotEmpty) buf.write('\n');
          buf.write(block.text);
        }
      }
      return buf.isEmpty ? null : buf.toString();
    case UserMessage():
      final buf = StringBuffer();
      for (var i = 0; i < msg.content.length; i++) {
        final block = msg.content[i];
        if (block is TextBlock) {
          if (buf.isNotEmpty) buf.write('\n');
          buf.write(block.text);
        }
      }
      return buf.isEmpty ? null : buf.toString();
    default:
      return null;
  }
}
