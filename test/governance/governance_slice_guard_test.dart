// Governance-slice guard (SC-010, SC-012, FR-008, FR-012).
//
// The 205 governance slice must not reintroduce a parallel runtime, a second
// policy engine / approval dispatcher / MCP client, a generated pi
// message/task/submission/session duplicate, a browser import, a Flutter
// dependency, or a global GetIt.instance read. These read the slice's own
// sources and assert the absence.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final sliceDirs = [
    'lib/src/governance',
    'lib/src/approvals',
    'lib/src/observability',
    'lib/src/artifacts',
    'lib/src/mcp',
    'lib/src/eval',
  ];
  final sources = <File>[];
  for (final dir in sliceDirs) {
    final d = Directory(dir);
    if (d.existsSync()) {
      sources.addAll(
        d
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')),
      );
    }
  }

  test('the slice scanned a non-empty source set', () {
    expect(sources, isNotEmpty);
  });

  test('no browser or Flutter import (FR-012)', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(
        text.contains('package:zuraffa_browser'),
        isFalse,
        reason: '${file.path} imports a browser package',
      );
      expect(
        text.contains('package:flutter'),
        isFalse,
        reason: '${file.path} imports Flutter',
      );
    }
  });

  test('no parallel runtime or second engine (SC-010)', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final forbidden in [
        'LlmToolLoop',
        'MissionRunner',
        'GetIt.instance',
      ]) {
        expect(
          text.contains(forbidden),
          isFalse,
          reason: '${file.path} carries $forbidden',
        );
      }
    }
  });

  test(
    'no generated pi message/task/submission/session duplicate (SC-012)',
    () {
      for (final file in sources) {
        final text = file.readAsStringSync();
        for (final forbidden in [
          'class PiMessage',
          'class AgentSubmission',
          'class PiSession',
          'class PiTask',
        ]) {
          expect(
            text.contains(forbidden),
            isFalse,
            reason: '${file.path} declares $forbidden',
          );
        }
      }
    },
  );
}
