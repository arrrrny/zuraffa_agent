// GENERATED TEST — `zfa tdd gen U3` (spec 044-test-tdd-generation).
//
// behavior_id: U3
// source_criterion: FR-003, SessionStorage.entries
// kind: unit
// description: `SessionStorage.entries()` MUST return a lazy
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u3_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u3_subject.dart';

void main() {
  group('U3 (FR-003, SessionStorage.entries)', () {
    test('U3 — `SessionStorage.entries()` MUST return a lazy', () async {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? outcome;
      try {
        await subject_u3();
        outcome = 'ok';
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final pulled = await subject_u3();
      // Assertion-shaped guard: an empty stream means unimplemented.
      expect(pulled, isNotEmpty);
      expect(pulled, ['e-0', 'e-1'],
          reason: 'early exit must stop the pull at two entries');
      expect(pulled.length, 2);
    });
  });
}
