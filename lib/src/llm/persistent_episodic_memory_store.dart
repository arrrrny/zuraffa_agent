// Runtime lineage: ported from dart_agent_core (MIT License, Copyright (c)
// 2024-2026 contributors) — see NOTICE. dart_agent_core is NOT a dependency
// of this package (constitution VIII): re-implemented in-tree per
// specs/010-episodic-memory/spec.md with this attribution retained.

import 'dart:convert';

import '../domain/entities/episodic_memory/episodic_memory.dart';
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
  Future<void> add(EpisodicMemory memory) async {
    // In-memory first (super semantics: same-id entries replace in place).
    super.add(memory);

    final encoded = jsonEncode(memory.toJson());
    final now = DateTime.now().toUtc();
    await storage.appendEntry(CustomTreeEntry(
      id: memory.id,
      timestamp: now,
      record: CustomEntry(
        id: memory.id,
        timestamp: now,
        customType: kEpisodicMemoryCustomType,
        payload: encoded,
      ),
    ));
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
      super.add(memory);
    }
  }
}
