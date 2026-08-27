// Tests for SubAgentType entity — Spec 005: Sub-agents & Declarative
//
// Covers:
// - Entity construction and field access
// - JSON serialization round-trip
// - copyWith behavior
// - Sub-agent type configuration (allowlists, budgets)

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_type/sub_agent_type.dart';

SubAgentType makeType({
  String? id,
  String? name,
  String? specRef,
  List<String>? allowlist,
  String? budgetProfile,
}) {
  return SubAgentType(
    id: id ?? 'type-1',
    name: name ?? 'explore',
    specRef: specRef ?? 'spec-explore',
    allowlist: allowlist ?? ['read_file', 'search'],
    budgetProfile: budgetProfile ?? 'standard',
  );
}

void main() {
  group('SubAgentType', () {
    test('construction and field access', () {
      final type = makeType();
      expect(type.id, 'type-1');
      expect(type.name, 'explore');
      expect(type.specRef, 'spec-explore');
      expect(type.allowlist, ['read_file', 'search']);
      expect(type.budgetProfile, 'standard');
    });

    test('construction with different type', () {
      final type = makeType(
        name: 'compose',
        allowlist: ['write_file', 'format'],
        budgetProfile: 'premium',
      );
      expect(type.name, 'compose');
      expect(type.allowlist, ['write_file', 'format']);
      expect(type.budgetProfile, 'premium');
    });

    test('copyWith creates new instance with overrides', () {
      final original = makeType();
      final updated = original.copyWith(
        name: 'verify',
        allowlist: ['run_test', 'lint'],
      );

      expect(updated.name, 'verify');
      expect(updated.allowlist, ['run_test', 'lint']);
      expect(updated.id, original.id);
      expect(updated.specRef, original.specRef);
    });

    test('toJson produces expected keys', () {
      final type = makeType();
      final json = type.toJson();

      expect(json['id'], 'type-1');
      expect(json['name'], 'explore');
      expect(json['specRef'], 'spec-explore');
      expect(json['allowlist'], ['read_file', 'search']);
      expect(json['budgetProfile'], 'standard');
    });

    test('fromJson round-trip preserves all fields', () {
      final original = makeType(
        id: 'compose-type',
        name: 'compose',
        specRef: 'spec-compose',
        allowlist: ['write_file', 'format', 'lint'],
        budgetProfile: 'unlimited',
      );
      final json = original.toJson();
      final restored = SubAgentType.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.specRef, original.specRef);
      expect(restored.allowlist, original.allowlist);
      expect(restored.budgetProfile, original.budgetProfile);
    });

    test('fromJson with empty allowlist', () {
      final json = {
        'id': 'restricted',
        'name': 'restricted',
        'specRef': 'spec-restricted',
        'allowlist': <String>[],
        'budgetProfile': 'minimal',
      };
      final type = SubAgentType.fromJson(json);

      expect(type.allowlist, isEmpty);
      expect(type.budgetProfile, 'minimal');
    });
  });

  group('SubAgentType - Tool Allowlists', () {
    test('explore type has read-only tools', () {
      final explore = makeType(
        name: 'explore',
        allowlist: ['read_file', 'search', 'list_dir'],
      );

      expect(explore.allowlist, contains('read_file'));
      expect(explore.allowlist, contains('search'));
      expect(explore.allowlist, isNot(contains('write_file')));
    });

    test('compose type has write tools', () {
      final compose = makeType(
        name: 'compose',
        allowlist: ['write_file', 'edit_file', 'format'],
      );

      expect(compose.allowlist, contains('write_file'));
      expect(compose.allowlist, contains('edit_file'));
    });

    test('verify type has test/lint tools', () {
      final verify = makeType(
        name: 'verify',
        allowlist: ['run_test', 'lint', 'analyze'],
      );

      expect(verify.allowlist, contains('run_test'));
      expect(verify.allowlist, contains('lint'));
    });
  });

  group('SubAgentType - Budget Profiles', () {
    test('standard budget profile', () {
      final type = makeType(budgetProfile: 'standard');
      expect(type.budgetProfile, 'standard');
    });

    test('premium budget profile', () {
      final type = makeType(budgetProfile: 'premium');
      expect(type.budgetProfile, 'premium');
    });

    test('minimal budget profile', () {
      final type = makeType(budgetProfile: 'minimal');
      expect(type.budgetProfile, 'minimal');
    });
  });
}
