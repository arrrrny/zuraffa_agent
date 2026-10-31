// Retention policy core (issue #135) — the pure, store-agnostic half of
// the retention feature.
//
// [RetentionPolicy] states the per-store limits (max age, max count, max
// bytes); [PruneCandidate] / [PruneResult] are the prune vocabulary;
// [selectPruneIds] is the one pure victim-selection function every store
// shares.
//
// This file depends on types.dart only, so the four stores it serves
// (session storage backends, episodic memory, usage ledger, engine event
// log) import it for the policy types without an import cycle —
// retention.dart holds the aggregation layer ([RetentionCoordinator] and
// friends) and imports the stores instead.
//
// Pure Dart: no dart:io (constitution VII). The file I/O for backup
// envelopes lives in session_backup.dart.

import 'dart:convert';

import 'types.dart';

/// Per-store retention limits (issue #135). A null axis is unlimited on
/// that axis; [RetentionPolicy.unlimited] is unlimited everywhere.
class RetentionPolicy {
  /// Creates a retention policy.
  const RetentionPolicy({this.maxAge, this.maxCount, this.maxBytes});

  /// Creates a retention policy (unlimited variant).
  const RetentionPolicy.unlimited()
    : maxAge = null,
      maxCount = null,
      maxBytes = null;

  /// Entries strictly older than this are pruned.
  final Duration? maxAge;

  /// At most this many entries survive (the newest win).
  final int? maxCount;

  /// At most this many serialized bytes survive (oldest dropped first).
  ///
  /// The unit is per store — do not mix budgets across stores: UTF-8
  /// bytes of the JSON encoding ([bytesOfJson]) for the session stores,
  /// episodic memory and the usage ledger; the rendered size
  /// (`toString().length`) for the engine event log, which exposes no
  /// JSON render of its events.
  final int? maxBytes;

  /// Whether the retention policy is unlimited.
  bool get isUnlimited =>
      maxAge == null && maxCount == null && maxBytes == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetentionPolicy &&
          maxAge == other.maxAge &&
          maxCount == other.maxCount &&
          maxBytes == other.maxBytes);

  @override
  int get hashCode => Object.hash(maxAge, maxCount, maxBytes);

  @override
  String toString() =>
      'RetentionPolicy(maxAge: $maxAge, maxCount: $maxCount, maxBytes: '
      '$maxBytes)';
}

/// One prune candidate: identity, ordering time, and serialized size.
typedef PruneCandidate = ({String id, DateTime timestamp, int bytes});

/// What one prune pass removed. [removedBytes] is the serialized size of
/// the pruned victims — an approximation of what the backing store frees.
class PruneResult {
  /// Creates a prune result.
  const PruneResult({required this.removedCount, required this.removedBytes});

  /// The empty prune result.
  static const PruneResult empty = PruneResult(
    removedCount: 0,
    removedBytes: 0,
  );

  /// The removed count.
  final int removedCount;

  /// The removed bytes.
  final int removedBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PruneResult &&
          removedCount == other.removedCount &&
          removedBytes == other.removedBytes);

  @override
  int get hashCode => Object.hash(removedCount, removedBytes);

  @override
  String toString() =>
      'PruneResult(removedCount: $removedCount, removedBytes: $removedBytes)';
}

/// Serialized byte size of a JSON map — the size unit of
/// [RetentionPolicy.maxBytes].
int bytesOfJson(Map<String, dynamic> json) =>
    utf8.encode(jsonEncode(json)).length;

/// Builds prune candidates for session-tree entries (shared by the session
/// storage backends: identity = entry id, time = entry timestamp, size =
/// serialized entry bytes).
List<PruneCandidate> sessionEntryCandidates(
  Iterable<SessionTreeEntry> entries,
) => [
  for (final entry in entries)
    (
      id: entry.id,
      timestamp: entry.timestamp,
      bytes: bytesOfJson(entry.toJson()),
    ),
];

/// Sums the serialized bytes of the pruned victims.
int prunedBytes(List<String> victims, Map<String, int> bytesById) => [
  for (final id in victims) bytesById[id] ?? 0,
].fold(0, (sum, bytes) => sum + bytes);

/// Selects the victims of one prune pass over [candidates] (pure function,
/// shared by every store). The axes compose by union of victims, applied in
/// order:
///
///   1. maxAge — entries strictly older than `now - maxAge`.
///   2. maxCount — when more than maxCount survive, the oldest are dropped
///      (ties broken by candidate order: earlier candidates count as older).
///   3. maxBytes — while the survivors' total size exceeds maxBytes, the
///      oldest are dropped.
List<String> selectPruneIds({
  required List<PruneCandidate> candidates,
  required RetentionPolicy policy,
  DateTime? now,
}) {
  if (policy.isUnlimited || candidates.isEmpty) return const [];
  final clock = now ?? DateTime.now();
  final victims = <String>{};

  final maxAge = policy.maxAge;
  if (maxAge != null) {
    final cutoff = clock.subtract(maxAge);
    for (final candidate in candidates) {
      if (candidate.timestamp.isBefore(cutoff)) victims.add(candidate.id);
    }
  }

  var survivors = [
    for (final candidate in candidates)
      if (!victims.contains(candidate.id)) candidate,
  ];
  final maxCount = policy.maxCount;
  if (maxCount != null && survivors.length > maxCount) {
    final ordered = List<PruneCandidate>.of(survivors);
    _sortByTime(ordered);
    for (var i = 0; i < ordered.length - maxCount; i++) {
      victims.add(ordered[i].id);
    }
    survivors = [
      for (final candidate in survivors)
        if (!victims.contains(candidate.id)) candidate,
    ];
  }

  final maxBytes = policy.maxBytes;
  if (maxBytes != null && survivors.isNotEmpty) {
    var total = survivors.fold(0, (sum, c) => sum + c.bytes);
    if (total > maxBytes) {
      final ordered = List<PruneCandidate>.of(survivors);
      _sortByTime(ordered);
      for (final candidate in ordered) {
        if (total <= maxBytes) break;
        victims.add(candidate.id);
        total -= candidate.bytes;
      }
    }
  }

  return victims.toList();
}

/// Deterministic oldest-first order: by timestamp, ties broken by original
/// candidate position (List.sort is not stable).
void _sortByTime(List<PruneCandidate> candidates) {
  final indexed =
      [for (var i = 0; i < candidates.length; i++) (i: i, c: candidates[i])]
        ..sort((a, b) {
          final byTime = a.c.timestamp.compareTo(b.c.timestamp);
          return byTime != 0 ? byTime : a.i.compareTo(b.i);
        });
  for (var i = 0; i < candidates.length; i++) {
    candidates[i] = indexed[i].c;
  }
}
