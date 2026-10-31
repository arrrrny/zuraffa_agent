// HiveSessionStorage — Hive binary storage backend for session tree
// persistence.
//
// Hand-written integration glue against zfa-generated entity types only.
// Uses dart:io indirectly via hive_ce (quarantined per Constitution VII).
//
// SINGLE-WRITER CONTRACT (spec 114, issue #136): Hive boxes are NOT safe
// for cross-process access — one writer per box per process. There is no
// cross-process lock here (the JSONL store has SessionLock); open a
// second process against the same box files only for read-only tooling,
// and never concurrently.

import 'package:hive_ce/hive.dart';

import 'hive_adapters.dart';
import 'retention_policy.dart';
import 'session_backup.dart';
import 'session_storage.dart';
import 'types.dart';

/// Fast binary KV store using [hive_ce] for on-device persistence.
///
/// Entries are stored in a Hive box keyed by their [SessionTreeEntry.id].
/// The active leaf ID is stored in a separate meta box.
class HiveSessionStorage implements SessionStorage {
  /// Creates a hive session storage.
  HiveSessionStorage({required this.boxName});

  /// The box name.
  final String boxName;

  static const _metaBoxName = '_zuraffa_meta';
  static const _activeLeafKey = 'activeLeafId';
  static const _schemaVersionKey = 'schemaVersion';

  late Box<SessionTreeEntry> _entryBox;
  late Box<String> _metaBox;
  bool _initialized = false;

  @override
  Future<StoreOpenResult> init() async {
    registerZuraffaAdapters();

    _entryBox = await Hive.openBox<SessionTreeEntry>(boxName);
    _metaBox = await Hive.openBox<String>(_metaBoxName);
    _initialized = true;

    // Schema-version stamp (spec 110, issue #122): Hive stores hydrated
    // objects rather than raw maps, so value-level migrations are deferred;
    // the stamp makes the persisted version observable. A box without a
    // stamp is legacy (pre-versioning) and is stamped forward.
    final existing = _metaBox.get(_schemaVersionKey);
    final schemaVersion = existing == null
        ? SessionSchema.currentVersion
        : int.parse(existing);
    await _metaBox.put(_schemaVersionKey, '${SessionSchema.currentVersion}');

    return StoreOpenResult(
      loadedEntriesCount: _entryBox.length,
      schemaVersion: SessionSchema.currentVersion,
      migratedFromVersion:
          existing == null || schemaVersion < SessionSchema.currentVersion
          ? schemaVersion
          : null,
    );
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
  Stream<SessionTreeEntry> entries() async* {
    // Lazy pull by key index — no full values materialization.
    for (var i = 0; i < _entryBox.length; i++) {
      final entry = _entryBox.getAt(i);
      if (entry != null) yield entry;
    }
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
  Future<void> backup(String dest) async {
    if (!_initialized) await init();
    await SessionBackupFile.write(
      dest,
      entries: _entryBox.values.toList(),
      activeLeafId: await getActiveLeafId(),
    );
  }

  @override
  Future<void> restore(String src) async {
    if (!_initialized) await init();
    final backup = await SessionBackupFile.read(src);
    final restored = SessionBackupCodec.decodeEntries(backup);

    // Put first, delete stale keys after: a crash mid-restore can never
    // leave the box empty (issue #135's crash-window theme). The keys are
    // dynamic — filter to the String keys this box is written with.
    final restoredIds = <String>{for (final entry in restored) entry.id};
    for (final entry in restored) {
      await _entryBox.put(entry.id, entry);
    }
    final stale = <String>[
      for (final key in _entryBox.keys)
        if (key is String && !restoredIds.contains(key)) key,
    ];
    if (stale.isNotEmpty) {
      await _entryBox.deleteAll(stale);
    }
    await _metaBox.put(_activeLeafKey, backup.activeLeafId ?? '');
  }

  @override
  Future<PruneResult> prune(RetentionPolicy policy, {DateTime? now}) async {
    if (!_initialized) await init();
    final candidates = sessionEntryCandidates(_entryBox.values);
    final victims = selectPruneIds(
      candidates: candidates,
      policy: policy,
      now: now,
    );
    if (victims.isEmpty) return PruneResult.empty;

    final bytesById = {for (final c in candidates) c.id: c.bytes};
    final victimSet = Set<String>.of(victims);
    await _entryBox.deleteAll(victims);
    final leaf = await getActiveLeafId();
    if (leaf != null && victimSet.contains(leaf)) {
      await _metaBox.put(_activeLeafKey, '');
    }
    return PruneResult(
      removedCount: victims.length,
      removedBytes: prunedBytes(victims, bytesById),
    );
  }

  @override
  Future<void> close() async {
    await _entryBox.close();
    await _metaBox.close();
    _initialized = false;
  }
}
