// GENERATED TEST — `zfa tdd gen A1` (spec 044-test-tdd-generation).
//
// behavior_id: A1
// source_criterion: AC-1
// kind: acceptance
// description: it exits 0 and prints
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/116-runnable-example/a1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A1:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/116-runnable-example/a1_subject.dart';


void main() {
  group('A1 (AC-1)', () {
    test('A1 — it exits 0 and prints', () async {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? outcome;
      String? exitCode;
      try {
        exitCode = await subject_a1();
        outcome = 'ok';
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      expect(exitCode, '0', reason: 'the example must exit 0');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
