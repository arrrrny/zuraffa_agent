// GENERATED TEST — `zfa tdd gen U2` (spec 044-test-tdd-generation).
//
// behavior_id: U2
// source_criterion: FR-002, AgentHomeResolver.compose
// kind: unit
// description: `AgentHomeResolver` MUST compose
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/u2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.


library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/115-agent-platform-packages/u2_subject.dart';



void main() {
  group('U2 (FR-002, AgentHomeResolver.compose)', () {
    test('U2 — `AgentHomeResolver` MUST compose', ()  {
      // Assertion-shaped guard: an empty home fails HERE.
      expect(() => subject_u2(''), throwsStateError);
      expect(() => subject_u2('  '), throwsStateError);
      expect(() => subject_u2(null), throwsStateError);
      final layout = subject_u2('/support/');
      expect(layout.sessions, '/support/sessions');
      expect(layout.memory, '/support/memory');
      expect(layout.artifacts, '/support/artifacts');
      final win = subject_u2('C:\\data\\agent');
      expect(win.sessions, 'C:/data/agent/sessions');
    });
  });
}
