// GENERATED TEST — `zfa tdd gen A2` (spec 044-test-tdd-generation).
//
// behavior_id: A2
// source_criterion: AC-2
// kind: acceptance
// description: (see test name)
//
// Hand-stepped assertions (spec 112): the scenario runs against the real
// logging facade; the test name is preserved byte-identical for
// --plain-name matching.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/logging/agent_log.dart';
import 'package:zuraffa_agent/tdd/112-structured-logging/a2_subject.dart';

void main() {
  group('A2 (AC-2)', () {
    test('A2 — nothing is printed, nothing throws, and', ()  {
      final result = subject_a2();
      expect(result['status'], 'silent-ok');
      // Every pinned subsystem emitted all four policy levels.
      expect(result['emitted'], AgentLog.subsystems.length * 4);
      expect(AgentLog.subsystems, hasLength(6));
    });
  });
}
