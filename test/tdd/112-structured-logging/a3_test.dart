// GENERATED TEST — `zfa tdd gen A3` (spec 044-test-tdd-generation).
//
// behavior_id: A3
// source_criterion: AC-3
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a3_subject.dart';

void main() {
  group('A3 (AC-3)', () {
    test('A3 — they are filtered out by the hierarchy and only', () {
      final delivered = subject_a3();
      expect(delivered, hasLength(2));
      expect(delivered[0].level, Level.WARNING);
      expect(delivered[0].message, contains('warning record'));
      expect(delivered[1].level, Level.SEVERE);
      expect(delivered[1].message, contains('severe record'));
    });
  });
}
