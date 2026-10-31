// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/009-context-compression-llm/spec.md with this attribution retained.

import '../retention_policy.dart';
import '../domain/entities/episodic_memory/episodic_memory.dart';

/// In-memory store for [EpisodicMemory] entries — the `retrieve_memory`
/// surface (spec 009 US2 / FR-003). Persistence belongs to the session-store
/// specs; the engine-loop tool-registry wiring belongs to specs 002/003.
///
/// Issue #135: each entry carries a recording time (`add`'s optional `at`,
/// default now) so [prune] can enforce a [RetentionPolicy] — max age, max
/// count, max bytes — the same axes the session stores support.
class EpisodicMemoryStore {
  final List<EpisodicMemory> _entries = [];

  /// Recording time per entry id — the maxAge clock for [prune].
  final Map<String, DateTime> _recordedAt = {};

  /// All entries in insertion order.
  List<EpisodicMemory> get entries => List.unmodifiable(_entries);

  /// Stores an entry (later additions with the same id replace earlier
  /// ones). [at] stamps the recording time used by retention (issue #135);
  /// defaults to now.
  void add(EpisodicMemory memory, {DateTime? at}) {
    _recordedAt[memory.id] = (at ?? DateTime.now()).toUtc();
    final existingIndex = _entries.indexWhere((m) => m.id == memory.id);
    if (existingIndex >= 0) {
      _entries[existingIndex] = memory;
    } else {
      _entries.add(memory);
    }
  }

  /// Retrieves an entry by id — the snapshot with its original messages.
  EpisodicMemory? retrieve(String id) {
    for (final memory in _entries) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  /// Case-insensitive substring search over the snapshot summaries.
  List<EpisodicMemory> search(String query) {
    final needle = query.toLowerCase();
    if (needle.isEmpty) return const [];
    return [
      for (final memory in _entries)
        if (memory.summary.toLowerCase().contains(needle)) memory,
    ];
  }

  /// Paginated listing in insertion order (oldest first) — spec 010 FR-004.
  ///
  /// [offset] skips the first offset entries; [limit] caps the page size.
  /// A non-positive or null-open limit yields everything from the offset on;
  /// a limit <= 0 yields an empty page (graceful degradation for a
  /// misbehaving model call). An offset beyond the end yields an empty page.
  List<EpisodicMemory> list({int? limit, int offset = 0}) {
    if (limit != null && limit <= 0) return const [];
    if (offset < 0) offset = 0;
    if (offset >= _entries.length) return const [];
    var page = _entries.skip(offset).toList();
    if (limit != null && page.length > limit) {
      page = page.sublist(0, limit);
    }
    return List.unmodifiable(page);
  }

  /// The prune candidates of this store (extension seam: the persistent
  /// subclass reuses them to mirror deletions into the storage backend).
  /// Unrecorded entries fall back to the epoch — they prune as oldest.
  List<PruneCandidate> pruneCandidates() => [
    for (final memory in _entries)
      (
        id: memory.id,
        timestamp:
            _recordedAt[memory.id] ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        bytes: bytesOfJson(memory.toJson()),
      ),
  ];

  /// Erases the given memories in memory — no storage side effects. The
  /// persistent subclass layers storage deletion on top of this seam.
  void evict(Iterable<String> ids) {
    final victimSet = Set<String>.of(ids);
    _entries.removeWhere((m) => victimSet.contains(m.id));
    for (final id in victimSet) {
      _recordedAt.remove(id);
    }
  }

  /// Enforces [policy] against this store (issue #135): drops memories
  /// recorded strictly earlier than `now - maxAge`, keeps only the newest
  /// `maxCount`, and drops oldest-first until the serialized memories fit
  /// `maxBytes`. Returns what was removed.
  Future<PruneResult> prune(RetentionPolicy policy, {DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final candidates = pruneCandidates();
    final victims = selectPruneIds(
      candidates: candidates,
      policy: policy,
      now: clock,
    );
    if (victims.isEmpty) return PruneResult.empty;

    final bytesById = {for (final c in candidates) c.id: c.bytes};
    evict(victims);
    return PruneResult(
      removedCount: victims.length,
      removedBytes: prunedBytes(victims, bytesById),
    );
  }
}
