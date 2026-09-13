// GENERATED TEST — `zfa tdd gen A5` (spec 044-test-tdd-generation).
//
// behavior_id: A5
// source_criterion: AC-5
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a5_subject.dart';

void main() {
  group('A5 (AC-5)', () {
    test('A5 — a', () async {
      final result = await subject_a5();
      expect(result['calls'], 2);
      final message = result['message'] as String;
      expect(message, contains('attempt=1'));
      expect(message, contains('delay=250ms'));
      expect(message, contains('boom'));
    });
  });
}
