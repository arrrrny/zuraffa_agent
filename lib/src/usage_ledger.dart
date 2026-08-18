// NEW file for zuraffa_agent (no pi_agent equivalent): read-side token usage
// projection over UsageLedgerEntry records (contracts/support-assets.md).
// Source licensed MIT under zuraffa_agent. See NOTICE.
//
// Consumed by the plugin policy shell's MissionBudgetHook
// (arrrrny/zuraffa#387).
library;

import 'types.dart';

/// Read-side projection over [UsageLedgerEntry] records on a branch.
///
/// Aggregates per-call token usage into totals and per-turn / per-model
/// views. Totals cover billed input and output tokens; provider cache token
/// fields are reported per record but are not double-counted into the totals
/// (test/usage_ledger_test.dart).
class UsageLedger {
  final List<UsageLedgerEntry> _entries;

  /// Creates a ledger from the branch-filtered record list.
  ///
  /// Branch filtering happens upstream (the caller passes the active
  /// branch's entries, e.g. via `AgentSession.getBranch`).
  UsageLedger.fromEntries(List<UsageLedgerEntry> entries)
      : _entries = List.unmodifiable(entries);

  /// Sum of all input tokens across the records.
  int get totalInputTokens =>
      _entries.fold(0, (sum, e) => sum + e.inputTokens);

  /// Sum of all output tokens across the records.
  int get totalOutputTokens =>
      _entries.fold(0, (sum, e) => sum + e.outputTokens);

  /// Records keyed by turn number.
  ///
  /// When a turn has multiple records, the last record wins.
  Map<int, UsageLedgerEntry> byTurn() {
    final result = <int, UsageLedgerEntry>{};
    for (final e in _entries) {
      result[e.turnNumber] = e;
    }
    return result;
  }

  /// Total tokens (input + output) per model id.
  Map<String, int> byModel() {
    final result = <String, int>{};
    for (final e in _entries) {
      result[e.model.modelId] =
          (result[e.model.modelId] ?? 0) + e.inputTokens + e.outputTokens;
    }
    return result;
  }
}
