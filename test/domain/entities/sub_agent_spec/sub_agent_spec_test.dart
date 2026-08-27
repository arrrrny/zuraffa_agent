// Spec 036 (issue arrrrny/zuraffa_agent#6, R5) — SubAgentSpec validation
// semantics, test-first via /speckit.tdd.run.
//
// Behaviors (specs/036-sub-agent-spec/tdd/test-list.md):
// - U1/U2/U3 (FR-001): empty identity fields throw ArgumentError.
// - U4/U5 (FR-002): blank allowlist ids throw ArgumentError.
// - U6/U7/U8 (FR-003): non-positive budgets throw; boundaries stay valid.
// - U9 (FR-004): the extendsSpec == name 1-cycle throws.
// - U10/U11/U12/U13 (FR-005/006): characterization pins for getters,
//   budgets, and non-const-list equality.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart'
    show RiskTier;
import 'package:zuraffa_agent/src/domain/entities/sub_agent_spec/sub_agent_spec.dart';

void main() {
  group('spec 036 — SubAgentSpec identity validation (FR-001)', () {
    test('U1: empty name throws ArgumentError naming the field', () {
      expect(
        () => SubAgentSpec(
          name: '',
          description: 'Explore a topic broadly.',
          systemPrompt: 'You are an explorer.',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('name')),
        ),
      );
    });

    test('U2: empty description throws ArgumentError naming the field', () {
      expect(
        () => SubAgentSpec(
          name: 'explore',
          description: '',
          systemPrompt: 'You are an explorer.',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('description')),
        ),
      );
    });

    test('U3: empty systemPrompt throws ArgumentError naming the field', () {
      expect(
        () => SubAgentSpec(
          name: 'explore',
          description: 'Explore a topic broadly.',
          systemPrompt: '',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('systemPrompt')),
        ),
      );
    });

    test('U1 boundary: non-empty identity fields construct a valid spec', () {
      final spec = SubAgentSpec(
        name: 'explore',
        description: 'Explore a topic broadly.',
        systemPrompt: 'You are an explorer.',
      );
      expect(spec.name, 'explore');
      expect(spec.isRoot, isTrue);
      expect(spec.isLeaf, isTrue);
      expect(spec.riskTier, RiskTier.safe);
    });
  });
}
