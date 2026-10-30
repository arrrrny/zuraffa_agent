// InMemorySessionStorage — volatile in-memory store for unit test speed.
//
// No dart:io import (constitution VII): backup/restore file I/O delegates
// to the allowlisted session_backup.dart adapter.
// Hand-written integration glue against zfa-generated entity types.

import 'retention.dart';
import 'session_backup.dart';
import 'session_storage.dart';
import 'types.dart';

/// Volatile in-memory store for unit test speed and isolation.
class InMemorySessionStorage implements SessionStorage {
  final Map<String, SessionTreeEntry> _entries = {};
  String _activeLeafId = '';

  @override
  Future<StoreOpenResult> init() async {
    return const StoreOpenResult(loadedEntriesCount: 0);
  }

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<SessionTreeEntry?> getEntry(String id) async {
    return _entries[id];
  }

  @override
  Future<List<SessionTreeEntry>> getEntries() async {
    return _entries.values.toList();
  }

  @override
  Stream<SessionTreeEntry> entries() async* {
    for (final entry in List.of(_entries.values)) {
      yield entry;
    }
  }

  @override
  Future<String?> getActiveLeafId() async {
    return _activeLeafId.isEmpty ? null : _activeLeafId;
  }

  @override
  Future<void> setActiveLeafId(String leafId) async {
    _activeLeafId = leafId;
  }

  @override
  Future<void> deleteEntries(Set<String> entryIds) async {
    for (final id in entryIds) {
      _entries.remove(id);
    }
  }

  @override
  Future<void> backup(String dest) async {
    await SessionBackupFile.write(
      dest,
      entries: _entries.values.toList(),
      activeLeafId: _activeLeafId.isEmpty ? null : _activeLeafId,
    );
  }

  @override
  Future<void> restore(String src) async {
    final backup = await SessionBackupFile.read(src);
    final restored = SessionBackupCodec.decodeEntries(backup);
    _entries
      ..clear()
      ..addAll({for (final entry in restored) entry.id: entry});
    _activeLeafId = backup.activeLeafId ?? '';
  }

  @override
  Future<PruneResult> prune(RetentionPolicy policy, {DateTime? now}) async {
    final candidates = sessionEntryCandidates(_entries.values);
    final victims = selectPruneIds(
      candidates: candidates,
      policy: policy,
      now: now,
    );
    if (victims.isEmpty) return PruneResult.empty;

    final bytesById = {for (final c in candidates) c.id: c.bytes};
    final victimSet = Set<String>.of(victims);
    for (final id in victimSet) {
      _entries.remove(id);
    }
    if (_activeLeafId.isNotEmpty && victimSet.contains(_activeLeafId)) {
      _activeLeafId = '';
    }
    return PruneResult(
      removedCount: victims.length,
      removedBytes: prunedBytes(victims, bytesById),
    );
  }

  @override
  Future<void> close() async {}
}
