// HiveSessionStorage — Hive binary storage backend for session tree persistence.
//
// Hand-written integration glue against zfa-generated entity types only.
// Uses dart:io indirectly via hive_ce (quarantined per Constitution VII).

import 'package:hive_ce/hive.dart';

import 'hive_adapters.dart';
import 'session_storage.dart';
import 'types.dart';

/// Fast binary KV store using [hive_ce] for on-device persistence.
///
/// Entries are stored in a Hive box keyed by their [SessionTreeEntry.id].
/// The active leaf ID is stored in a separate meta box.
class HiveSessionStorage implements SessionStorage {
  HiveSessionStorage({required this.boxName});

  final String boxName;

  static const _metaBoxName = '_zuraffa_meta';
  static const _activeLeafKey = 'activeLeafId';

  late Box<SessionTreeEntry> _entryBox;
  late Box<String> _metaBox;

  @override
  Future<StoreOpenResult> init() async {
    registerZuraffaAdapters();

    _entryBox = await Hive.openBox<SessionTreeEntry>(boxName);
    _metaBox = await Hive.openBox<String>(_metaBoxName);

    return StoreOpenResult(loadedEntriesCount: _entryBox.length);
  }

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async {
    await _entryBox.put(entry.id, entry);
  }

  @override
  Future<SessionTreeEntry?> getEntry(String id) async {
    return _entryBox.get(id);
  }

  @override
  Future<List<SessionTreeEntry>> getEntries() async {
    return _entryBox.values.toList();
  }

  @override
  Future<String?> getActiveLeafId() async {
    final id = _metaBox.get(_activeLeafKey);
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  Future<void> setActiveLeafId(String leafId) async {
    await _metaBox.put(_activeLeafKey, leafId);
  }

  @override
  Future<void> deleteEntries(Set<String> entryIds) async {
    await _entryBox.deleteAll(entryIds.toList());
  }

  @override
  Future<void> close() async {
    await _entryBox.close();
    await _metaBox.close();
  }
}
