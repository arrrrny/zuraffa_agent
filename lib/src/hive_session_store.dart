// NEW file for zuraffa_agent (no pi_agent equivalent; research R1/R4): Hive
// session storage over hive_ce boxes. Source licensed MIT under zuraffa_agent.
// See NOTICE.
//
// The `hive_ce` import lives only here and in `hive_adapters.dart`
// (plan.md quarantine) so JSONL/in-memory paths stay pure-stdlib Dart.
library;

import 'dart:io' as io;

import 'package:hive_ce/hive_ce.dart' as hive;

import 'hive_adapters.dart';
import 'session_storage.dart';
import 'types.dart';

final SessionInfo _defaultMeta = SessionInfo(
  id: '',
  name: '',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Hive-backed session storage (device persistence, FR-003).
///
/// One box named [boxName] stores every session-tree entry keyed by entry id,
/// the current leaf id and [SessionInfo] under reserved keys, and an
/// append-order index (Hive iterates boxes key-sorted, so the index preserves
/// the log order the cross-store equivalence contract requires). Entries are
/// stored through the hand-written adapters in `hive_adapters.dart`.
class HiveSessionStorage implements SessionStorage {
  /// Reserved box key for the current leaf id.
  static const String leafKey = r'$zuraffa.leaf';

  /// Reserved box key for the session metadata.
  static const String metadataKey = r'$zuraffa.metadata';

  /// Reserved box key for the append-order index (list of entry ids).
  static const String orderKey = r'$zuraffa.order';

  /// Name of the Hive box backing this storage.
  final String boxName;

  /// Directory where the Hive box file lives; defaults to Hive's home.
  final String? hivePath;

  hive.Box<Object>? _box;
  List<SessionTreeEntry>? _cache;
  List<String>? _order;
  String? _leafId;
  SessionInfo? _metadata;

  /// Creates Hive storage backed by the named box.
  HiveSessionStorage(this.boxName, {this.hivePath});

  /// The open Hive box, or null before [init] / after [close].
  hive.Box<Object>? get box => _box;

  @override
  Future<StoreOpenResult> init() async {
    registerZuraffaAdapters();
    if (hivePath != null) {
      await io.Directory(hivePath!).create(recursive: true);
    }
    _box ??= await hive.Hive.openBox<Object>(boxName, path: hivePath);
    _loadFromBox();
    return const StoreOpenResult();
  }

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async {
    _cache ??= [];
    _cache!.add(entry);
    _order ??= [];
    _order!.add(entry.id);
    _leafId = entry.id;
    await _box!.put(entry.id, entry);
    await _box!.put(orderKey, _order!);
  }

  @override
  Future<List<SessionTreeEntry>> loadEntries() async {
    _cache ??= _box == null ? [] : _readFromBox();
    return List<SessionTreeEntry>.from(_cache!);
  }

  @override
  Future<SessionTreeEntry?> findEntry(String id) async {
    final entries = await loadEntries();
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> setLeafId(String? leafId) async {
    _leafId = leafId;
    final box = _box!;
    if (leafId == null) {
      await box.delete(leafKey);
    } else {
      await box.put(leafKey, leafId);
    }
  }

  @override
  Future<String?> getLeafId() async => _leafId;

  @override
  Future<void> setMetadata(SessionInfo info) async {
    _metadata = info;
    await _box!.put(metadataKey, info);
  }

  @override
  Future<SessionInfo> getMetadata() async => _metadata ?? _defaultMeta;

  @override
  Future<void> removeEntry(String id) async {
    _order?.remove(id);
    _cache?.removeWhere((e) => e.id == id);
    await _box!.delete(id);
    if (_order != null) {
      await _box!.put(orderKey, _order!);
    }
  }

  @override
  Future<void> close() async {
    if (_box != null) {
      await _box!.close();
      _box = null;
    }
    _cache = null;
    _order = null;
    _leafId = null;
    _metadata = null;
  }

  void _loadFromBox() {
    final box = _box;
    if (box == null) return;
    final order = box.get(orderKey);
    if (order is List) {
      _order = order.cast<String>();
    }
    _cache = _readFromBox();
    final leaf = box.get(leafKey);
    _leafId = leaf is String ? leaf : null;
    final meta = box.get(metadataKey);
    _metadata = meta is SessionInfo ? meta : null;
  }

  List<SessionTreeEntry> _readFromBox() {
    final box = _box;
    if (box == null) return [];
    final byId = <String, SessionTreeEntry>{};
    for (final value in box.values) {
      if (value is SessionTreeEntry) byId[value.id] = value;
    }
    final order = _order;
    if (order != null) {
      return [
        for (final id in order)
          if (byId.containsKey(id)) byId[id]!,
      ];
    }
    // No append-order index (e.g. a box written without one): fall back to
    // Hive's key-sorted iteration, deterministic for monotonic entry ids.
    final entries = byId.values.toList();
    entries.sort((a, b) => a.id.compareTo(b.id));
    return entries;
  }
}
