// Regression test for arrarrny/zuraffa_agent#4 (R3 — tools & MCP client).
//
// Asserts:
// - RiskTier enum has safe/confirm/admin with correct severity ordering
//   and requiresConfirmation / isAdmin getters.
// - ExecutionMode enum has sequential/parallel.
// - AgentTool is constructible with id + description + (optional riskTier,
//   executionMode, paramsSchema) and defaults to safe / sequential.
// - AgentTool.requiresConfirmation / isAdmin delegate correctly to the
//   risk tier.
// - Value equality holds across all five fields of AgentTool, including
//   deep equality on paramsSchema.
// - The clean-arch layers (AgentToolService + AgentToolProvider) are
//   wired correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';
import 'package:zuraffa_agent/src/domain/services/agent_tool_service.dart';
import 'package:zuraffa_agent/src/data/providers/agent_tool/agent_tool_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#4 — RiskTier enum', () {
    test('RiskTier has safe / confirm / admin with severity 0/1/2', () {
      expect(RiskTier.safe.severity, 0);
      expect(RiskTier.confirm.severity, 1);
      expect(RiskTier.admin.severity, 2);
      expect(RiskTier.values.length, 3);
    });

    test('RiskTier.requiresConfirmation is false for safe, true for confirm+admin', () {
      expect(RiskTier.safe.requiresConfirmation, isFalse);
      expect(RiskTier.confirm.requiresConfirmation, isTrue);
      expect(RiskTier.admin.requiresConfirmation, isTrue);
    });

    test('RiskTier.isAdmin is true only for admin', () {
      expect(RiskTier.safe.isAdmin, isFalse);
      expect(RiskTier.confirm.isAdmin, isFalse);
      expect(RiskTier.admin.isAdmin, isTrue);
    });
  });

  group('arrarrny/zuraffa_agent#4 — AgentTool declaration entity', () {
    test('AgentTool defaults to safe / sequential when riskTier/executionMode omitted', () {
      final tool = AgentTool(
        id: 'fs.read',
        description: 'Read a file from local disk.',
      );
      expect(tool.id, 'fs.read');
      expect(tool.description, 'Read a file from local disk.');
      expect(tool.riskTier, RiskTier.safe);
      expect(tool.executionMode, ExecutionMode.sequential);
      expect(tool.paramsSchema, isNull);
      expect(tool.requiresConfirmation, isFalse);
      expect(tool.isAdmin, isFalse);
    });

    test('AgentTool carries riskTier + executionMode + paramsSchema when provided', () {
      final tool = AgentTool(
        id: 'fs.write',
        description: 'Write a file to local disk.',
        riskTier: RiskTier.confirm,
        executionMode: ExecutionMode.parallel,
        paramsSchema: {
          'type': 'object',
          'properties': {
            'path': {'type': 'string'},
            'content': {'type': 'string'},
          },
          'required': ['path', 'content'],
        },
      );
      expect(tool.riskTier, RiskTier.confirm);
      expect(tool.executionMode, ExecutionMode.parallel);
      expect(tool.requiresConfirmation, isTrue);
      expect(tool.isAdmin, isFalse);
      expect(tool.paramsSchema, isNotNull);
      expect(tool.paramsSchema!['type'], 'object');
    });

    test('AgentTool.requiresConfirmation is true for admin', () {
      final tool = AgentTool(
        id: 'sys.shutdown',
        description: 'Shut the system down.',
        riskTier: RiskTier.admin,
      );
      expect(tool.requiresConfirmation, isTrue);
      expect(tool.isAdmin, isTrue);
    });

    test('AgentTool equality is value-based across all five fields', () {
      final schema = {
        'type': 'object',
        'properties': {'path': {'type': 'string'}},
      };
      final a = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
        riskTier: RiskTier.confirm,
        executionMode: ExecutionMode.parallel,
        paramsSchema: schema,
      );
      final b = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
        riskTier: RiskTier.confirm,
        executionMode: ExecutionMode.parallel,
        paramsSchema: schema,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('AgentTool inequality differs on paramsSchema deep contents', () {
      final a = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
        paramsSchema: {
          'type': 'object',
          'properties': {'path': {'type': 'string'}},
        },
      );
      final b = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
        paramsSchema: {
          'type': 'object',
          'properties': {'path': {'type': 'number'}}, // differs
        },
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#4 — AgentTool clean-arch layers', () {
    test('AgentToolProvider is an AgentToolService', () {
      final provider = AgentToolProvider();
      expect(provider, isA<AgentToolService>());
    });

    test('AgentToolProvider.current throws UnimplementedError on NoParams', () {
      final provider = AgentToolProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('AgentToolProvider.count throws UnimplementedError on NoParams', () {
      final provider = AgentToolProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
