// Ported from pi_agent (~/Developer/pi/pi_agent, branch 001-dart-agent-package,
// lib/src/compaction.dart). Source licensed BSD-3-Clause (ZikZak AI);
// modifications licensed MIT under zuraffa_agent. See NOTICE.
/// Selective structured context compaction.
///
/// Replaces pi_agent's naive string summarizer (research R9): the default
/// [HeuristicSummarizer] extracts structured categories from typed entries,
/// discarded material is represented by resolvable [ArtifactRef]s, and
/// summaries compose across successive compactions. The estimator,
/// cut-point search, summarizer injection, and compaction core all live
/// here. pi_agent's `_generatePlaceholderSummary` and `CompactionResult`
/// are NOT ported — [compact] returns a typed [CompactionEntry] directly.
library;

import 'types.dart';

/// Signature for context token estimation.
typedef TokenEstimator = int Function(List<AgentMessage> messages);

/// Default compaction settings (ported defaults).
const CompactionSettings defaultCompactionSettings = CompactionSettings();

/// Reference to material moved out of the live context by compaction.
///
/// Opaque by design: the `kind`/`id` pair is resolved through an
/// [ArtifactResolver] implemented by the artifact store (spec 003).
class ArtifactRef {
  /// Artifact category, e.g. 'tool-output' or 'file'.
  final String kind;

  /// Artifact store key.
  final String id;

  /// Creates an artifact reference.
  const ArtifactRef({required this.kind, required this.id});

  @override
  bool operator ==(Object other) =>
      other is ArtifactRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'ArtifactRef($kind/$id)';
}

/// Resolves [ArtifactRef]s to their stored material.
///
/// Implemented by spec 003's artifact store; tests provide a stub.
abstract class ArtifactResolver {
  /// Resolves [ref] to the stored artifact, or null when it is gone.
  Future<Object?> resolve(ArtifactRef ref);
}

/// Structured compaction summary replacing pi_agent's placeholder string.
///
/// Retained categories survive compaction as typed fields; discarded
/// material is represented by resolvable [ArtifactRef]s.
class CompactionSummary {
  /// Decisions retained from the compacted conversation.
  final List<String> decisions;

  /// Names of tools invoked in the compacted conversation.
  final List<String> toolNames;

  /// Key results retained from the compacted conversation.
  final List<String> keyResults;

  /// Mission plan state at compaction time, if any.
  final String? planState;

  /// References to discarded material, resolvable via [ArtifactResolver].
  final List<ArtifactRef> artifacts;

  /// Optional narrative summary (e.g. LLM-written).
  final String? prose;

  /// Creates a structured compaction summary.
  const CompactionSummary({
    this.decisions = const [],
    this.toolNames = const [],
    this.keyResults = const [],
    this.planState,
    this.artifacts = const [],
    this.prose,
  });

  @override
  bool operator ==(Object other) =>
      other is CompactionSummary &&
      _listEq(other.decisions, decisions) &&
      _listEq(other.toolNames, toolNames) &&
      _listEq(other.keyResults, keyResults) &&
      other.planState == planState &&
      _listEq(other.artifacts, artifacts) &&
      other.prose == prose;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(decisions),
        Object.hashAll(toolNames),
        Object.hashAll(keyResults),
        planState,
        Object.hashAll(artifacts),
        prose,
      );

  @override
  String toString() =>
      'CompactionSummary(decisions: $decisions, toolNames: $toolNames, '
      'keyResults: $keyResults, planState: $planState, '
      'artifacts: $artifacts)';
}

/// Injectable summarizer producing the typed summary for a compaction.
///
/// Spec 004 can wire an LLM-backed implementation without touching this
/// layer; [HeuristicSummarizer] is the shipped default (research R9).
abstract class CompactionSummarizer {
  /// Summarizes the entries being cut, folding in [previousSummary] so
  /// summaries compose across successive compactions (contract guarantee 5).
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
    String? customInstructions,
  });
}

/// Default [CompactionSummarizer]: deterministic structured extraction.
///
/// Extracts from the typed entries being cut:
/// - decisions: assistant `Decision:`/`Decided:`/`Resolved:` lines;
/// - plan state: the most recent `Plan:` line (user or assistant);
/// - tool names: tool calls and invocation records, first-seen order;
/// - key results: non-error tool-result text, truncated per
///   [maxKeyResultLength];
/// - artifacts: existing [ArtifactRef]s from [ToolInvocationRecord]s.
///
/// Previous summaries fold in (decisions/toolNames/keyResults/artifacts
/// concatenated, plan state replaced when a newer one is found).
class HeuristicSummarizer implements CompactionSummarizer {
  static final RegExp _decisionPattern = RegExp(
      r'^\s*[-*]?\s*(?:decision|decided|resolved)\s*:\s*(.+)$',
      caseSensitive: false);
  static final RegExp _planPattern =
      RegExp(r'^\s*plan\s*:\s*(.+)$', caseSensitive: false);

