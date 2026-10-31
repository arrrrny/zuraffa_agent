// Issue arrrrny/zuraffa_agent#132 — JsonlAuditSink: the append-only JSONL
// audit sink with tamper-evidence and configurable retention.
//
// Tamper-evidence contract pinned here (the AC's "append-only — open-file
// in append mode, never truncate"):
//
//   - the sink opens the log file in FileMode.append ONLY; bytes already in
//     the file survive every append byte-for-byte as a strict prefix;
//   - no temp-file rewrite exists in this sink (unlike JsonlEntityStorage,
//     whose tmp+rename rewrite is correct for entity stores but forbidden
//     for an audit trail);
//   - a torn tail (crash mid-append, missing trailing newline) is repaired
//     by appending a newline — prior bytes are never touched;
//   - retention NEVER truncates: when the active segment exceeds the
//     RetentionPolicy budget it is renamed whole into an archive segment
//     and the trail continues in a fresh file, so every byte ever written
//     stays on disk (in some segment) until maxAge expires ARCHIVES —
//     the active file is never deleted, rewritten, or truncated.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/retention_policy.dart';
import 'package:zuraffa_agent/src/security/audit_log.dart';
import 'package:zuraffa_agent/src/security/jsonl_audit_sink.dart';

AuditEntry _entry(String marker, {DateTime? at}) => AuditEntry(
  id: 'id-$marker',
  timestamp: at ?? DateTime.utc(2026, 1, 1, 12),
  category: AuditCategory.toolCall,
  action: AuditActions.toolInvoked,
  details: {'marker': marker},
);

/// Reads the raw bytes of [path], or an empty byte list when absent.
Future<List<int>> _rawBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) return const [];
  return file.readAsBytes();
}

