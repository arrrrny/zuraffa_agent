// InMemorySessionStorage and JsonlSessionStorage implementations.
//
// Hand-written integration glue against zfa-generated entity types only.
// Uses dart:io for file I/O (quarantined per Constitution VII).

import 'dart:convert';
import 'dart:io';

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

/// Human-readable JSONL storage with streaming append and corrupt-tail
/// tear recovery.
///
/// Each line is a JSON-serialized [SessionTreeEntry]. The active leaf ID
/// is stored as the first line with a special `_meta` wrapper.
class JsonlSessionStorage implements SessionStorage {
  JsonlSessionStorage(this.path);

  final String path;

  final Map<String, SessionTreeEntry> _entries = {};
  String _activeLeafId = '';
  bool _dirty = false;

  @override
  Future<StoreOpenResult> init() async {
    final file = File(path);
    if (!await file.exists()) {
      return const StoreOpenResult(loadedEntriesCount: 0);
    }

    final lines = await file.readAsLines();
    int salvagedCount = 0;
    int tearLineNumber = 0;
    String? tearReason;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;

        // Check for meta line (active leaf pointer).
        if (json.containsKey('_meta')) {
          _activeLeafId = json['activeLeafId'] as String? ?? '';
          continue;
        }

        final entry = SessionTreeEntry.fromJson(json);
        _entries[entry.id] = entry;
        salvagedCount++;
      } catch (e) {
        tearLineNumber = i + 1;
        tearReason = 'Malformed JSON at line ${i + 1}: $e';
        break; // Stop at first corrupt line (tear recovery).
      }
    }

    if (tearReason != null) {
      return StoreOpenResult(
        loadedEntriesCount: salvagedCount,
        tearReport: JsonlTear(
          lineNumber: tearLineNumber,
          reason: tearReason,
          salvagedEntryCount: salvagedCount,
        ),
      );
    }

    return StoreOpenResult(loadedEntriesCount: salvagedCount);
  }

  @override
  Future<void> appendEntry(SessionTreeEntry entry) async {
    _entries[entry.id] = entry;
    _dirty = true;

    // Streaming append — write only the new line, not the full file.
    final file = File(path);
    final sink = file.openWrite(mode: FileMode.append);
    sink.writeln(jsonEncode(entry.toJson()));
    await sink.flush();
    await sink.close();
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
    _dirty = true;
  }

  @override
  Future<void> deleteEntries(Set<String> entryIds) async {
    for (final id in entryIds) {
      _entries.remove(id);
    }
    _dirty = true;
  }

  @override
  Future<void> close() async {
    if (!_dirty) return;

    // Rewrite file with current state (after deletions or leaf changes).
    final file = File(path);
    final sink = file.openWrite();

    // Write active leaf meta as first line.
    sink.writeln(jsonEncode({'_meta': true, 'activeLeafId': _activeLeafId}));

    for (final entry in _entries.values) {
      sink.writeln(jsonEncode(entry.toJson()));
    }

    await sink.flush();
    await sink.close();
    _dirty = false;
  }
}
