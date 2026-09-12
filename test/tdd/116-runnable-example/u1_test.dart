// GENERATED TEST — `zfa tdd gen U1` (spec 044-test-tdd-generation).
//
// behavior_id: U1
// source_criterion: FR-001, MinimalAgent.run
// kind: unit
// description: The example MUST run a full mission through `MissionRunner`
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/116-runnable-example/u1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/116-runnable-example/u1_subject.dart';


void main() {
  group('U1 (FR-001, MinimalAgent.run)', () {
    test('U1 — The example MUST run a full mission through `MissionRunner`', () async {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? outcome;
      try {
        outcome = await subject_u1();
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      expect(outcome, '0', reason: 'the example mission must exit 0');
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