  /// Maximum characters kept per key result.
  final int maxKeyResultLength;

  /// Creates the heuristic summarizer.
  const HeuristicSummarizer({this.maxKeyResultLength = 200});

  @override
  Future<CompactionSummary> summarize({
    required List<SessionTreeEntry> cutEntries,
    required List<SessionTreeEntry> keptEntries,
    CompactionSummary? previousSummary,
    String? customInstructions,
  }) async {
    final decisions = <String>[];
    final toolNames = <String>[];
    final keyResults = <String>[];
    final artifacts = <ArtifactRef>[];
    String? planState;

    void addToolName(String name) {
      if (!toolNames.contains(name)) toolNames.add(name);
    }

    for (final entry in cutEntries) {
      switch (entry) {
        case MessageEntry(:final message):
          switch (message) {
            case AssistantMessage(:final content):
              for (final block in content) {
                switch (block) {
                  case TextBlock():
                    for (final line in block.text.split('\n')) {
                      final decision = _decisionPattern.firstMatch(line);
                      if (decision != null) {
                        decisions.add(decision.group(1)!.trim());
                      }
                      final plan = _planPattern.firstMatch(line);
                      if (plan != null) planState = plan.group(1)!.trim();
                    }
                  case ToolCallBlock(:final name):
                    addToolName(name);
                  case _:
                    break;
                }
              }
            case ToolResultMessage(:final content, :final isError):
              if (!isError) {
                final text = content
                    .whereType<TextBlock>()
                    .map((b) => b.text)
                    .join()
                    .trim();
                if (text.isNotEmpty) {
                  keyResults.add(text.length > maxKeyResultLength
                      ? text.substring(0, maxKeyResultLength)
                      : text);
                }
              }
            case UserMessage(:final content):
              for (final block in content) {
                if (block is! TextBlock) continue;
                final plan = _planPattern.firstMatch(block.text);
                if (plan != null) planState = plan.group(1)!.trim();
              }
            case CustomMessage():
              break;
          }
        case ToolInvocationRecord(:final toolName, :final artifactRefs):
          addToolName(toolName);
          artifacts.addAll(artifactRefs);
        case _:
          break;
      }
    }

    final previous = previousSummary;
    return CompactionSummary(
      decisions: [...?previous?.decisions, ...decisions],
      toolNames: [...?previous?.toolNames, ...toolNames],
      keyResults: [...?previous?.keyResults, ...keyResults],
      planState: planState ?? previous?.planState,
      artifacts: [...?previous?.artifacts, ...artifacts],
      prose: previous?.prose,
    );
  }
}

/// Estimates context tokens from a list of messages (chars/4 heuristic).
///
/// This is the default [TokenEstimator]; real per-call counts come from the
/// usage ledger and take precedence via [estimateEntriesTokens] (R12).
int estimateContextTokens(List<AgentMessage> messages) {
  var total = 0;
  for (final message in messages) {
    total += _estimateMessageTokens(message);
  }
  return total;
}

/// Estimates the context tokens of an entry list (R12).
///
/// Recorded [UsageLedgerEntry] counts take precedence: the estimate is the
/// sum of recorded counts plus the heuristic delta for messages appended
/// after the last recorded usage. With no records at all, it falls back to
/// the pure chars/4 heuristic over all messages.
int estimateEntriesTokens(List<SessionTreeEntry> entries) {
  var ledgerTokens = 0;
  var lastUsageIndex = -1;
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (e is UsageLedgerEntry) {
      ledgerTokens += e.inputTokens + e.outputTokens;
      lastUsageIndex = i;
    }
  }

  var delta = 0;
  for (var i = lastUsageIndex + 1; i < entries.length; i++) {
    final e = entries[i];
    if (e is MessageEntry) delta += _estimateMessageTokens(e.message);
  }
  if (lastUsageIndex < 0) {
    delta = estimateContextTokens([
      for (final e in entries)
        if (e is MessageEntry) e.message,
    ]);
  }
  return ledgerTokens + delta;
}

/// Checks whether compaction should be triggered.
///
/// Triggers when the estimated context exceeds
/// `(contextWindow - reserveTokens) * triggerThresholdRatio`; disabled
/// settings never trigger.
bool shouldCompact(
  List<AgentMessage> messages,
  int contextWindow, {
  CompactionSettings settings = defaultCompactionSettings,
}) {
  if (!settings.enabled) return false;
  final usable = contextWindow - settings.reserveTokens;
  if (usable <= 0) return false;
  return estimateContextTokens(messages) > usable * settings.triggerThresholdRatio;
}

