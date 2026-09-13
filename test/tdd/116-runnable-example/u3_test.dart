// GENERATED TEST — `zfa tdd gen U3` (spec 044-test-tdd-generation).
//
// behavior_id: U3
// source_criterion: FR-003, MinimalAgent.subprocess
// kind: unit
// description: A test MUST execute the example as a subprocess and assert
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/116-runnable-example/u3_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

library;

import 'dart:io';

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/116-runnable-example/u3_subject.dart';


void main() {
  group('U3 (FR-003, MinimalAgent.subprocess)', () {
    test('U3 — A test MUST execute the example as a subprocess and assert',
        () async {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? guard;
      try {
        await subject_u3();
        guard = 'ok';
      } on UnimplementedError catch (e) {
        guard = e;
      }
      expect(guard, isNot(isA<UnimplementedError>()));
      final result = await subject_u3();
      expect(result['exitCode'], 0);
      expect(result['hasStart'], isTrue);
      expect(result['hasComplete'], isTrue);
      expect(result['hasStatus'], isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
