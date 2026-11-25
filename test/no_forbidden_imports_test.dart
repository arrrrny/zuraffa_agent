// Forbidden-import / no-parallel-runtime guard (SC-003, SC-004, FR-004, FR-008).
//
// The next-major wrapper must carry no re-implementation of the agent loop,
// provider call, transcript store, compaction, or durable scheduler, and must
// import no browser package or host application. These tests read the package's
// own lib/ sources and assert the absence.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final libDir = Directory('lib');
  final sources = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/ is non-empty (the guard actually scanned sources)', () {
    expect(sources, isNotEmpty);
  });

  test('no browser package import', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(
        text.contains('package:zuraffa_browser'),
        isFalse,
        reason: '${file.path} imports a browser package',
      );
    }
  });

  test('no parallel runtime (LlmToolLoop / MissionRunner)', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(
        text.contains('LlmToolLoop'),
        isFalse,
        reason: '${file.path} carries LlmToolLoop',
      );
      expect(
        text.contains('MissionRunner'),
        isFalse,
        reason: '${file.path} carries MissionRunner',
      );
    }
  });

  test('no global service-locator read in business logic', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(
        text.contains('GetIt.instance'),
        isFalse,
        reason: '${file.path} reads GetIt.instance',
      );
    }
  });
}