/// Finds the cut point index in [entries] to keep [keepTokens] recent tokens.
///
/// Walks entries from the leaf backward, accumulating message tokens, and
/// returns the index of the first entry to KEEP (older entries are cut).
/// Returns null when the whole history fits within [keepTokens].
int? findCutPoint(
  List<SessionTreeEntry> entries,
  int keepTokens, {
  int startIndex = 0,
}) {
  var accumulated = 0;
  for (var i = entries.length - 1; i >= startIndex; i--) {
    final entry = entries[i];
    if (entry is MessageEntry) {
      accumulated += _estimateMessageTokens(entry.message);
    }
    if (accumulated >= keepTokens) {
      return i;
    }
  }
  return null;
}

/// Separates the entries to cut from the entries to keep.
class CompactionPreparation {
  /// Index of the first kept entry ([CompactionPreparation.keptEntries]).
  final int cutIndex;

  /// Estimated tokens removed by the cut.
  final int tokensCut;

  /// Entries that will be kept (from [CompactionPreparation.cutIndex] on).
  final List<SessionTreeEntry> keptEntries;

  /// Entries that will be removed/summarized.
  final List<SessionTreeEntry> cutEntries;

  /// Previous compaction summary, if any.
  final String? previousSummary;

  /// Whether there is anything to cut.
  bool get canCompact => cutIndex > 0;

  /// Creates a compaction preparation.
  const CompactionPreparation({
    required this.cutIndex,
    required this.tokensCut,
    required this.keptEntries,
    required this.cutEntries,
    this.previousSummary,
  });
}

/// Prepares compaction by identifying the cut point and categorizing entries.
CompactionPreparation prepareCompaction(
  List<SessionTreeEntry> entries,
  int keepTokens, {
  String? previousSummary,
}) {
  final cutIndex = findCutPoint(entries, keepTokens) ?? 0;
  var tokensCut = 0;
  for (var i = 0; i < cutIndex; i++) {
    final entry = entries[i];
    if (entry is MessageEntry) {
      tokensCut += _estimateMessageTokens(entry.message);
    }
  }

  return CompactionPreparation(
    cutIndex: cutIndex,
    tokensCut: tokensCut,
    keptEntries: entries.sublist(cutIndex),
    cutEntries: entries.sublist(0, cutIndex),
    previousSummary: previousSummary,
  );
}

/// Runs full compaction: find the cut point, summarize the cut entries, and
/// produce the [CompactionEntry] to append to the active branch.
///
/// [entries] must be the active branch in root-to-leaf order. Call only when
/// [shouldCompact] returns true (compaction runs at turn boundaries; the
/// entry parents at the current leaf, so sibling branches stay untouched).
/// Throws [StateError] when compaction is disabled.
Future<CompactionEntry> compact(
  List<SessionTreeEntry> entries,
  int contextWindow, {
  required CompactionSummarizer summarizer,
  CompactionSettings? settings,
  String? customInstructions,
  CompactionSummary? previousSummary,
}) async {
  settings ??= defaultCompactionSettings;
  if (!settings.enabled) {
    throw StateError('compact() called while compaction is disabled');
  }
  final preparation =
      prepareCompaction(entries, settings.keepRecentTokens);

  final summary = await summarizer.summarize(
    cutEntries: preparation.cutEntries,
    keptEntries: preparation.keptEntries,
    previousSummary: previousSummary,
    customInstructions: customInstructions,
  );

  final firstKeptEntryId = preparation.keptEntries.isNotEmpty
      ? preparation.keptEntries.first.id
      : (entries.isNotEmpty ? entries.last.id : '');

  return CompactionEntry(
    id: newEntryId(),
    parentId: entries.isNotEmpty ? entries.last.id : '',
    timestamp: DateTime.now(),
    summary: summary,
    firstKeptEntryId: firstKeptEntryId,
    tokensBefore: estimateEntriesTokens(entries),
  );
}

int _estimateMessageTokens(AgentMessage message) {
  final text = switch (message) {
    UserMessage(:final content) =>
      content.whereType<TextBlock>().map((b) => b.text).join(),
    AssistantMessage(:final content) =>
      content.whereType<TextBlock>().map((b) => b.text).join(),
    ToolResultMessage(:final content) =>
      content.whereType<TextBlock>().map((b) => b.text).join(),
    CustomMessage(:final display) => display,
  };
  return (text.length / 4).ceil();
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
