import 'types.dart';

/// UsageLedger — a read projection over [UsageEntry] instances that provides
/// aggregate token metrics and filtered sub-ledgers.
///
/// This is integration glue: the zfa-generated [UsageLedgerEntry] entities
/// provide raw data, and this projection aggregates it for budget tracking.

/// Aggregate token accounting projection over a list of [UsageEntry] records.
class UsageLedger {
  final List<UsageEntry> _entries;

  const UsageLedger(this._entries);

  /// Sum of [UsageLedgerEntry.inputTokens] across all entries.
  int get totalInputTokens =>
      _entries.fold(0, (sum, e) => sum + e.record.inputTokens);

  /// Sum of [UsageLedgerEntry.outputTokens] across all entries.
  int get totalOutputTokens =>
      _entries.fold(0, (sum, e) => sum + e.record.outputTokens);

  /// Total tokens consumed: input + output.
  int get totalTokens => totalInputTokens + totalOutputTokens;

  /// Sum of [UsageLedgerEntry.cacheReadTokens] across all entries.
  int get totalCacheReadTokens =>
      _entries.fold(0, (sum, e) => sum + e.record.cacheReadTokens);

  /// Sum of [UsageLedgerEntry.cacheWriteTokens] across all entries.
  int get totalCacheWriteTokens =>
      _entries.fold(0, (sum, e) => sum + e.record.cacheWriteTokens);

  /// Returns a sub-ledger containing only entries for the given [turnNumber].
  UsageLedger byTurn(int turnNumber) {
    return UsageLedger(
      _entries.where((e) => e.record.turnNumber == turnNumber).toList(),
    );
  }

  /// Returns a sub-ledger containing only entries whose [UsageEntry.model]
  /// has a matching [modelId].
  UsageLedger byModel(String modelId) {
    return UsageLedger(
      _entries.where((e) => e.model?.modelId == modelId).toList(),
    );
  }

  /// Number of entries in this ledger.
  int get length => _entries.length;

  /// Whether this ledger has no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether this ledger has at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;
}
