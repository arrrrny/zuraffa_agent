// Issue arrrrny/zuraffa_agent#132 — the append-only JSONL audit sink.
//
// Mirrors the JsonlEntityStorage / JsonlSessionStorage persistence
// conventions (one JSON object per line, corrupt-line skip on read,
// quarantined dart:io) with ONE deliberate difference: an audit trail is
// TAMPER-EVIDENT, so this sink never rewrites the log file. Where
// JsonlEntityStorage persists by rewriting the full file (tmp + rename —
// correct for entity stores), this sink opens the file in FileMode.append
// ONLY: bytes already on disk survive every append byte-for-byte.
//
// Retention (issue #132 AC, on top of the PS-3 RetentionPolicy, #135)
// therefore never truncates either:
//   - maxCount / maxBytes — when the ACTIVE segment can no longer accept an
//     entry within budget, the segment is renamed whole into an archive
//     (`<path>.<epochMs>`) and the trail continues in a fresh file. Rename
//     preserves bytes; nothing is destroyed.
//   - maxAge — archive segments whose last write is strictly older than
//     maxAge are DELETED. The active file is never expired, rewritten, or
//     truncated.
//
// Single-writer discipline (spec 114 precedent): a process-wide
// `package:synchronized` mutex serializes appends, so interleaved callers
// never interleave bytes.

import 'dart:convert';
import 'dart:io';

import 'package:synchronized/synchronized.dart';

import '../retention_policy.dart';
import 'audit_log.dart';

