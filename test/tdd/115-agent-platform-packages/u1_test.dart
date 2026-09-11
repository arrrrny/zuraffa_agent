// GENERATED TEST — `zfa tdd gen U1` (spec 044-test-tdd-generation).
//
// behavior_id: U1
// source_criterion: FR-001, AgentPlatform.getAgentHome
// kind: unit
// description: `AgentPlatform` MUST define the host seam —
//
// Hand-stepped assertions (spec 115): named refusal unbound + fake
// binding round-trip. Test name preserved byte-identical.

library;

import 'package:test/test.dart';

import 'package:zuraffa_agent/zuraffa_agent.dart';
import 'package:zuraffa_agent/tdd/115-agent-platform-packages/u1_subject.dart';

class _LocalFake implements AgentPlatform {
  @override
  Future<String?> getAgentHome() async => '/support';
  @override
  Future<String?> secureRead(String key) async => null;
  @override
  Future<void> secureWrite(String key, String value) async {}
  @override
  Future<void> secureDelete(String key) async {}
}

void main() {
  group('U1 (FR-001, AgentPlatform.getAgentHome)', () {
    test('U1 — `AgentPlatform` MUST define the host seam —', () async {
      // Unbound default: a NAMED refusal, not silence (FR-001).
      Object? unboundOutcome;
      try {
        await subject_u1();
        unboundOutcome = 'ok';
      } on UnimplementedError catch (e) {
        unboundOutcome = e;
        expect(e.message, contains('AgentPlatform is not bound'));
      }
      expect(unboundOutcome, isA<UnimplementedError>(),
          reason: 'the unbound seam must fail loudly, not silently');
      // A bound implementation serves the home.
      AgentPlatformBinding.instance = _LocalFake();
      addTearDown(AgentPlatformBinding.reset);
      expect(await subject_u1(), '/support');
    });
  });
}
