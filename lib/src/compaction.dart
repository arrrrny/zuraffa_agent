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

  /// Creates a compaction settings.
  const CompactionSettings({
    this.enabled = true,
    this.reserveTokens = 16384,
    this.keepRecentTokens = 20000,
    this.triggerThresholdRatio = 0.85,
  });
}

/// Abstract contract for generating structured compaction summaries.
abstract interface class CompactionSummarizer {
  /// Summarizes the cut window into a compaction summary, chaining
  /// [previousSummary] when the session was compacted before.
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
  });
}

/// Abstract contract for resolving preserved [ArtifactRef] instances.
abstract interface class ArtifactResolver {
  /// Resolves the ref.
  Future<Object?> resolve(ArtifactRef ref);
}

/// Slices of entries after compaction point calculation.
class CompactionPreparation {
  /// Entries to be compacted (older, to be summarized).
  final List<SessionTreeEntry> cutEntries;

  /// Entries to keep uncompacted (recent).
  final List<SessionTreeEntry> keptEntries;

  /// Creates a compaction preparation.
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

/// Estimates the token cost of [summary] once rendered back into context.
///
/// The snapshot renderer joins decisions, tool names, key results and the
/// plan state into the active context (see `ContextCompressor`), so this
/// mirrors that shape with the same ~4 chars/token heuristic as
/// [estimateContextTokens] — replacing the former fixed 200-token
/// allowance that under-counted content-bearing key results.
int estimateSummaryTokens(CompactionSummary summary) {
  var chars = 120; // <state_snapshot> wrapper tags and section headers.
  for (final d in summary.decisions) {
    chars += d.length + 2; // '; ' joiner
  }
  for (final t in summary.toolNames) {
    chars += t.length + 2;
  }
  for (final r in summary.keyResults) {
    chars += r.length + 2;
  }
  chars += (summary.planState ?? 'continue').length + 2;
  return (chars / 4).ceil();
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

/// Finds the split index separating entries to be compacted from entries to
/// keep.
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
  /// The entry.
  final CompactionEntry entry;

  /// The summary.
  final CompactionSummary summary;

  /// Creates a compaction result.
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
      summary: CompactionSummary(decisions: [], toolNames: [], keyResults: []),
    );
  }

  final compactionSummary = await summarizer.summarize(
    cutEntries: preparation.cutEntries,
    keptEntries: preparation.keptEntries,
  );

  final tokensBefore = estimateEntriesTokens(rootFirstEntries);
  // The summary is rendered back into the active context, so account its
  // real content cost (decisions, tool names, key results) instead of the
  // former fixed 200-token allowance — content-bearing key results could
  // under-count that constant by thousands of tokens.
  final tokensAfter =
      estimateEntriesTokens(preparation.keptEntries) +
      estimateSummaryTokens(compactionSummary);

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
  /// The max key result length.
  final int maxKeyResultLength;

  /// Creates a heuristic summarizer.
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

    // Tool-result message entries in the cut region already yield a
    // content key result below; a matching resultEntryId reference row
    // would duplicate the same tool call in the merged summary.
    final resultEntryIdsInCut = <String>{
      for (final e in cutEntries)
        if (e is MessageEntry && e.message is ToolResultMessage) e.id,
    };

    for (final entry in cutEntries) {
      switch (entry) {
        case MessageEntry():
          // Epic R2.3 — key results: outcomes live in toolResult
          // messages (epic #1 AC3). Every toolResult message in the cut
          // region is retained as a key result; error results carry an
          // explicit [error] marker so a failed call is never silently
          // forgotten by compaction.
          if (entry.message case ToolResultMessage(
            toolName: final tn,
            content: final content,
            isError: final isError,
          )) {
            final marker = isError ? '[error] ' : '';
            final truncated = _truncateCodePoints(content, maxKeyResultLength);
            keyResults.add('$marker$tn: $truncated');
          }
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
          final resultEntryId = entry.record.resultEntryId;
          if (resultEntryId != null &&
              !resultEntryIdsInCut.contains(resultEntryId)) {
            // Key result: tool name + truncated result reference. Skipped
            // when the result message itself sits in the cut region — the
            // content row recorded above supersedes the id-reference.
            keyResults.add('${entry.record.toolName}: result $resultEntryId');
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

    // Truncate key results to maxKeyResultLength (code-point aware so a
    // truncation cut never splits a UTF-16 surrogate pair).
    final truncatedResults = keyResults
        .map((r) => _truncateCodePoints(r, maxKeyResultLength))
        .toList();

    // Merge with previous summary if present.
    final mergedDecisions = [...?previousSummary?.decisions, ...decisions];
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

/// Truncates [s] to at most [max] code points, appending an ellipsis when
/// truncating. Walks [String.runes] so the cut can never split a UTF-16
/// surrogate pair (e.g. an emoji in tool output).
String _truncateCodePoints(String s, int max) {
  if (s.length <= max) return s;
  final buf = StringBuffer();
  var taken = 0;
  for (final rune in s.runes) {
    if (taken >= max) break;
    buf.writeCharCode(rune);
    taken++;
  }
  return '$buf…';
}

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
      return _extractTextFromBlocks(msg.content);
    case UserMessage():
      return _extractTextFromBlocks(msg.content);
    default:
      return null;
  }
}

String? _extractTextFromBlocks(List<ContentBlock> blocks) {
  final buf = StringBuffer();
  for (final block in blocks) {
    if (block is TextBlock) {
      if (buf.isNotEmpty) buf.write('\n');
      buf.write(block.text);
    }
  }
  return buf.isEmpty ? null : buf.toString();
}
