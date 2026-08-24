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
    test('YamlAgentSpecProvider is a YamlAgentSpecService', () {
      final provider = YamlAgentSpecProvider();
      expect(provider, isA<YamlAgentSpecService>());
    });

    test('YamlAgentSpecProvider.current throws UnimplementedError on NoParams', () {
      final provider = YamlAgentSpecProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('YamlAgentSpecProvider.count throws UnimplementedError on NoParams', () {
      final provider = YamlAgentSpecProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
