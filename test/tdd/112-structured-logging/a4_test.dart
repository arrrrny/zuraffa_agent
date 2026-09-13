// GENERATED TEST — `zfa tdd gen A4` (spec 044-test-tdd-generation).
//
// behavior_id: A4
// source_criterion: AC-4
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a4_subject.dart';

void main() {
  group('A4 (AC-4)', () {
    test('A4 — transport is FINE, lifecycle is INFO, resilience (retry,', ()  {
      final policy = subject_a4();
      expect(policy['transport'], Level.FINE);
      expect(policy['lifecycle'], Level.INFO);
      expect(policy['resilience'], Level.WARNING);
      expect(policy['terminal'], Level.SEVERE);
    });
  });
}
