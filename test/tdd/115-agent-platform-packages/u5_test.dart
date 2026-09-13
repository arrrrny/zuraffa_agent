// GENERATED TEST — `zfa tdd gen U5` (spec 044-test-tdd-generation).
//
// behavior_id: U5
// source_criterion: FR-005, FederatedBridge.channel
// kind: unit
// description: The channel contract MUST be exactly: channel
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/u5_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.


library;

import 'package:test/test.dart';
import 'dart:io';


import 'package:zuraffa_agent/tdd/115-agent-platform-packages/u5_subject.dart';



void main() {
  group('U5 (FR-005, FederatedBridge.channel)', () {
    test('U5 — The channel contract MUST be exactly: channel', ()  {
      // Assertion-shaped guard: the stub fails HERE via assertion.
      Object? guard;
      try {
        subject_u5('getAgentHome', {});
        guard = 'ok';
      } on UnimplementedError catch (e) {
        guard = e;
      }
      expect(guard, isNot(isA<UnimplementedError>()));
      expect(subject_u5('getAgentHome', {}), 'ok');
      expect(subject_u5('secureRead', {'key': 'k'}), 'ok');
      expect(subject_u5('secureWrite', {'key': 'k', 'value': 'v'}), 'ok');
      expect(subject_u5('secureDelete', {'key': 'k'}), 'ok');
      expect(subject_u5('nope', {}), 'bad-method');
      expect(subject_u5('secureRead', {}), 'bad-args');
      expect(subject_u5('secureWrite', {'key': 'k'}), 'bad-args');
      // The interface package pins the same names in its source.
      final src = File('packages/zuraffa_agent_platform_interface/lib/src/method_channel_platform.dart').readAsStringSync();
      for (final m in u5MethodNames) {
        expect(src, contains("'$m'"), reason: 'channel method $m unpinned');
      }
      expect(src, contains(u5ChannelName));
    });
  });
}
