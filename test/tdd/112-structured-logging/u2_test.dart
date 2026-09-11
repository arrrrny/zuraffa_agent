// GENERATED TEST — `zfa tdd gen U2` (spec 044-test-tdd-generation).
//
// behavior_id: U2
// source_criterion: FR-002, AgentLog.levelPolicy
// kind: unit
// description: The level policy MUST be pinned as facade constants —
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/112-structured-logging/u2_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.
library;

import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:zuraffa_agent/tdd/112-structured-logging/u2_subject.dart';

void main() {
  group('U2 (FR-002, AgentLog.levelPolicy)', () {
    test('U2 — The level policy MUST be pinned as facade constants —', () {
      final policy = subject_u2();
      // Policy table (spec 112 FR-002): transport FINE, lifecycle INFO,
      // resilience WARNING, terminal SEVERE.
      expect(policy['transport'], Level.FINE);
      expect(policy['lifecycle'], Level.INFO);
      expect(policy['resilience'], Level.WARNING);
      expect(policy['terminal'], Level.SEVERE);
      expect(policy.length, 4);
    });
  });
}
