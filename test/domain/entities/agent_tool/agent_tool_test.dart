// Spec 034 — AgentTool classification + registry persistence + hash contract
// tests (TDD cycles 1-3).
//
// Traces: tdd/test-list.md A1..A3, U3, U4 (cycle 1: hash contract fix),
// A4..A6, U1, U2 (cycle 2: tier/mode classification parsing), A7..A9, U5
// (cycle 3: registry persistence contract).
//
// The A1 hash test is a LIVE assertion-level red against the scaffolded
// entity today (probe-verified 2026-08-27): two equal tools with
// distinct-but-equal paramsSchema map instances compare equal through the
// deep _mapEq but hash differently because Object.hash(...) hashes the
// Map by identity (518580394 vs 128524753). The parser and serialization
// tests are compile-level reds (fromString/toJson/fromJson absent).

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/agent_tool/agent_tool.dart';

void main() {
  const schema = <String, dynamic>{
    'type': 'object',
    'properties': {
      'path': {'type': 'string'},
      'content': {'type': 'string'},
    },
    'required': ['path', 'content'],
  };

  group('spec 034 — AgentTool hash contract (cycle 1)', () {
    test('A1: equal tools with distinct-but-equal paramsSchema instances share hashCode', () {
      final a = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
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
      final b = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
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
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode), reason: 'the scaffold hashes the Map by identity — a live ==/hashCode contract violation');
    });

    test('A2: equal schemas built in different insertion orders hash equally', () {
      AgentTool withSchema(Map<String, dynamic> schema) => AgentTool(
            id: 't',
            description: 'd',
            paramsSchema: schema,
          );
      final a = withSchema({
        'type': 'object',
        'properties': {
          'path': {'type': 'string'},
        },
        'required': ['path'],
      });
      final b = withSchema({
        'required': ['path'],
        'properties': {
          'path': {'type': 'string'},
        },
        'type': 'object',
      });
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode), reason: 'map insertion order is noise — the fold is order-independent');
    });

    test('A3: tools differing on any of the five fields are unequal', () {
      final base = AgentTool(id: 't', description: 'd', paramsSchema: schema);
      expect(base == AgentTool(id: 'u', description: 'd', paramsSchema: schema), isFalse, reason: 'id');
      expect(base == AgentTool(id: 't', description: 'e', paramsSchema: schema), isFalse, reason: 'description');
      expect(
        base == AgentTool(id: 't', description: 'd', riskTier: RiskTier.confirm, paramsSchema: schema),
        isFalse,
        reason: 'riskTier',
      );
      expect(
        base == AgentTool(id: 't', description: 'd', executionMode: ExecutionMode.parallel, paramsSchema: schema),
        isFalse,
        reason: 'executionMode',
      );
      expect(base == AgentTool(id: 't', description: 'd'), isFalse, reason: 'paramsSchema presence');
    });

    test('U3: the hash fold recurses into nested maps (a one-level fold would re-violate)', () {
      final a = AgentTool(
        id: 't',
        description: 'd',
        paramsSchema: {
          'properties': {
            'path': {'type': 'string'},
          },
        },
      );
      final b = AgentTool(
        id: 't',
        description: 'd',
        paramsSchema: {
          'properties': {
            'path': {'type': 'string'},
          },
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode), reason: 'nested map instances are distinct — the fold must recurse');
    });

    test('U4: schema array order matters for equality and hashing (required lists are ordered)', () {
      final a = AgentTool(
        id: 't',
        description: 'd',
        paramsSchema: {
          'required': ['path', 'content'],
        },
      );
      final b = AgentTool(
        id: 't',
        description: 'd',
        paramsSchema: {
          'required': ['content', 'path'],
        },
      );
      expect(a == b, isFalse, reason: 'JSON-Schema arrays are ordered — a reordered required list is a different schema');
    });
  });

  group('spec 034 — RiskTier / ExecutionMode classification (cycle 2)', () {
    test('A4: RiskTier.fromString parses safe/confirm/admin exactly and round-trips via name', () {
      expect(RiskTier.fromString('safe'), RiskTier.safe);
      expect(RiskTier.fromString('confirm'), RiskTier.confirm);
      expect(RiskTier.fromString('admin'), RiskTier.admin);
      for (final tier in RiskTier.values) {
        expect(RiskTier.fromString(tier.name), tier);
      }
    });

    test('A5: RiskTier.fromString rejects unknown strings (incl. case mismatches) typed', () {
      expect(() => RiskTier.fromString('delete'), throwsArgumentError);
      expect(() => RiskTier.fromString(''), throwsArgumentError);
      expect(() => RiskTier.fromString('SAFE'), throwsArgumentError, reason: 'declaration strings are exact — case is significant');
      expect(() => RiskTier.fromString('low'), throwsArgumentError, reason: 'never silently under-classify an unknown tier');
    });

    test('A6: each tier dispatch policy reads correctly (confirm pauses, admin gates)', () {
      expect(RiskTier.safe.requiresConfirmation, isFalse);
      expect(RiskTier.safe.isAdmin, isFalse);
      expect(RiskTier.confirm.requiresConfirmation, isTrue);
      expect(RiskTier.confirm.isAdmin, isFalse);
      expect(RiskTier.admin.requiresConfirmation, isTrue);
      expect(RiskTier.admin.isAdmin, isTrue);
      expect(RiskTier.safe.severity < RiskTier.confirm.severity, isTrue);
      expect(RiskTier.confirm.severity < RiskTier.admin.severity, isTrue);
    });

    test('U1: ExecutionMode.fromString parses sequential/parallel; unknown rejects typed', () {
      expect(ExecutionMode.fromString('sequential'), ExecutionMode.sequential);
      expect(ExecutionMode.fromString('parallel'), ExecutionMode.parallel);
      expect(() => ExecutionMode.fromString('batch'), throwsArgumentError);
    });

    test('U2: fromString ArgumentError carries the offending input as its value', () {
      expect(
        () => RiskTier.fromString('delete'),
        throwsA(isA<ArgumentError>().having((e) => e.invalidValue, 'invalidValue', 'delete')),
      );
    });
  });

  group('spec 034 — AgentTool registry persistence (cycle 3)', () {
    test('A7: a fully-declared tool round-trips JSON with tier, mode and deep schema', () {
      final tool = AgentTool(
        id: 'web.fetch',
        description: 'Fetch a URL.',
        riskTier: RiskTier.confirm,
        executionMode: ExecutionMode.parallel,
        paramsSchema: schema,
      );
      final json = tool.toJson();
      expect(json['riskTier'], 'confirm');
      expect(json['executionMode'], 'parallel');
      final parsed = AgentTool.fromJson(json);
      expect(parsed, equals(tool));
      expect(parsed.hashCode, tool.hashCode);
      expect(parsed.requiresConfirmation, isTrue, reason: 'dispatch policy survives the round-trip');
    });

    test('A8: a schema-less tool serializes paramsSchema absent', () {
      final tool = AgentTool(id: 'clock.now', description: 'Current time.');
      final json = tool.toJson();
      expect(json.containsKey('paramsSchema'), isFalse);
      expect(json['riskTier'], 'safe');
      expect(json['executionMode'], 'sequential');
      final parsed = AgentTool.fromJson(json);
      expect(parsed.paramsSchema, isNull);
      expect(parsed, equals(tool));
    });

    test('A9: malformed declaration JSON throws ArgumentError naming the field', () {
      expect(
        () => AgentTool.fromJson(const {'description': 'd'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing id',
      );
      expect(
        () => AgentTool.fromJson(const {'id': 't'}),
        throwsA(isA<ArgumentError>()),
        reason: 'missing description',
      );
      expect(
        () => AgentTool.fromJson(const {'id': 't', 'description': 'd', 'riskTier': 'delete'}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'riskTier')),
        reason: 'unknown tier — never a silent safe',
      );
      expect(
        () => AgentTool.fromJson(const {'id': 't', 'description': 'd', 'executionMode': 'batch'}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'executionMode')),
        reason: 'unknown mode',
      );
      expect(
        () => AgentTool.fromJson(const {'id': 't', 'description': 'd', 'paramsSchema': 'nope'}),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'paramsSchema')),
        reason: 'non-map schema',
      );
    });

    test('U5: fromJson routes tier/mode through fromString — unknown tier in JSON fails like a declaration', () {
      expect(
        () => AgentTool.fromJson(const {'id': 't', 'description': 'd', 'riskTier': 'SAFE'}),
        throwsA(isA<ArgumentError>()),
        reason: 'case mismatch rejects exactly like RiskTier.fromString does',
      );
    });
  });
}
