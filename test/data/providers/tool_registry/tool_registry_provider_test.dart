// HAND-CURATED regression tests for the ToolRegistry value object +
// ToolRegistryProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/tool_registry/tool_registry.dart';
import 'package:zuraffa_agent/src/domain/services/tool_registry_service.dart';
import 'package:zuraffa_agent/src/data/providers/tool_registry/tool_registry_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#4 - ToolRegistry value equality', () {
    test('ToolRegistry equality is value-based across all fields', () {
      final a = ToolRegistry(id: 'id-a', toolNames: const ['a','b'], ddToolCount: 10, generatedToolCount: 10, mcpToolCount: 10);
      final b = ToolRegistry(id: 'id-a', toolNames: const ['a','b'], ddToolCount: 10, generatedToolCount: 10, mcpToolCount: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ToolRegistry inequality differs when a field changes', () {
      final a = ToolRegistry(id: 'id-a', toolNames: const ['a','b'], ddToolCount: 10, generatedToolCount: 10, mcpToolCount: 10);
      final b = ToolRegistry(id: 'id-b', toolNames: const ['a','b','c'], ddToolCount: 20, generatedToolCount: 20, mcpToolCount: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolRegistry clean-arch layers', () {
    test('ToolRegistryProvider is a ToolRegistryService', () {
      final provider = ToolRegistryProvider();
      expect(provider, isA<ToolRegistryService>());
    });

    test('ToolRegistryProvider.current throws UnimplementedError on NoParams', () {
      final provider = ToolRegistryProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ToolRegistryProvider.count throws UnimplementedError on NoParams', () {
      final provider = ToolRegistryProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
