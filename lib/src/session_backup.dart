// Session backup/restore envelope + file I/O (issue #135).
//
// The backup envelope IS the versioned session-file format (spec 110) with
// one extra `_backup` provenance line, so a backup file can be opened
// directly as a session store. PS-1 (schema versioning) is honored by the
// `_schema` header line: `restore` refuses snapshots newer than
// [SessionSchema.currentVersion] and migrates older ones through the
// [SessionMigrator] registry.
//
// dart:io is confined to this file per Constitution VII — it is allowlisted
// in .github/workflows/pipeline.yml alongside the other storage adapters;
// all three SessionStorage backends delegate backup I/O here.

import 'dart:convert';
import 'dart:io';

import 'session_migrator.dart';
import 'session_storage.dart';
import 'types.dart';

/// A parsed backup snapshot: envelope metadata plus the raw entry maps
/// (still un-migrated / un-deserialized — [SessionBackupCodec.parse] does
/// no entry work).
final class SessionBackup {
  const SessionBackup({
    required this.schemaVersion,
    this.createdAt,
    this.activeLeafId,
    required this.rawEntries,
  });

  /// The schema version the snapshot was written at.
  final int schemaVersion;

  /// When the snapshot was taken (from the provenance line).
  final DateTime? createdAt;

  /// The active-leaf pointer captured by the snapshot (null when none).
  final String? activeLeafId;

  /// Raw entry maps in snapshot order.
  final List<Map<String, dynamic>> rawEntries;
}

/// Encodes and parses the versioned backup envelope (issue #135).
final class SessionBackupCodec {
  SessionBackupCodec._();

  /// Marker + format id of the provenance line (second line of the envelope).
  static const String backupKey = '_backup';
  static const String formatId = 'zuraffa/session-backup';

  /// The full envelope: `_schema` header, `_backup` provenance, `_meta`
  /// active-leaf (omitted when empty), then one line per entry.
  static List<String> encodeLines({
    required List<SessionTreeEntry> entries,
    String? activeLeafId,
    DateTime? createdAt,
  }) => [
    jsonEncode({
      SessionSchema.headerKey: {'schemaVersion': SessionSchema.currentVersion},
    }),
    jsonEncode({
      backupKey: true,
      'format': formatId,
      'createdAt': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
      'entryCount': entries.length,
    }),
    if (activeLeafId != null && activeLeafId.isNotEmpty)
      jsonEncode({'_meta': true, 'activeLeafId': activeLeafId}),
    for (final entry in entries) jsonEncode(entry.toJson()),
  ];

  /// Parses envelope lines. Strict: a missing header or a snapshot newer
  /// than [SessionSchema.currentVersion] throws (StateError for the
  /// downgrade refusal, FormatException for a headerless/malformed
  /// envelope) — a corrupt backup must fail loudly, not partially restore.
  static SessionBackup parse(List<String> lines) {
    var seenHeader = false;
    int? schemaVersion;
    DateTime? createdAt;
    String? activeLeafId;
    final rawEntries = <Map<String, dynamic>>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final decoded = jsonDecode(trimmed) as Map<String, dynamic>;

      if (!seenHeader) {
        final schema = decoded[SessionSchema.headerKey];
        if (schema is! Map) {
          throw const FormatException(
            'backup envelope has no schema header line',
          );
        }
        final version = schema['schemaVersion'];
        if (version is! int) {
          throw const FormatException(
            'backup header is missing a valid schemaVersion',
          );
        }
        schemaVersion = version;
        if (schemaVersion > SessionSchema.currentVersion) {
          throw StateError(
            'backup schemaVersion $schemaVersion is newer than the supported '
            'version ${SessionSchema.currentVersion} — downgrade is not '
            'supported',
          );
        }
        seenHeader = true;
        continue;
      }
      if (decoded.containsKey(backupKey)) {
        final created = decoded['createdAt'];
        createdAt = created is String ? DateTime.tryParse(created) : null;
        continue;
      }
      if (decoded.containsKey('_meta')) {
        activeLeafId = decoded['activeLeafId'] as String?;
        continue;
      }
      rawEntries.add(decoded);
    }

    if (!seenHeader) {
      throw const FormatException('backup envelope has no schema header line');
    }
    return SessionBackup(
      schemaVersion: schemaVersion!,
      createdAt: createdAt,
      activeLeafId: activeLeafId,
      rawEntries: rawEntries,
    );
  }

  /// Deserializes the raw entry maps, migrating legacy snapshots through
  /// the [SessionMigrator] registry when the snapshot predates the current
  /// schema version.
  static List<SessionTreeEntry> decodeEntries(SessionBackup backup) {
    if (backup.schemaVersion >= SessionSchema.currentVersion) {
      return [
        for (final map in backup.rawEntries)
          SessionTreeEntry.fromJson(Map<String, dynamic>.from(map)),
      ];
    }
    final migrator = SessionMigrator.standard();
    return [
      for (final map in backup.rawEntries)
        SessionTreeEntry.fromJson(
          Map<String, dynamic>.from(migrator.migrate(map)),
        ),
    ];
  }
}

/// File I/O for backup envelopes — the dart:io seam (constitution VII).
final class SessionBackupFile {
  SessionBackupFile._();

  /// Writes the envelope to [dest] atomically (temp file + rename), so a
  /// crash mid-backup cannot leave a truncated snapshot.
  static Future<void> write(
    String dest, {
    required List<SessionTreeEntry> entries,
    String? activeLeafId,
    DateTime? createdAt,
  }) async {
    // Uniquified temp name: two backups of the same dest overlapping in
    // one isolate (or two processes sharing the store) each get their own
    // temp file instead of clobbering one shared `$dest.tmp` before the
    // rename. SessionLock guards the store path, not the dest.
    final tmp = File(
      '$dest.tmp.${pid}_${DateTime.now().microsecondsSinceEpoch}',
    );
    final sink = tmp.openWrite();
    for (final line in SessionBackupCodec.encodeLines(
      entries: entries,
      activeLeafId: activeLeafId,
      createdAt: createdAt,
    )) {
      sink.writeln(line);
    }
    await sink.flush();
    await sink.close();
    final target = File(dest);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(dest);
  }

  /// Reads and parses the snapshot at [src].
  static Future<SessionBackup> read(String src) async {
    final file = File(src);
    if (!await file.exists()) {
      throw FileSystemException('backup snapshot not found', src);
    }
    return SessionBackupCodec.parse(await file.readAsLines());
  }

  /// Rotates N-generation backups around [path] (issue #135, optional AC):
  /// `<path>.backup.(i)` shifts to `<path>.backup.(i+1)` for i =
  /// generations-1 .. 1, then the current file is copied to
  /// `<path>.backup.1`. The oldest generation falls off the cliff.
  static Future<void> rotateGenerations(String path, int generations) async {
    if (generations < 1) return;
    final source = File(path);
    if (!await source.exists()) return;
    for (var i = generations - 1; i >= 1; i--) {
      final older = File('$path.backup.$i');
      if (await older.exists()) {
        await older.rename('$path.backup.${i + 1}');
      }
    }
    await source.copy('$path.backup.1');
  }
}
