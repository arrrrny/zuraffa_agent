// GENERATED TEST — `zfa tdd gen U1` (spec 044-test-tdd-generation).
//
// behavior_id: U1
// source_criterion: FR-001, JsonlSessionStorage.guard
// kind: unit
// description: Every `JsonlSessionStorage` mutation (`appendEntry`,
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u1_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u1_subject.dart';

void main() {
  group('U1 (FR-001, JsonlSessionStorage.guard)', () {
    test('U1 — Every `JsonlSessionStorage` mutation (`appendEntry`,', () async {
      final ids = await subject_u1(null);
      expect(ids, ['u1-a', 'u1-b'],
          reason: 'interleaved mutations all survive the mutex');
    });
  });
}
