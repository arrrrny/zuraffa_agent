// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (constitution VIII): re-implemented in-tree per
// specs/009-context-compression-llm/spec.md with this attribution retained.

import '../domain/entities/episodic_memory/episodic_memory.dart';

/// In-memory store for [EpisodicMemory] entries — the `retrieve_memory`
/// surface (spec 009 US2 / FR-003). Persistence belongs to the session-store
/// specs; the engine-loop tool-registry wiring belongs to specs 002/003.
class EpisodicMemoryStore {
  final List<EpisodicMemory> _entries = [];

  /// All entries in insertion order.
  List<EpisodicMemory> get entries => List.unmodifiable(_entries);

  /// Stores an entry (later additions with the same id replace earlier ones).
  void add(EpisodicMemory memory) {
    final existingIndex =
        _entries.indexWhere((m) => m.id == memory.id);
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
}
