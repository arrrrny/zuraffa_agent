// InMemorySessionStorage — volatile in-memory store for unit test speed.
//
// No dart:io dependency. JsonlSessionStorage lives in jsonl_session_storage.dart.
// Hand-written integration glue against zfa-generated entity types.

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
  Future<void> close() async {}
}
