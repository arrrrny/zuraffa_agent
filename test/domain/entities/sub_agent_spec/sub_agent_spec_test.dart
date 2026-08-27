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

  group('spec 036 — SubAgentSpec allowlist validation (FR-002)', () {
    test('U4: blank tool id inside tools throws ArgumentError', () {
      expect(
        () => SubAgentSpec(
          name: 'explore',
          description: 'Explore a topic broadly.',
          systemPrompt: 'You are an explorer.',
          tools: ['fs.read', ''],
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('tools')),
        ),
      );
    });

    test('U5: blank sub-agent name inside subAgents throws ArgumentError', () {
      expect(
        () => SubAgentSpec(
          name: 'orchestrator',
          description: 'Orchestrates sub-agents.',
          systemPrompt: 'You are an orchestrator.',
          subAgents: ['explore', ''],
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('subAgents')),
        ),
      );
    });

    test('U4/U5 boundary: empty allowlists and non-blank ids stay valid', () {
      final leaf = SubAgentSpec(
        name: 'explore',
        description: 'Explore a topic broadly.',
        systemPrompt: 'You are an explorer.',
      );
      expect(leaf.tools, isEmpty);
      expect(leaf.subAgents, isEmpty);

      final toolUser = SubAgentSpec(
        name: 'composer',
        description: 'Compose long-form content.',
        systemPrompt: 'You are a composer.',
        tools: ['fs.read', 'web.fetch'],
        subAgents: ['explore'],
      );
      expect(toolUser.tools, hasLength(2));
      expect(toolUser.subAgents, hasLength(1));
    });
  });

  group('spec 036 — SubAgentSpec budget validation (FR-003)', () {
    test('U6: maxTurns 0 throws, maxTurns 1 is valid (both sides)', () {
      expect(
        () => SubAgentSpec(
          name: 'x',
          description: 'x',
          systemPrompt: 'x',
          maxTurns: 0,
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', contains('maxTurns')),
        ),
      );
      final boundary = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
        maxTurns: 1,
      );
      expect(boundary.maxTurns, 1);
      expect(boundary.hasBudgets, isTrue);
    });

    test('U7: contextWindowTokens 0 throws, 1 is valid (both sides)', () {
      expect(
        () => SubAgentSpec(
          name: 'x',
          description: 'x',
          systemPrompt: 'x',
          contextWindowTokens: 0,
        ),
        throwsA(
          isA<ArgumentError>().having(
              (e) => e.name, 'name', contains('contextWindowTokens')),
        ),
      );
      final boundary = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
        contextWindowTokens: 1,
      );
      expect(boundary.contextWindowTokens, 1);
    });

    test('U8: negative wallClockTimeout throws; Duration.zero and null valid', () {
      expect(
        () => SubAgentSpec(
          name: 'x',
          description: 'x',
          systemPrompt: 'x',
          wallClockTimeout: const Duration(seconds: -1),
        ),
        throwsA(
          isA<ArgumentError>().having(
              (e) => e.name, 'name', contains('wallClockTimeout')),
        ),
      );
      // Duration.zero is the documented "no wall-clock limit" sentinel — valid.
      final zero = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
        wallClockTimeout: Duration.zero,
      );
      expect(zero.wallClockTimeout, Duration.zero);
      expect(zero.hasBudgets, isTrue);
      // Null (inherit from parent) is valid and leaves hasBudgets to other
      // fields.
      final unset = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
      );
      expect(unset.wallClockTimeout, isNull);
      expect(unset.hasBudgets, isFalse);
    });
  });

  group('spec 036 — SubAgentSpec inheritance 1-cycle check (FR-004)', () {
    test('U9: extendsSpec == name throws ArgumentError (self-extends)', () {
      expect(
        () => SubAgentSpec(
          name: 'verify',
          description: 'Verifier.',
          systemPrompt: 'You verify.',
          extendsSpec: 'verify',
        ),
        throwsA(
          isA<ArgumentError>().having(
              (e) => e.name, 'name', contains('extendsSpec')),
        ),
      );
    });

    test('U9 boundary: extendsSpec naming a distinct parent constructs', () {
      final child = SubAgentSpec(
        name: 'verify-strict',
        description: 'Strict verifier.',
        systemPrompt: 'You verify strictly.',
        extendsSpec: 'verify',
      );
      expect(child.extendsSpec, 'verify');
      expect(child.isRoot, isFalse);
      expect(child.isLeaf, isTrue);
    });
  });

  group('spec 036 — characterization pins (FR-005/FR-006, shipped behavior)', () {
    test('U10 pin: isLeaf/isRoot across the four canonical shapes', () {
      // root+leaf, root+branch, child+leaf are covered by the pre-existing
      // provider suite; this pin completes child+branch and holds the matrix.
      final rootLeaf = SubAgentSpec(
          name: 'a', description: 'd', systemPrompt: 's');
      final rootBranch = SubAgentSpec(
          name: 'b', description: 'd', systemPrompt: 's', subAgents: ['a']);
      final childLeaf = SubAgentSpec(
          name: 'c', description: 'd', systemPrompt: 's', extendsSpec: 'a');
      final childBranch = SubAgentSpec(
          name: 'd2',
          description: 'd',
          systemPrompt: 's',
          extendsSpec: 'b',
          subAgents: ['a', 'c']);
      expect(rootLeaf.isRoot, isTrue);
      expect(rootLeaf.isLeaf, isTrue);
      expect(rootBranch.isRoot, isTrue);
      expect(rootBranch.isLeaf, isFalse);
      expect(childLeaf.isRoot, isFalse);
      expect(childLeaf.isLeaf, isTrue);
      expect(childBranch.isRoot, isFalse);
      expect(childBranch.isLeaf, isFalse);
    });

    test('U12 pin: equality/hashCode with non-const, independently built lists', () {
      // FR-006: two specs equal in all ten fields, lists built separately at
      // runtime (distinct instances, equal contents) must be == and hash
      // equally. The pre-existing provider test used const literals, which
      // canonicalize to identical instances — this pin exercises the
      // element-wise comparison for real.
      final a = SubAgentSpec(
        name: 'verify',
        description: 'Verifier.',
        systemPrompt: 'Verify strictly.',
        extendsSpec: 'base',
        tools: ['fs.read', 'fs.write'],
        subAgents: ['explore'],
        riskTier: RiskTier.admin,
        maxTurns: 5,
        wallClockTimeout: const Duration(seconds: 30),
        contextWindowTokens: 8000,
      );
      final b = SubAgentSpec(
        name: 'verify',
        description: 'Verifier.',
        systemPrompt: 'Verify strictly.',
        extendsSpec: 'base',
        tools: ['fs.read', 'fs.write'],
        subAgents: ['explore'],
        riskTier: RiskTier.admin,
        maxTurns: 5,
        wallClockTimeout: const Duration(seconds: 30),
        contextWindowTokens: 8000,
      );
      expect(identical(a.tools, b.tools), isFalse,
          reason: 'the pin must use distinct list instances');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
