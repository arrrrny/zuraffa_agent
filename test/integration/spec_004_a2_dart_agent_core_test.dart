// Spec 004 — acceptance behavior A2: with the engine pubspec resolved,
// `dart_agent_core` is NOT a dependency, and any files ported from it carry
// MIT attribution headers (per NOTICE / issue R4).
//
// Repo-invariant acceptance test: scans `lib/` for an import of the removed
// dependency and verifies ported files are attributed. No engine feature is
// required — this locks in the current (correct) dependency posture.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('spec 004 A2 - engine has no dart_agent_core dependency; vendored files attributed', () {
    final libDir = Directory('lib');
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('no file imports package:dart_agent_core', () {
      final violations = <String>[];
      for (final f in dartFiles) {
        final content = f.readAsStringSync();
        if (content.contains("import 'package:dart_agent_core'") ||
            content.contains('import "package:dart_agent_core"')) {
          violations.add(f.path);
        }
      }
      expect(violations, isEmpty,
          reason: 'dart_agent_core must not be a dependency: $violations');
    });

    test('ported files carry MIT attribution + state the dependency is absent', () {
      final ported = dartFiles.where((f) {
        final c = f.readAsStringSync();
        return c.contains('dart_agent_core') &&
            (c.contains('Ported from') || c.contains('port from'));
      }).toList();
      expect(ported, isNotEmpty, reason: 'expected at least one ported file');
      for (final f in ported) {
        final c = f.readAsStringSync();
        expect(c, contains('MIT License'),
            reason: '${f.path} is missing MIT attribution');
        expect(c, contains('NOT a dependency'),
            reason: '${f.path} should state dart_agent_core is not a dependency');
      }
    });
  });
}
