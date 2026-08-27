// HAND-CURATED regression tests for the ToolRegistry value object +
// ToolRegistryProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/tool_registry/tool_registry.dart';
import 'package:zuraffa_agent/src/domain/services/tool_registry_service.dart';
import 'package:zuraffa_agent/src/data/providers/tool_registry/tool_registry_provider.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart' as engine;
import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';

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

    test('ToolRegistry inequality detected per-field: id', () {
      final a = ToolRegistry(id: 'id-1', toolNames: const [], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      final b = ToolRegistry(id: 'id-2', toolNames: const [], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      expect(a == b, isFalse);
    });

    test('ToolRegistry inequality detected per-field: toolNames', () {
      final a = ToolRegistry(id: 'id', toolNames: const ['x'], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      final b = ToolRegistry(id: 'id', toolNames: const ['x','y'], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      expect(a == b, isFalse);
    });

    test('ToolRegistry inequality detected per-field: ddToolCount', () {
      final a = ToolRegistry(id: 'id', toolNames: const [], ddToolCount: 1, generatedToolCount: 0, mcpToolCount: 0);
      final b = ToolRegistry(id: 'id', toolNames: const [], ddToolCount: 2, generatedToolCount: 0, mcpToolCount: 0);
      expect(a == b, isFalse);
    });

    test('ToolRegistry empty toolNames list is valid', () {
      final r = ToolRegistry(id: 'empty', toolNames: const [], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      expect(r.toolNames, isEmpty);
    });

    test('ToolRegistry zero counts are valid', () {
      final r = ToolRegistry(id: 'zero', toolNames: const ['t'], ddToolCount: 0, generatedToolCount: 0, mcpToolCount: 0);
      expect(r.ddToolCount, 0);
      expect(r.generatedToolCount, 0);
      expect(r.mcpToolCount, 0);
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolRegistry toString', () {
    test('toString includes id and toolNames', () {
      final r = ToolRegistry(id: 'my-reg', toolNames: const ['fs.read','web.fetch'], ddToolCount: 1, generatedToolCount: 2, mcpToolCount: 3);
      final s = r.toString();
      expect(s, contains('my-reg'));
      expect(s, contains('fs.read'));
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

  group('arrarrny/zuraffa_agent#4 - Engine ToolRegistry interface', () {
    test('NamespaceCollisionEvent holds toolName, sources, resolution', () {
      const event = engine.NamespaceCollisionEvent(
        toolName: 'fs.read',
        sources: ['dda', 'mcp:server1'],
        resolution: 'dda-wins',
      );
      expect(event.toolName, 'fs.read');
      expect(event.sources, ['dda', 'mcp:server1']);
      expect(event.resolution, 'dda-wins');
    });

    test('NamespaceCollisionEvent const constructor', () {
      const event = engine.NamespaceCollisionEvent(
        toolName: 't',
        sources: ['s1'],
        resolution: 'r',
      );
      expect(event, isA<engine.NamespaceCollisionEvent>());
    });
  });
}
