// GENERATED TEST — `zfa tdd gen A1` (spec 044-test-tdd-generation).
//
// behavior_id: A1
// source_criterion: AC-1
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/a1_subject.dart';

void main() {
  group('A1 (AC-1)', () {
    test('A1 — both records arrive at the sink carrying logger names `zuraffa.agent.llm`', () {
      final records = subject_a1();
      expect(records, hasLength(2));
      expect(records[0].loggerName, 'zuraffa.agent.llm');
      expect(records[0].level, Level.INFO);
      expect(records[0].message, 'llm lifecycle record');
      expect(records[1].loggerName, 'zuraffa.agent.engine');
      expect(records[1].level, Level.WARNING);
    });
  });
}
