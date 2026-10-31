// HAND-CURATED regression tests for the ToolRegistry value object +
// ToolRegistryProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/tool_registry/tool_registry_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_registry/tool_registry.dart';
import 'package:zuraffa_agent/src/domain/services/tool_registry_service.dart';
import 'package:zuraffa_agent/src/engine/tool_registry.dart' as engine;

void main() {
  group('arrarrny/zuraffa_agent#4 - ToolRegistry value equality', () {
    test('ToolRegistry equality is value-based across all fields', () {
      const a = ToolRegistry(
        id: 'id-a',
        toolNames: ['a', 'b'],
        ddToolCount: 10,
        generatedToolCount: 10,
        mcpToolCount: 10,
      );
      const b = ToolRegistry(
        id: 'id-a',
        toolNames: ['a', 'b'],
        ddToolCount: 10,
        generatedToolCount: 10,
        mcpToolCount: 10,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ToolRegistry inequality differs when a field changes', () {
      const a = ToolRegistry(
        id: 'id-a',
        toolNames: ['a', 'b'],
        ddToolCount: 10,
        generatedToolCount: 10,
        mcpToolCount: 10,
      );
      const b = ToolRegistry(
        id: 'id-b',
        toolNames: ['a', 'b', 'c'],
        ddToolCount: 20,
        generatedToolCount: 20,
        mcpToolCount: 20,
      );
      expect(a == b, isFalse);
    });

    test('ToolRegistry inequality detected per-field: id', () {
      const a = ToolRegistry(
        id: 'id-1',
        toolNames: [],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      const b = ToolRegistry(
        id: 'id-2',
        toolNames: [],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(a == b, isFalse);
    });

    test('ToolRegistry inequality detected per-field: toolNames', () {
      const a = ToolRegistry(
        id: 'id',
        toolNames: ['x'],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      const b = ToolRegistry(
        id: 'id',
        toolNames: ['x', 'y'],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(a == b, isFalse);
    });

    test('ToolRegistry inequality detected per-field: ddToolCount', () {
      const a = ToolRegistry(
        id: 'id',
        toolNames: [],
        ddToolCount: 1,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      const b = ToolRegistry(
        id: 'id',
        toolNames: [],
        ddToolCount: 2,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(a == b, isFalse);
    });

    test('ToolRegistry empty toolNames list is valid', () {
      const r = ToolRegistry(
        id: 'empty',
        toolNames: [],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(r.toolNames, isEmpty);
    });

    test('ToolRegistry zero counts are valid', () {
      const r = ToolRegistry(
        id: 'zero',
        toolNames: ['t'],
        ddToolCount: 0,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(r.ddToolCount, 0);
      expect(r.generatedToolCount, 0);
      expect(r.mcpToolCount, 0);
    });
  });

  group('arrarrny/zuraffa_agent#4 - ToolRegistry toString', () {
    test('toString includes id and toolNames', () {
      const r = ToolRegistry(
        id: 'my-reg',
        toolNames: ['fs.read', 'web.fetch'],
        ddToolCount: 1,
        generatedToolCount: 2,
        mcpToolCount: 3,
      );
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

    test(
      'ToolRegistryProvider.current returns the active registry snapshot',
      () async {
        final registry = await ToolRegistryProvider().current(const NoParams());
        expect(registry, isA<ToolRegistry>());
        expect(registry.id, 'default');
        expect(registry.toolNames, isNotEmpty);
        expect(
          registry.toolNames.length,
          registry.ddToolCount +
              registry.generatedToolCount +
              registry.mcpToolCount,
        );
      },
    );

    test('ToolRegistryProvider.current honours an injected registry', () async {
      const injected = ToolRegistry(
        id: 'custom',
        toolNames: ['x'],
        ddToolCount: 1,
        generatedToolCount: 0,
        mcpToolCount: 0,
      );
      expect(
        await ToolRegistryProvider(injected).current(const NoParams()),
        equals(injected),
      );
    });

    test('ToolRegistryProvider.count returns 1', () async {
      expect(await ToolRegistryProvider().count(const NoParams()), 1);
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
