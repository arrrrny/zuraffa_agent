import 'dart:convert';

import 'retention_policy.dart';
import 'types.dart';

/// UsageLedger — a read projection over [UsageEntry] instances that provides
/// aggregate token metrics and filtered sub-ledgers.
///
/// This is integration glue: the zfa-generated [UsageLedgerEntry] entities
/// provide raw data, and this projection aggregates it for budget tracking.
///
/// Spec 083: the ledger is a READ-ONLY projection — it defensively copies
/// its entries into an unmodifiable list, exposes them via [entries],
/// serializes via [toJson], and defines ordered-sequence equality through
/// the serialized form (equal ledgers have equal `toJson`).
class UsageLedger {
  final List<UsageEntry> _entries;

  /// Creates an usage ledger.
  UsageLedger(List<UsageEntry> entries) : _entries = List.unmodifiable(entries);

  /// The immutable entry sequence this projection aggregates over
  /// (spec 083 FR-002). Mutation attempts throw [UnsupportedError].
  List<UsageEntry> get entries => _entries;

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

  /// Serializes the projection (spec 083 FR-003): the entries' own JSON
  /// forms, in order. Monomorphic — no `_type` tag needed.
  Map<String, dynamic> toJson() => {
    'entries': [for (final e in _entries) e.toJson()],
  };

  /// Rebuilds a ledger from its serialized form. Round-trips [toJson]:
  /// `UsageLedger.fromJson(ledger.toJson()) == ledger`.
  factory UsageLedger.fromJson(Map<String, dynamic> json) => UsageLedger([
    for (final e in (json['entries'] as List? ?? const []))
      UsageEntry.fromJson(Map<String, dynamic>.from(e as Map)),
  ]);

  /// Applies [policy] to this projection and returns the pruned projection
  /// (issue #135).
  ///
  /// The receiver is untouched — spec 083 keeps the ledger an immutable
  /// value object, so prune is a pure filter: maxAge by the entry's own
  /// timestamp, maxCount keeping the newest, maxBytes dropping
  /// oldest-first by serialized size. Order of survivors is preserved.
  UsageLedger prune(RetentionPolicy policy, {DateTime? now}) {
    if (policy.isUnlimited || _entries.isEmpty) {
      return UsageLedger(_entries.toList());
    }
    final candidates = [
      for (final entry in _entries)
        (
          id: entry.id,
          timestamp: entry.timestamp,
          bytes: bytesOfJson(entry.toJson()),
        ),
    ];
    final victims = Set<String>.of(
      selectPruneIds(candidates: candidates, policy: policy, now: now),
    );
    if (victims.isEmpty) return UsageLedger(_entries.toList());
    return UsageLedger([
      for (final entry in _entries)
        if (!victims.contains(entry.id)) entry,
    ]);
  }

  /// The serialized entry sequence — the equality substrate (spec 083
  /// FR-004). Lazy + memoized: sub-ledger construction stays cheap and the
  /// encode happens at most once per instance. Deterministic because
  /// [UsageEntry.toJson] builds its map from a fixed literal key order.
  late final String _encoded = jsonEncode([
    for (final e in _entries) e.toJson(),
  ]);

  /// Ordered-sequence equality (spec 083 FR-004): two ledgers are equal
  /// iff their entries serialize identically, in order. Defined THROUGH
  /// the serialized form so equality and serialization can never disagree.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageLedger && _encoded == other._encoded);

  @override
  int get hashCode => _encoded.hashCode;
}
