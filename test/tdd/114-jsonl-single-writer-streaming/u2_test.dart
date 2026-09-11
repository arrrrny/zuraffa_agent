// GENERATED TEST — `zfa tdd gen U2` (spec 044-test-tdd-generation).
//
// behavior_id: U2
// source_criterion: FR-002, SessionLock.acquire
// kind: unit
// description: `JsonlSessionStorage.init` MUST acquire an advisory
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u2_subject.dart';

void main() {
  group('U2 (FR-002, SessionLock.acquire)', () {
    test('U2 — `JsonlSessionStorage.init` MUST acquire an advisory', () async {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? outcome;
      try {
        await subject_u2();
        outcome = 'ok';
      } on UnimplementedError catch (e) {
        outcome = e;
      }
      expect(outcome, isNot(isA<UnimplementedError>()));
      final message = await subject_u2();
      // Assertion-shaped guard: an unimplemented lock yields ''.
      expect(message, isNotEmpty);
      expect(message, contains('locked by another writer'));
    });
  });
}
