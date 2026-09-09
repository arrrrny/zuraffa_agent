// HAND-CURATED regression tests for the YamlAgentSpec value object +
// YamlAgentSpecProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/yaml_agent_spec/yaml_agent_spec.dart';
import 'package:zuraffa_agent/src/domain/services/yaml_agent_spec_service.dart';
import 'package:zuraffa_agent/src/data/providers/yaml_agent_spec/yaml_agent_spec_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 - YamlAgentSpec value equality', () {
    test('YamlAgentSpec equality is value-based across all fields', () {
      final a = YamlAgentSpec(id: 'id-a', name: 'research-agent', extendsSpecId: null, toolAllowlist: const ['a','b'], systemPrompt: 'You are a helpful assistant.');
      final b = YamlAgentSpec(id: 'id-a', name: 'research-agent', extendsSpecId: null, toolAllowlist: const ['a','b'], systemPrompt: 'You are a helpful assistant.');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('YamlAgentSpec inequality differs when a field changes', () {
      final a = YamlAgentSpec(id: 'id-a', name: 'research-agent', extendsSpecId: null, toolAllowlist: const ['a','b'], systemPrompt: 'You are a helpful assistant.');
      final b = YamlAgentSpec(id: 'id-b', name: 'code-agent', extendsSpecId: null, toolAllowlist: const ['a','b','c'], systemPrompt: 'You are a helpful assistant.');
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 - YamlAgentSpec clean-arch layers', () {
    // spec 106 (issue #117): the provider no longer invents a default
    // agent spec — the former no-arg pins (id 'default', base allowlist)
    // were retired with that invented-default behavior.

    test('U3: constructing without a spec throws ArgumentError naming it',
        () {
      expect(
        () => YamlAgentSpecProvider(),
        throwsA(
          predicate((Object e) =>
              e is ArgumentError &&
              e.message.toString().contains('YamlAgentSpec')),
        ),
      );
    });

    test('U4 + A1: a configured provider serves the injected spec verbatim',
        () async {
      final custom = YamlAgentSpec(
        id: 'custom',
        name: 'research',
        extendsSpecId: 'base',
        toolAllowlist: const ['search'],
        systemPrompt: 'Research the topic.',
      );
      final provider = YamlAgentSpecProvider(custom);
      expect(provider, isA<YamlAgentSpecService>());
      final spec = await provider.current(NoParams());
      expect(spec, same(custom));
      expect(spec.id, 'custom');
      expect(spec.extendsSpecId, 'base');
      expect(spec.toolAllowlist, ['search']);
      expect(await provider.count(NoParams()), 1);
    });
  });

  group('spec 005 A6 - declarative spec validation diagnostics', () {
    test('a spec referencing an unknown tool fails validation with a precise error', () {
      final spec = YamlAgentSpec(
        id: 'id-x',
        name: 'broken',
        extendsSpecId: null,
        toolAllowlist: const ['search', 'unknown_tool'],
        systemPrompt: 'x',
      );
      final errors = spec.validate(
        parentOf: const {},
        knownTools: {'search', 'read_file'},
      );
      expect(errors, hasLength(1));
      expect(errors.single, contains("unknown tool 'unknown_tool'"));
      expect(errors.single, contains("spec 'id-x'"));
    });

    test('a spec with cyclic inheritance fails validation with a precise error', () {
      // a -> b -> a
      final specA = YamlAgentSpec(
        id: 'a', name: 'A', extendsSpecId: 'b',
        toolAllowlist: const [], systemPrompt: 'x',
      );
      final errors = specA.validate(
        parentOf: const {'a': 'b', 'b': 'a'},
        knownTools: const {},
      );
      expect(errors, anyElement(contains("cyclic inheritance")));
      expect(errors, anyElement(contains("spec 'a'")));
      expect(errors, anyElement(contains('b -> a -> b')));
    });
  });
}
