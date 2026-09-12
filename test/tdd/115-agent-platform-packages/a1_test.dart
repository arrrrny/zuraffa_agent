// GENERATED TEST — `zfa tdd gen A1` (spec 044-test-tdd-generation).
//
// behavior_id: A1
// source_criterion: AC-1
// kind: acceptance
// description: sessions/memory/artifacts
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A1:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a1_subject.dart';


void main() {
  group('A1 (AC-1)', () {
    test('A1 — sessions/memory/artifacts', ()  {
      final layout = subject_a1();
      // Assertion-shaped guard: a stub throws here (assertion, honest red).
      expect(layout.sessions, '/support/sessions');
      expect(layout.memory, '/support/memory');
      expect(layout.artifacts, '/support/artifacts');
    });
  });
}
