// GENERATED TEST — `zfa tdd gen U4` (spec 044-test-tdd-generation).
//
// behavior_id: U4
// source_criterion: FR-004, SessionStorage.entries
// kind: unit
// description: Hive persistence MUST document its single-writer
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u4_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'dart:io';


import 'package:zuraffa_agent/tdd/114-jsonl-single-writer-streaming/u4_subject.dart';

void main() {
  group('U4 (FR-004, SessionStorage.entries)', () {
    test('U4 — Hive persistence MUST document its single-writer', () {
      final header = File('lib/src/hive_session_store.dart').readAsStringSync();
      // Assertion-shaped guard: a missing marker fails HERE.
      expect(() => subject_u4(header), returnsNormally);
      expect(header, contains('SINGLE-WRITER CONTRACT'));
      expect(header, contains('spec 114'));
    });
  });
}
