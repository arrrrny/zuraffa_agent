// Regression test for arrarrny/zuraffa_agent#6 (R5 — sub-agents & specs:
// declarative agent specs).
//
// Asserts:
// - SubAgentSpec is constructible with name + description + systemPrompt
//   and defaults: extendsSpec=null, tools=[], subAgents=[], riskTier=safe,
//   maxTurns=null, wallClockTimeout=null, contextWindowTokens=null.
// - isLeaf is true when subAgents is empty; isRoot is true when extends
//   is null; hasBudgets reflects the three budget fields.
// - The spec carries tools + subAgents allowlists + extends + riskTier +
//   budgets when provided.
// - Value equality holds across all ten fields.
// - The clean-arch layers (SubAgentSpecService + SubAgentSpecProvider)
//   are wired correctly, compile, and report real behavior.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart'
    show RiskTier;
import 'package:zuraffa_agent/src/domain/entities/sub_agent_spec/sub_agent_spec.dart';
import 'package:zuraffa_agent/src/domain/services/sub_agent_spec_service.dart';
import 'package:zuraffa_agent/src/data/providers/sub_agent_spec/sub_agent_spec_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 — SubAgentSpec declarative value object', () {
    test('SubAgentSpec defaults to root/leaf/safe with no budgets', () {
      final spec = SubAgentSpec(
        name: 'explore',
        description: 'Explore a topic broadly.',
        systemPrompt: 'You are an explorer.',
      );
      expect(spec.name, 'explore');
      expect(spec.description, 'Explore a topic broadly.');
      expect(spec.systemPrompt, 'You are an explorer.');
      expect(spec.extendsSpec, isNull);
      expect(spec.tools, isEmpty);
      expect(spec.subAgents, isEmpty);
      expect(spec.riskTier, RiskTier.safe);
      expect(spec.maxTurns, isNull);
      expect(spec.wallClockTimeout, isNull);
      expect(spec.contextWindowTokens, isNull);
      expect(spec.isLeaf, isTrue);
      expect(spec.isRoot, isTrue);
      expect(spec.hasBudgets, isFalse);
    });

    test('SubAgentSpec carries tools + subAgents + extends + riskTier + budgets', () {
      final spec = SubAgentSpec(
        name: 'composer',
        description: 'Compose long-form content.',
        systemPrompt: 'You are a composer.',
        extendsSpec: 'explore',
        tools: const ['fs.read', 'web.fetch'],
        subAgents: const ['explore', 'verify'],
        riskTier: RiskTier.confirm,
        maxTurns: 20,
        wallClockTimeout: const Duration(minutes: 5),
        contextWindowTokens: 32000,
      );
      expect(spec.extendsSpec, 'explore');
      expect(spec.tools.length, 2);
      expect(spec.tools, contains('fs.read'));
      expect(spec.subAgents.length, 2);
      expect(spec.subAgents, contains('verify'));
      expect(spec.riskTier, RiskTier.confirm);
      expect(spec.maxTurns, 20);
      expect(spec.wallClockTimeout, const Duration(minutes: 5));
      expect(spec.contextWindowTokens, 32000);
      expect(spec.isLeaf, isFalse);
      expect(spec.isRoot, isFalse);
      expect(spec.hasBudgets, isTrue);
    });

    test('SubAgentSpec.isLeaf is false when subAgents is non-empty', () {
      final spec = SubAgentSpec(
        name: 'orchestrator',
        description: 'Orchestrates sub-agents.',
        systemPrompt: 'You are an orchestrator.',
        subAgents: const ['explore', 'compose', 'verify'],
      );
      expect(spec.isLeaf, isFalse);
      expect(spec.isRoot, isTrue);
    });

    test('SubAgentSpec.isRoot is false when extends is non-null', () {
      final spec = SubAgentSpec(
        name: 'verify-strict',
        description: 'Strict verifier.',
        systemPrompt: 'You verify strictly.',
        extendsSpec: 'verify',
      );
      expect(spec.isRoot, isFalse);
      expect(spec.isLeaf, isTrue);
    });

    test('SubAgentSpec.hasBudgets is true when only maxTurns is set', () {
      final spec = SubAgentSpec(
        name: 'budgeted',
        description: 'Has only maxTurns budget.',
        systemPrompt: 'x',
        maxTurns: 10,
      );
      expect(spec.hasBudgets, isTrue);
    });

    test('SubAgentSpec equality is value-based across all ten fields', () {
      final a = SubAgentSpec(
        name: 'verify',
        description: 'Verifier.',
        systemPrompt: 'Verify strictly.',
        extendsSpec: 'base',
        tools: const ['fs.read'],
        subAgents: const [],
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
        tools: const ['fs.read'],
        subAgents: const [],
        riskTier: RiskTier.admin,
        maxTurns: 5,
        wallClockTimeout: const Duration(seconds: 30),
        contextWindowTokens: 8000,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SubAgentSpec inequality differs on tools list contents', () {
      final a = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
        tools: const ['fs.read'],
      );
      final b = SubAgentSpec(
        name: 'x',
        description: 'x',
        systemPrompt: 'x',
        tools: const ['fs.write'],
      );
      expect(a == b, isFalse);
    });

    test('SubAgentSpec inequality differs on extends', () {
      final a = SubAgentSpec(
        name: 'verify-strict',
        description: 'x',
        systemPrompt: 'x',
      );
      final b = SubAgentSpec(
        name: 'verify-strict',
        description: 'x',
        systemPrompt: 'x',
        extendsSpec: 'verify',
      );
      expect(a == b, isFalse);
      expect(a.isRoot, isTrue);
      expect(b.isRoot, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 — SubAgentSpec clean-arch layers', () {
    test('SubAgentSpecProvider is a SubAgentSpecService', () {
      final provider = SubAgentSpecProvider();
      expect(provider, isA<SubAgentSpecService>());
    });

    test('SubAgentSpecProvider.current returns the active spec', () async {
      final spec = await SubAgentSpecProvider().current(NoParams());
      expect(spec, isA<SubAgentSpec>());
      expect(spec.name, 'explore');
      expect(spec.description, 'Default exploratory sub-agent.');
      expect(spec.riskTier, RiskTier.safe);
      expect(spec.isLeaf, isTrue);
    });

    test('SubAgentSpecProvider.current returns a supplied active spec', () async {
      final active = SubAgentSpec(
        name: 'composer',
        description: 'Compose.',
        systemPrompt: 'You compose.',
      );
      expect(await SubAgentSpecProvider(active).current(NoParams()), active);
    });

    test('SubAgentSpecProvider.count returns 1', () async {
      expect(await SubAgentSpecProvider().count(NoParams()), 1);
    });
  });
}
