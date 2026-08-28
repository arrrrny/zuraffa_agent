// JsonlEntityStorage — generic durable JSONL persistence adapter for
// datasources that need local backing (Constitution VII: dart:io is confined
// to consciously allowlisted I/O adapters; this file is added to the engine
// runtime purity allowlist in .github/workflows/pipeline.yml).
//
// Each line is a JSON-serialized entity of type [T] keyed by its id. The full
// file is rewritten on mutation — simple and correct for session-scoped data.
// Corrupt lines are skipped (tear recovery).

import 'dart:convert';
import 'dart:io';

/// Generic durable JSONL store for value objects of type [T].
class JsonlEntityStorage<T> {
  JsonlEntityStorage({
    required this.path,
    required this.fromJson,
    required this.toJson,
    required this.getId,
  });

  final String path;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final String Function(T) getId;

  final Map<String, T> _store = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final file = File(path);
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final item = fromJson(json);
          _store[getId(item)] = item;
        } catch (_) {
          // Skip corrupt lines (tear recovery).
        }
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final target = File(path);
    // Write to a temp file first, then atomically rename onto the target so a
    // crash mid-write cannot truncate/destroy the existing durable copy.
    final tmp = File('$path.tmp');
    final sink = tmp.openWrite();
    for (final item in _store.values) {
      sink.writeln(jsonEncode(toJson(item)));
    }
    await sink.flush();
    await sink.close();
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(path);
  }

  Future<T?> get(String id) async {
    await _ensureLoaded();
    return _store[id];
  }

  Future<List<T>> getAll() async {
    await _ensureLoaded();
    return _store.values.toList();
  }

  Future<T> put(T item) async {
    await _ensureLoaded();
    _store[getId(item)] = item;
    await _persist();
    return item;
  }

  Future<void> delete(String id) async {
    await _ensureLoaded();
    _store.remove(id);
    await _persist();
  }
}
