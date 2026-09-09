// JsonlSessionStorage — streaming append JSONL persistence with corrupt-tail
// tear recovery.
//
// Quarantined dart:io usage (Constitution VII). This file is the ONLY storage
// implementation that imports dart:io.
//
// Hand-written integration glue against zfa-generated entity types.

import 'dart:convert';
import 'dart:io';

import 'session_migrator.dart';
import 'session_storage.dart';
import 'types.dart';

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
      // Fresh store: born at the current schema version (spec 110).
      await _writeHeader(file);
      return const StoreOpenResult(
        loadedEntriesCount: 0,
        schemaVersion: SessionSchema.currentVersion,
      );
    }

    final lines = await file.readAsLines();
    int salvagedCount = 0;
    int tearLineNumber = 0;
    String? tearReason;

    // Schema-version detection (spec 110, issue #122): the header line is
    // the FIRST line; its absence marks a legacy v1 file. An undecodable
    // first line means "no header" — the main loop's tear scan reports it
    // exactly as before this spec.
    int? headerVersion;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final decoded = jsonDecode(line) as Map<String, dynamic>;
        if (decoded.containsKey(SessionSchema.headerKey)) {
          final schema =
              decoded[SessionSchema.headerKey] as Map<String, dynamic>;
          headerVersion = schema['schemaVersion'] as int;
          if (headerVersion > SessionSchema.currentVersion) {
            throw StateError(
              'session file schemaVersion $headerVersion is newer than the '
              'supported version ${SessionSchema.currentVersion} — downgrade '
              'is not supported',
            );
          }
          lines[i] = ''; // header consumed — never surfaced as an entry
        }
      } on FormatException {
        break; // no header — tear scan handles the corrupt line below
      }
      break; // the header (if any) is the first non-empty line
    }
    final fromVersion = headerVersion ?? 1;
    final needsMigration = fromVersion < SessionSchema.currentVersion;
    final migrator = needsMigration ? SessionMigrator.standard() : null;

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

        // Legacy file: migrate the raw map through the registry before
        // deserialization (spec 110).
        final raw = needsMigration ? migrator!.migrate(json) : json;
        final entry = SessionTreeEntry.fromJson(raw);
        _entries[entry.id] = entry;
        lines[i] = needsMigration ? jsonEncode(entry.toJson()) : line;
        salvagedCount++;
      } catch (e) {
        tearLineNumber = i + 1;
        tearReason = 'Malformed JSON at line ${i + 1}: $e';
        break; // Stop at first corrupt line (tear recovery).
      }
    }

    // A migrated (or header-less) file is rewritten atomically with the
    // current-version header so the NEXT open is a native open.
    if (needsMigration || headerVersion == null) {
      await _rewriteWithHeader(file, lines);
    }

    if (tearReason != null) {
      return StoreOpenResult(
        loadedEntriesCount: salvagedCount,
        tearReport: JsonlTear(
          lineNumber: tearLineNumber,
          reason: tearReason,
          salvagedEntryCount: salvagedCount,
        ),
        schemaVersion: SessionSchema.currentVersion,
        migratedFromVersion: needsMigration ? fromVersion : null,
      );
    }

    return StoreOpenResult(
      loadedEntriesCount: salvagedCount,
      schemaVersion: SessionSchema.currentVersion,
      migratedFromVersion: needsMigration ? fromVersion : null,
    );
  }

  /// Writes the current-version header as the first line of a fresh store.
  Future<void> _writeHeader(File file) async {
    final sink = file.openWrite(mode: FileMode.write);
    sink.writeln(_headerLine());
    await sink.flush();
    await sink.close();
  }

  /// Atomic rewrite (temp + rename) with the current-version header, the
  /// migrated entry lines, and the active-leaf meta line.
  Future<void> _rewriteWithHeader(File file, List<String> lines) async {
    final tmp = File('$path.migrating');
    final sink = tmp.openWrite(mode: FileMode.write);
    sink.writeln(_headerLine());
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      sink.writeln(trimmed);
    }
    if (_activeLeafId.isNotEmpty) {
      sink.writeln(jsonEncode({'_meta': true, 'activeLeafId': _activeLeafId}));
    }
    await sink.flush();
    await sink.close();
    await tmp.rename(path);
  }

  static String _headerLine() => jsonEncode({
    SessionSchema.headerKey: {'schemaVersion': SessionSchema.currentVersion},
  });

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
