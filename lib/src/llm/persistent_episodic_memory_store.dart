// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/010-episodic-memory/spec.md with this attribution retained.

import 'dart:convert';

import '../domain/entities/episodic_memory/episodic_memory.dart';
import '../retention_policy.dart';
import '../session_storage.dart';
import '../types.dart';
import 'episodic_memory_store.dart';

/// The custom-entry kind used to persist episodic memories in the session
/// storage backend (spec 010 FR-005).
const kEpisodicMemoryCustomType = 'episodic_memory';

/// An [EpisodicMemoryStore] that mirrors every entry into the session
/// storage backend and can rebuild itself after an engine restart
/// (spec 010 US3 / FR-005 / SC-003).
///
/// Persistence encoding: one [CustomTreeEntry] per memory whose record is a
/// [CustomEntry] with `customType: 'episodic_memory'` and the memory's JSON
/// as the payload. The CustomEntry escape hatch exists precisely for
/// consumer-defined record kinds, so the pi_agent-ported `types.dart` entry
/// hierarchy stays untouched. Older sessions without such entries restore to
/// an empty memory store.
class PersistentEpisodicMemoryStore extends EpisodicMemoryStore {
  final SessionStorage storage;

  PersistentEpisodicMemoryStore({required this.storage});

  @override
  Future<void> add(EpisodicMemory memory, {DateTime? at}) async {
    // In-memory first (super semantics: same-id entries replace in place).
    // The recording time and the storage timestamp are the SAME stamp so
    // in-memory retention and storage retention agree (issue #135).
    final stamp = (at ?? DateTime.now()).toUtc();
    super.add(memory, at: stamp);

    final encoded = jsonEncode(memory.toJson());
    await storage.appendEntry(
      CustomTreeEntry(
        id: memory.id,
        timestamp: stamp,
        record: CustomEntry(
          id: memory.id,
          timestamp: stamp,
          customType: kEpisodicMemoryCustomType,
          payload: encoded,
        ),
      ),
    );
  }

  /// Rebuilds the in-memory entries from the storage backend — the "engine
  /// restart" path (spec 010 US3 / SC-003).
  ///
  /// Only custom entries with [kEpisodicMemoryCustomType] are considered;
  /// everything else in the session tree is left alone. Insertion order
  /// follows the storage backend's entry order. Malformed payloads are
  /// skipped rather than failing the whole restore (a corrupt single entry
  /// must not lose the remaining memories).
  Future<void> restore() async {
    for (final entry in await storage.getEntries()) {
      if (entry is! CustomTreeEntry) continue;
      if (entry.record.customType != kEpisodicMemoryCustomType) continue;
      final EpisodicMemory memory;
      try {
        final decoded =
            jsonDecode(entry.record.payload) as Map<String, dynamic>;
        memory = EpisodicMemory.fromJson(decoded);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
      // The storage entry's timestamp is the recording time (issue #135):
      // retention policies survive an engine restart.
      super.add(memory, at: entry.timestamp);
    }
  }

  @override
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
    // Mirror the deletion into the storage backend so pruned memories do
    // not resurrect on the next restore (issue #135).
    await storage.deleteEntries(Set<String>.of(victims));
    return PruneResult(
      removedCount: victims.length,
      removedBytes: prunedBytes(victims, bytesById),
    );
  }
}
