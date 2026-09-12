// GENERATED TEST — `zfa tdd gen U2` (spec 044-test-tdd-generation).
//
// behavior_id: U2
// source_criterion: FR-002, MinimalAgent.transcript
// kind: unit
// description: The example MUST print the mission lifecycle (start,
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/116-runnable-example/u2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/116-runnable-example/u2_subject.dart';


void main() {
  group('U2 (FR-002, MinimalAgent.transcript)', () {
    test('U2 — The example MUST print the mission lifecycle (start,', ()  {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? guard;
      try {
        subject_u2(const ['MissionStarted']);
        guard = 'ok';
      } on UnimplementedError catch (e) {
        guard = e;
      }
      expect(guard, isNot(isA<UnimplementedError>()));
      final lines = subject_u2(['MissionStarted', 'MissionCompleted']);
      expect(lines, ['[event] MissionStarted', '[event] MissionCompleted']);
    });
  });
}