void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('audit-132');
    path = '${dir.path}/audit.jsonl';
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('JsonlAuditSink — tamper evidence (append-only)', () {
    test(
      'pre-existing bytes survive appends byte-for-byte (never truncate)',
      () async {
        final first = JsonlAuditSink(path);
        await first.append(_entry('a'));
        await first.append(_entry('b'));
        final original = await _rawBytes(path);
        expect(original, isNotEmpty);

        // A fresh sink over the same file must append, never rewrite.
        final second = JsonlAuditSink(path);
        await second.append(_entry('c'));

        final after = await _rawBytes(path);
        expect(after.length, greaterThan(original.length));
        // Strict-prefix check: the original bytes are untouched.
        expect(List<int>.of(after.sublist(0, original.length)), original);
        expect(await second.entries(), hasLength(3));
      },
    );

    test(
      'a torn tail (no trailing newline) is repaired by appending only',
      () async {
        final first = JsonlAuditSink(path);
        await first.append(_entry('a'));
        // Simulate a crash mid-append: an unterminated partial line.
        await File(
          path,
        ).writeAsBytes('{"id":"torn"'.codeUnits, mode: FileMode.append);
        final torn = await _rawBytes(path);

        final second = JsonlAuditSink(path);
        await second.append(_entry('b'));

        final after = await _rawBytes(path);
        // Every original byte — including the torn fragment — still present.
        expect(List<int>.of(after.sublist(0, torn.length)), torn);
        // The repair is one appended newline; then the new entry.
        expect(after[torn.length], 0x0A);
        // The projection skips the corrupt fragment and yields both valid
        // entries.
        final entries = await second.entries();
        expect(entries.map((e) => e.details['marker']), ['a', 'b']);
      },
    );

    test('no temp-file rewrite artifacts are ever created', () async {
      final sink = JsonlAuditSink(path);
      await sink.append(_entry('a'));
      await sink.append(_entry('b'));

      final names = await dir.list().map((e) => e.path).toList();
      expect(
        names.where((n) => n.endsWith('.tmp') || n.endsWith('.rewriting')),
        isEmpty,
      );
    });

    test(
      'concurrent appends serialize — every entry survives intact',
      () async {
        final sink = JsonlAuditSink(path);
        await Future.wait([
          for (var i = 0; i < 10; i++) sink.append(_entry('c$i')),
        ]);

        final entries = await sink.entries();
        expect(entries, hasLength(10));
        expect(entries.map((e) => e.details['marker']).toSet(), {
          for (var i = 0; i < 10; i++) 'c$i',
        });
        // Every line still parses — no interleaved corruption.
        final lines = await File(path).readAsLines();
        expect(lines.where((l) => l.trim().isNotEmpty), hasLength(10));
      },
    );

    test('entries() skips corrupt lines (tear recovery, JsonlEntityStorage '
        'parity)', () async {
      final sink = JsonlAuditSink(path);
      await sink.append(_entry('a'));
      await File(path).writeAsString('not-json\n', mode: FileMode.append);
      await sink.append(_entry('b'));

      expect((await sink.entries()).map((e) => e.details['marker']), [
        'a',
        'b',
      ]);
    });
  });

  group('JsonlAuditSink — configurable retention', () {
    test('unlimited (default) never rotates', () async {
      final sink = JsonlAuditSink(path);
      for (var i = 0; i < 10; i++) {
        await sink.append(_entry('e$i'));
      }
      expect((await sink.entries()).length, 10);
      expect(await sink.segmentPaths(), [path]);
    });

    test('maxCount rotates the active segment whole into an archive — every '
        'byte stays on disk', () async {
      final sink = JsonlAuditSink(
        path,
        retention: const RetentionPolicy(maxCount: 2),
      );
      for (var i = 0; i < 5; i++) {
        await sink.append(_entry('e$i'));
      }

      final segments = await sink.segmentPaths();
      expect(segments.length, 3, reason: '2 archives + the active segment');
      expect(segments.last, path);

      // The first archive holds the original bytes of the rotated segment —
      // rename, not rewrite.
      final archiveBytes = await _rawBytes(segments.first);
      expect(archiveBytes, isNotEmpty);
      expect((await sink.allEntries()).map((e) => e.details['marker']), [
        'e0',
        'e1',
        'e2',
        'e3',
        'e4',
      ]);
      // The active segment holds only the post-rotation entries.
      expect((await sink.entries()).map((e) => e.details['marker']), ['e4']);
    });

    test('maxBytes rotates before the budget is exceeded', () async {
      // The serialized size of one entry line, newline included — the same
      // unit the sink budgets with.
      final entryBytes = utf8
          .encode('${jsonEncode(_entry('e0').toJson())}\n')
          .length;
      final sink = JsonlAuditSink(
        path,
        retention: RetentionPolicy(maxBytes: entryBytes * 2 + 8),
      );
      for (var i = 0; i < 4; i++) {
        await sink.append(_entry('e$i'));
      }

      final segments = await sink.segmentPaths();
      expect(segments.length, greaterThanOrEqualTo(2));
      // The active segment never accumulates far beyond the budget (a single
      // entry larger than the budget is still appended — a trail never drops
      // its newest event).
      final activeBytes = (await _rawBytes(path)).length;
      expect(activeBytes, lessThan(entryBytes * 2 + 8 + entryBytes + 2));
      expect((await sink.allEntries()), hasLength(4));
    });

    test(
      'maxAge expires archived segments but never the active file',
      () async {
        final sink = JsonlAuditSink(
          path,
          retention: const RetentionPolicy(maxAge: Duration(hours: 1)),
        );
        // Rotate twice via maxCount-like pressure: use a second sink to build
        // archives, then expire them.
        final rotator = JsonlAuditSink(
          path,
          retention: const RetentionPolicy(maxCount: 1),
        );
        await rotator.append(_entry('old-1'));
        await rotator.append(_entry('old-2'));
        await rotator.append(_entry('old-3'));

        final segmentsBefore = await rotator.segmentPaths();
        final archives = segmentsBefore.sublist(0, segmentsBefore.length - 1);
        expect(archives, hasLength(2));

        // Age the archives past maxAge — but only one of them.
        final cutoff = DateTime.now().subtract(const Duration(hours: 2));
        await File(archives.first).setLastModified(cutoff);
        await File(
          archives.last,
        ).setLastModified(DateTime.now().subtract(const Duration(minutes: 5)));

        // The next append runs the expiry sweep.
        await sink.append(_entry('fresh'));

        final segmentsAfter = await sink.segmentPaths();
        expect(
          segmentsAfter,
          contains(archives.last),
          reason: 'a young archive survives',
        );
        expect(
          segmentsAfter,
          isNot(contains(archives.first)),
          reason: 'an archive older than maxAge is expired',
        );
        expect(
          segmentsAfter.last,
          path,
          reason:
              'the active file is never '
              'deleted or rewritten by retention',
        );
        expect(
          (await sink.allEntries()).map((e) => e.details['marker']),
          contains('fresh'),
        );
      },
    );

    test(
      'segmentPaths lists archives oldest-first with the active last',
      () async {
        final sink = JsonlAuditSink(
          path,
          retention: const RetentionPolicy(maxCount: 1),
        );
        for (var i = 0; i < 3; i++) {
          await sink.append(_entry('e$i'));
        }
        final segments = await sink.segmentPaths();
        expect(segments.length, 3);
        // Archive names carry the rotation epoch — lexically sorted is
        // chronologically sorted.
        final archives = segments.sublist(0, segments.length - 1);
        expect([...archives]..sort(), archives);
      },
    );
  });
}
