// Retention & TTL policy for the durable stores (issue #135).
//
// Sessions, episodic memory, the usage ledger, and the engine event log
// all grow unbounded today — there is no "delete sessions older than N
// days" or "cap episodic memory at M entries" story. [RetentionPolicy]
// states the per-store limits (max age, max count, max bytes); each store
// exposes a `prune()` that enforces them; [RetentionCoordinator] bundles
// the stores + policies into the hook [MissionRunner] calls between
// missions.
//
// Pure Dart: no dart:io (constitution VII). The file I/O for backup
// envelopes lives in session_backup.dart.

import 'dart:convert';

import 'engine/events/engine_event_log.dart';
import 'llm/episodic_memory_store.dart';
import 'session_storage.dart';
import 'types.dart';
import 'usage_ledger.dart';

/// Per-store retention limits (issue #135). A null axis is unlimited on
/// that axis; [RetentionPolicy.unlimited] is unlimited everywhere.
class RetentionPolicy {
  const RetentionPolicy({this.maxAge, this.maxCount, this.maxBytes});

  const RetentionPolicy.unlimited()
    : maxAge = null,
      maxCount = null,
      maxBytes = null;

  /// Entries strictly older than this are pruned.
  final Duration? maxAge;

  /// At most this many entries survive (the newest win).
  final int? maxCount;

  /// At most this many serialized bytes survive (oldest dropped first).
  final int? maxBytes;

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
      'RetentionPolicy(maxAge: $maxAge, maxCount: $maxCount, maxBytes: $maxBytes)';
}

/// One prune candidate: identity, ordering time, and serialized size.
typedef PruneCandidate = ({String id, DateTime timestamp, int bytes});

/// What one prune pass removed. [removedBytes] is the serialized size of
/// the pruned entries — an approximation of what the backing store frees.
class PruneResult {
  const PruneResult({required this.removedCount, required this.removedBytes});

  static const PruneResult empty = PruneResult(
    removedCount: 0,
    removedBytes: 0,
  );

  final int removedCount;
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

/// Serialized byte size of a JSON map — the size unit of [RetentionPolicy.maxBytes].
int bytesOfJson(Map<String, dynamic> json) =>
    utf8.encode(jsonEncode(json)).length;

/// Builds prune candidates for session-tree entries (shared by the
/// [SessionStorage] backends: identity = entry id, time = entry timestamp,
/// size = serialized entry bytes).
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

/// The mission-runner prune hook (issue #135): anything that can sweep
/// stale state between missions. [RetentionCoordinator] is the stock
/// implementation; tests inject fakes.
abstract interface class RetentionSweep {
  Future<void> prune();
}

/// Binds a [UsageLedger] projection to its policy. The ledger is an
/// immutable value object (spec 083) — it cannot prune itself in place —
/// so the owner supplies a [ledger] getter and a [writeback] that receives
/// the pruned projection.
final class UsageLedgerBinding {
  const UsageLedgerBinding({
    required this.ledger,
    required this.writeback,
    required this.policy,
  });

  final UsageLedger Function() ledger;
  final void Function(UsageLedger) writeback;
  final RetentionPolicy policy;
}

/// Aggregated outcome of one [RetentionCoordinator] sweep.
class PruneReport {
  const PruneReport({required this.results});

  final List<PruneResult> results;

  int get totalRemovedCount =>
      results.fold(0, (sum, r) => sum + r.removedCount);

  int get totalRemovedBytes =>
      results.fold(0, (sum, r) => sum + r.removedBytes);
}

/// The stock [RetentionSweep] (issue #135): runs `prune()` over every
/// wired store with its policy. A store axis left out (null store or null
/// policy) is simply not swept; usage-ledger bindings always run.
final class RetentionCoordinator implements RetentionSweep {
  RetentionCoordinator({
    this.sessionStorage,
    this.sessionPolicy,
    this.episodicMemoryStore,
    this.memoryPolicy,
    this.usageLedgers = const [],
    this.eventLog,
    this.eventPolicy,
    this.clock,
  });

  final SessionStorage? sessionStorage;
  final RetentionPolicy? sessionPolicy;
  final EpisodicMemoryStore? episodicMemoryStore;
  final RetentionPolicy? memoryPolicy;
  final List<UsageLedgerBinding> usageLedgers;
  final EngineEventLog? eventLog;
  final RetentionPolicy? eventPolicy;

  /// Injectable clock for maxAge cutoffs (defaults to `DateTime.now`).
  final DateTime Function()? clock;

  @override
  Future<PruneReport> prune() async {
    final now = (clock ?? DateTime.now)();
    final results = <PruneResult>[];

    final storage = sessionStorage;
    final sPolicy = sessionPolicy;
    if (storage != null && sPolicy != null) {
      results.add(await storage.prune(sPolicy, now: now));
    }

    final memory = episodicMemoryStore;
    final mPolicy = memoryPolicy;
    if (memory != null && mPolicy != null) {
      results.add(await memory.prune(mPolicy, now: now));
    }

    for (final binding in usageLedgers) {
      binding.writeback(binding.ledger().prune(binding.policy, now: now));
    }

    final log = eventLog;
    final ePolicy = eventPolicy;
    if (log != null && ePolicy != null) {
      results.add(log.prune(ePolicy, now: now));
    }

    return PruneReport(results: List.unmodifiable(results));
  }
}
