// Spec 041 (issue arrrrny/zuraffa_agent#3, R1/R2.1) — AgentMessage entity
// semantics: role/id validation + parts value equality, test-first via
// /speckit.tdd.run.
//
// Behaviors (specs/041-agent_message/tdd/test-list.md):
// - U1 (FR-001): empty id/role throw; empty parts stay valid.
// - U2 (FR-002): parts equality is element-wise across distinct instances.
// - U3 (FR-002): single-field differences break equality.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_message/agent_message.dart';

void main() {
  group('spec 041 — AgentMessage validation (FR-001)', () {
    test('U1: empty id throws ArgumentError naming id', () {
      expect(
        () => AgentMessage(id: '', role: 'assistant', parts: const ['text']),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('id')),
        ),
      );
    });

    test('U1: empty role throws ArgumentError naming role', () {
      expect(
        () => AgentMessage(id: 'id-a', role: '', parts: const ['text']),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('role')),
        ),
      );
    });

    test('U1 boundary: empty parts list stays valid', () {
      final m = AgentMessage(id: 'id-a', role: 'user', parts: const []);
      expect(m.parts, isEmpty);
      expect(m.id, 'id-a');
      expect(m.role, 'user');
    });
  });

  group('spec 041 — AgentMessage parts value equality (FR-002)', () {
    test('U2: distinct-instance equal-parts messages are == and hash equally', () {
      // The shipped entity compared parts with List == (identity), so these
      // two compared UNEQUAL — the bug this cycle fixes.
      final a = AgentMessage(id: 'id-a', role: 'assistant', parts: ['hello']);
      final b = AgentMessage(id: 'id-a', role: 'assistant', parts: ['hello']);
      expect(identical(a.parts, b.parts), isFalse,
          reason: 'the test must use distinct list instances');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('U2: multi-part equality with mixed content parts', () {
      final a = AgentMessage(id: 'm1', role: 'user', parts: [
        'intro',
        {'kind': 'image', 'ref': 'img-1'},
        'outro',
      ]);
      final b = AgentMessage(id: 'm1', role: 'user', parts: [
        'intro',
        {'kind': 'image', 'ref': 'img-1'},
        'outro',
      ]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('U3: single-field differences break equality', () {
      final base = AgentMessage(id: 'id-a', role: 'assistant', parts: ['hi']);
      final idDiffers =
          AgentMessage(id: 'id-b', role: 'assistant', parts: ['hi']);
      final roleDiffers =
          AgentMessage(id: 'id-a', role: 'user', parts: ['hi']);
      final partsDiffer =
          AgentMessage(id: 'id-a', role: 'assistant', parts: ['bye']);
      expect(base == idDiffers, isFalse);
      expect(base == roleDiffers, isFalse);
      expect(base == partsDiffer, isFalse);
    });
  });
}
