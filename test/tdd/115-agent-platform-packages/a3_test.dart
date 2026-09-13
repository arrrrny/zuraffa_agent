// GENERATED TEST — `zfa tdd gen A3` (spec 044-test-tdd-generation).
//
// behavior_id: A3
// source_criterion: AC-3
// kind: acceptance
// description: the same value returns; after delete, the read returns null.
//
// This test asserts the observable behavior described above. It is
// "honest red" on first execution: the paired subject at
// `package:zuraffa_agent/tdd/115-agent-platform-packages/a3_subject.dart` is unimplemented, so the test fails through an
// assertion (not an uncaught error, compile/load error, skip, or
// placeholder). Replace the subject's
// stub body with real implementation to make this test pass.

// zfa:tdd: contract:A3:hand — hand step completed before first red certification (issue #1411)

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/platform/agent_platform.dart';
import 'package:zuraffa_agent/tdd/115-agent-platform-packages/a3_subject.dart';


class _SeqFake implements AgentPlatform {
  final store = <String, String>{};
  @override
  Future<String?> getAgentHome() async => '/support';
  @override
  Future<String?> secureRead(String key) async => store[key];
  @override
  Future<void> secureWrite(String key, String value) async => store[key] = value;
  @override
  Future<void> secureDelete(String key) async => store.remove(key);
}

void main() {
  group('A3 (AC-3)', () {
    test('A3 — the same value returns; after delete, the read returns null.', () async {
      AgentPlatformBinding.reset();
      addTearDown(AgentPlatformBinding.reset);
      // Bind an in-test fake implementing the pure interface.
      AgentPlatformBinding.instance = _SeqFake();
      final result = await subject_a3();
      expect(result[0], isNull, reason: 'absent before write');
      expect(result[1], 'sk-live', reason: 'written value round-trips');
      expect(result[2], isNull, reason: 'deleted after delete');
    });
  });
}
