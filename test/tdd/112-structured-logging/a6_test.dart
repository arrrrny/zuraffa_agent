// GENERATED TEST — `zfa tdd gen A6` (spec 044-test-tdd-generation).
//
// behavior_id: A6
// source_criterion: AC-6
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a6_subject.dart';

void main() {
  group('A6 (AC-6)', () {
    test('A6 — an INFO', () async {
      final messages = await subject_a6();
      expect(messages, hasLength(2));
      expect(messages[0], contains('mission m-a6: started'));
      expect(messages[1], contains('mission m-a6: completed'));
    });
  });
}
