// GENERATED TEST — `zfa tdd gen A4` (spec 044-test-tdd-generation).
//
// behavior_id: A4
// source_criterion: AC-4
// kind: acceptance
// description: an `ArgumentError` names the key requirement and
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a4_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A4:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a4_subject.dart';


void main() {
  group('A4 (AC-4)', () {
    test('A4 — an `ArgumentError` names the key requirement and', ()  {
      expect(() => subject_a4(''), throwsArgumentError);
      expect(() => subject_a4('  '), throwsArgumentError);
      expect(() => subject_a4('k\x00'), throwsArgumentError);
      expect(() => subject_a4('openai'), returnsNormally);
    });
  });
}
