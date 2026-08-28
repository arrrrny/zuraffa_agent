// HAND-CURATED regression tests for the ToolRegistry value object +
// ToolRegistryProvider. Pattern mirrors spec 033.

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

    test('ToolRegistryProvider.current returns the active registry snapshot', () async {
      final registry = await ToolRegistryProvider().current(NoParams());
      expect(registry, isA<ToolRegistry>());
      expect(registry.id, 'default');
      expect(registry.toolNames, isNotEmpty);
      expect(
        registry.toolNames.length,
        registry.ddToolCount + registry.generatedToolCount + registry.mcpToolCount,
      );
    });

    test('ToolRegistryProvider.current honours an injected registry', () async {
      final injected = ToolRegistry(id: 'custom', toolNames: const ['x'], ddToolCount: 1, generatedToolCount: 0, mcpToolCount: 0);
      expect(await ToolRegistryProvider(injected).current(NoParams()), equals(injected));
    });

    test('ToolRegistryProvider.count returns 1', () async {
      expect(await ToolRegistryProvider().count(NoParams()), 1);
    });
  });
}