/// Append-only JSONL audit sink with retention by whole-segment rotation.
class JsonlAuditSink implements AuditSink {
  /// Creates a jsonl audit sink.
  JsonlAuditSink(
    this.path, {
    this.retention = const RetentionPolicy.unlimited(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The active segment path. Archive segments live next to it as
  /// `<path>.<epochMs>`.
  final String path;

  /// Per-active-segment budget (PS-3 [RetentionPolicy], #135). Unlimited by
  /// default — no rotation, no expiry.
  final RetentionPolicy retention;

  final DateTime Function() _clock;
  final Lock _mutex = Lock();

  bool _indexed = false;
  int _entryCount = 0;
  int _fileBytes = 0;
  bool _endsWithNewline = true;

  @override
  Future<void> append(AuditEntry entry) {
    return _mutex.synchronized(() async {
      await _ensureIndexedLocked();
      await _expireArchivesLocked();

      final line = utf8.encode('${jsonEncode(entry.toJson())}\n');
      if (_needsRotationLocked(line.length)) {
        await _rotateLocked();
      }

      // Append-only: the ONLY mode this sink ever opens the log with.
      final sink = File(path).openWrite(mode: FileMode.append);
      if (!_endsWithNewline) {
        // Tear repair: a crash mid-append can leave the file without its
        // trailing newline. Prepending one newline re-establishes the line
        // boundary WITHOUT touching any existing byte.
        sink.write('\n');
      }
      sink.add(line);
      await sink.flush();
      await sink.close();

      if (!_endsWithNewline) {
        _fileBytes += 1;
        _endsWithNewline = true;
      }
      _fileBytes += line.length;
      _entryCount += 1;
    });
  }

  @override
  Future<List<AuditEntry>> entries() {
    return _mutex.synchronized(() async {
      final file = File(path);
      if (!await file.exists()) return const <AuditEntry>[];
      return _parseEntries(await file.readAsBytes());
    });
  }

  /// Every entry across all segments (archives oldest-first, then the
  /// active segment) — the full trail as currently on disk.
  Future<List<AuditEntry>> allEntries() {
    return _mutex.synchronized(() async {
      final entries = <AuditEntry>[];
      for (final segment in await _segmentPathsLocked()) {
        final file = File(segment);
        if (await file.exists()) {
          entries.addAll(_parseEntries(await file.readAsBytes()));
        }
      }
      return entries;
    });
  }

  /// All segment paths, archives (oldest first) then the active segment.
  Future<List<String>> segmentPaths() {
    return _mutex.synchronized(_segmentPathsLocked);
  }

  // -- Internals (caller holds the mutex). ---------------------------------

  Future<void> _ensureIndexedLocked() async {
    if (_indexed) return;
    _indexed = true;
    final file = File(path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    _fileBytes = bytes.length;
    if (bytes.isEmpty) return;
    _endsWithNewline = bytes.last == 0x0A;
    // Count the VALID lines for maxCount budgeting. Corrupt lines stay
    // budgeted by bytes (they are still on disk) but are not entries.
    for (final raw in LineSplitter.split(
      utf8.decode(bytes, allowMalformed: true),
    )) {
      if (raw.trim().isEmpty) continue;
      try {
        AuditEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _entryCount += 1;
      } catch (_) {
        // Tear recovery: skip, never repair in place.
      }
    }
  }

  bool _needsRotationLocked(int incomingBytes) {
    final maxCount = retention.maxCount;
    if (maxCount != null && _entryCount >= maxCount) return true;
    final maxBytes = retention.maxBytes;
    // An empty segment always accepts the entry — a trail never drops its
    // newest event even when one entry alone exceeds the budget.
    if (maxBytes != null &&
        _fileBytes > 0 &&
        _fileBytes + incomingBytes > maxBytes) {
      return true;
    }
    return false;
  }

  Future<void> _rotateLocked() async {
    final file = File(path);
    if (!await file.exists()) {
      _entryCount = 0;
      _fileBytes = 0;
      _endsWithNewline = true;
      return;
    }
    var stamp = _clock().toUtc().millisecondsSinceEpoch;
    var target = '$path.$stamp';
    while (await File(target).exists()) {
      stamp += 1; // same-ms rotation: bump until the name is free
      target = '$path.$stamp';
    }
    // Rename, never rewrite: the segment's bytes move whole.
    await file.rename(target);
    _entryCount = 0;
    _fileBytes = 0;
    _endsWithNewline = true;
  }

  Future<void> _expireArchivesLocked() async {
    final maxAge = retention.maxAge;
    if (maxAge == null) return;
    final cutoff = _clock().subtract(maxAge);
    for (final segment in await _segmentPathsLocked()) {
      if (segment == path) continue; // the active file is never expired
      final file = File(segment);
      if (!await file.exists()) continue;
      final modified = await file.lastModified();
      if (modified.isBefore(cutoff)) {
        try {
          await file.delete();
        } on FileSystemException {
          // A concurrently removed archive is already the desired state.
        }
      }
    }
  }

  Future<List<String>> _segmentPathsLocked() async {
    final active = File(path);
    final name = path.split(Platform.pathSeparator).last;
    final archives = <String>[];
    await for (final entity in active.parent.list()) {
      if (entity is! File) continue;
      final entityName = entity.path.split(Platform.pathSeparator).last;
      if (!entityName.startsWith('$name.')) continue;
      final suffix = entityName.substring(name.length + 1);
      if (int.tryParse(suffix) == null) {
        continue; // archives are `<path>.<epochMs>`
      }
      archives.add(entity.path);
    }
    archives.sort((a, b) => _archiveStamp(a).compareTo(_archiveStamp(b)));
    return [...archives, if (await active.exists()) path];
  }

  int _archiveStamp(String segmentPath) =>
      int.parse(segmentPath.substring(segmentPath.lastIndexOf('.') + 1));

  List<AuditEntry> _parseEntries(List<int> bytes) {
    final entries = <AuditEntry>[];
    for (final raw in LineSplitter.split(
      utf8.decode(bytes, allowMalformed: true),
    )) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      try {
        entries.add(
          AuditEntry.fromJson(jsonDecode(line) as Map<String, dynamic>),
        );
      } catch (_) {
        // Tear recovery: a corrupt line is skipped, never repaired.
      }
    }
    return entries;
  }
}
