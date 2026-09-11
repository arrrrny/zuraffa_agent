// GENERATED TEST — `zfa tdd gen A6` (spec 044-test-tdd-generation).
//
// behavior_id: A6
// source_criterion: AC-6
// kind: acceptance
// description: the channel method names and argument maps match the
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a6_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A6:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'dart:io';

import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a6_subject.dart';


void main() {
  group('A6 (AC-6)', () {
    test('A6 — the channel method names and argument maps match the', ()  {
      expect(subject_a6('getAgentHome', {}), 'ok');
      expect(subject_a6('secureRead', {'key': 'k'}), 'ok');
      expect(subject_a6('secureWrite', {'key': 'k', 'value': 'v'}), 'ok');
      expect(subject_a6('secureDelete', {'key': 'k'}), 'ok');
      expect(subject_a6('nope', {}), 'bad-method');
      expect(subject_a6('secureRead', {}), 'bad-args');
      // The interface package source pins the same contract.
      final src = File('packages/zuraffa_agent_platform_interface/lib/src/method_channel_platform.dart').readAsStringSync();
      for (final m in a6MethodNames) {
        expect(src, contains("'$m'"), reason: 'channel method $m unpinned');
      }
      expect(src, contains(a6ChannelName));
    });
  });
}
