// GENERATED TEST — `zfa tdd gen U1` (spec 044-test-tdd-generation).
//
// behavior_id: U1
// source_criterion: FR-001, AgentLog.logger
// kind: unit
// description: `AgentLog` MUST expose the named subsystem loggers `llm`,
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/112-structured-logging/u1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/u1_subject.dart';

void main() {
  group('U1 (FR-001, AgentLog.logger)', () {
    test('U1 — `AgentLog` MUST expose the named subsystem loggers `llm`,', () {
      // Pinned six-subsystem contract (spec 112 FR-001): every name
      // resolves to a Logger under the zuraffa.agent hierarchy.
      expect(subject_u1('llm').fullName, 'zuraffa.agent.llm');
      expect(subject_u1('mcp').fullName, 'zuraffa.agent.mcp');
      expect(subject_u1('engine').fullName, 'zuraffa.agent.engine');
      expect(subject_u1('eval').fullName, 'zuraffa.agent.eval');
      expect(subject_u1('session').fullName, 'zuraffa.agent.session');
      expect(subject_u1('eventBus').fullName, 'zuraffa.agent.eventBus');
      // Off-hierarchy names are refused — consumer routing is by name.
      expect(() => subject_u1('nope'), throwsArgumentError);
    });
  });
}
