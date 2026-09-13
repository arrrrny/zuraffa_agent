// GENERATED TEST — `zfa tdd gen A2` (spec 044-test-tdd-generation).
//
// behavior_id: A2
// source_criterion: AC-2
// kind: acceptance
// description: it throws `StateError` naming the failure — never a
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A2:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a2_subject.dart';


void main() {
  group('A2 (AC-2)', () {
    test('A2 — it throws `StateError` naming the failure — never a', ()  {
      // Assertion-shaped guard.
      expect(() => subject_a2(), throwsStateError);
    });
  });
}
