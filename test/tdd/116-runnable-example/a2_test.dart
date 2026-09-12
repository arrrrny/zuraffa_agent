// GENERATED TEST — `zfa tdd gen A2` (spec 044-test-tdd-generation).
//
// behavior_id: A2
// source_criterion: AC-2
// kind: acceptance
// description: it
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/116-runnable-example/a2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A2:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/116-runnable-example/a2_subject.dart';


void main() {
  group('A2 (AC-2)', () {
    test('A2 — it', ()  {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? outcome;
      try {
        outcome = subject_a2();
        outcome = 'ok';
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final offenders = subject_a2();
      expect(offenders, isEmpty, reason: 'no keys/endpoints in example');
    });
  });
}
