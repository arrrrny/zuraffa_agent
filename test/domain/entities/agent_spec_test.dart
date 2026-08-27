// Tests for AgentSpec entity — Spec 005: Sub-agents & Declarative
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Declarative spec structure (tools, subagents, budgets, extends)

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/agent_spec/agent_spec.dart';

AgentSpec makeSpec({
  String? id,
  List<String>? tools,
  List<String>? subagents,
  String? budget,
  String? systemPrompt,
  String? riskTier,
  String? extendsSpec,
}) {
  return AgentSpec(
    id: id ?? 'spec-1',
    tools: tools ?? ['read_file', 'write_file'],
    subagents: subagents ?? ['explore'],
    budget: budget ?? 'standard',
    systemPrompt: systemPrompt ?? 'You are a helpful assistant.',
    riskTier: riskTier ?? 'safe',
    extendsSpec: extendsSpec ?? '',
  );
}

void main() {
  group('AgentSpec', () {
    test('construction and field access', () {
      final spec = makeSpec();
      expect(spec.id, 'spec-1');
      expect(spec.tools, ['read_file', 'write_file']);
      expect(spec.subagents, ['explore']);
      expect(spec.budget, 'standard');
      expect(spec.systemPrompt, 'You are a helpful assistant.');
      expect(spec.riskTier, 'safe');
      expect(spec.extendsSpec, '');
    });

    test('construction with extends', () {
      final spec = makeSpec(
        id: 'child-spec',
        extendsSpec: 'base-spec',
        tools: ['custom_tool'],
      );
      expect(spec.extendsSpec, 'base-spec');
      expect(spec.tools, ['custom_tool']);
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeSpec();
      final updated = original.copyWith(
        tools: ['new_tool'],
        budget: 'premium',
      );

      expect(updated.tools, ['new_tool']);
      expect(updated.budget, 'premium');
      expect(updated.id, original.id);
      expect(updated.systemPrompt, original.systemPrompt);
    });

    test('toJson produces expected keys', () {
      final spec = makeSpec();
      final json = spec.toJson();

      expect(json['id'], 'spec-1');
      expect(json['tools'], ['read_file', 'write_file']);
      expect(json['subagents'], ['explore']);
      expect(json['budget'], 'standard');
      expect(json['systemPrompt'], 'You are a helpful assistant.');
      expect(json['riskTier'], 'safe');
      expect(json['extends'], ''); // JsonKey name mapping
    });

    test('fromJson round-trip preserves all fields', () {
      final original = makeSpec(
        id: 'complex-spec',
        tools: ['tool_a', 'tool_b', 'tool_c'],
        subagents: ['explore', 'verify'],
        budget: 'unlimited',
        systemPrompt: 'Custom prompt with instructions.',
        riskTier: 'admin',
        extendsSpec: 'base-spec',
      );
      final json = original.toJson();
      final restored = AgentSpec.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.tools, original.tools);
      expect(restored.subagents, original.subagents);
      expect(restored.budget, original.budget);
      expect(restored.systemPrompt, original.systemPrompt);
      expect(restored.riskTier, original.riskTier);
      expect(restored.extendsSpec, original.extendsSpec);
    });

    test('fromJson with empty lists', () {
      final json = {
        'id': 'minimal-spec',
        'tools': <String>[],
        'subagents': <String>[],
        'budget': 'default',
        'systemPrompt': '',
        'riskTier': 'safe',
        'extends': '',
      };
      final spec = AgentSpec.fromJson(json);

      expect(spec.tools, isEmpty);
      expect(spec.subagents, isEmpty);
    });

    test('fromJson with extends field', () {
      final json = {
        'id': 'child',
        'tools': ['read'],
        'subagents': <String>[],
        'budget': 'standard',
        'systemPrompt': 'Be helpful.',
        'riskTier': 'safe',
        'extends': 'parent-spec',
      };
      final spec = AgentSpec.fromJson(json);

      expect(spec.extendsSpec, 'parent-spec');
    });
  });

  group('AgentSpec - Inheritance Pattern', () {
    test('child spec inherits from parent', () {
      makeSpec(
        id: 'parent',
        tools: ['read_file', 'write_file'],
        budget: 'standard',
      );
      final child = makeSpec(
        id: 'child',
        extendsSpec: 'parent',
        tools: ['read_file', 'custom_tool'], // Overrides tools
        budget: 'premium', // Overrides budget
      );

      expect(child.extendsSpec, 'parent');
      expect(child.tools, ['read_file', 'custom_tool']);
      expect(child.budget, 'premium');
    });

    test('empty extends means root spec', () {
      final root = makeSpec(extendsSpec: '');
      expect(root.extendsSpec, isEmpty);
    });
  });
}
