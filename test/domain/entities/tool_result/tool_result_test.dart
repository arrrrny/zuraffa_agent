// Spec 031 — ToolResult value-object semantics tests (TDD cycles 1-3).
//
// Traces: tdd/test-list.md A7, A8, U1..U5 (cycle 1: isError + equality/
// hashCode contract), A1..A3, A6, U8 (cycle 2: serialization), A4, A5, U6, U7
// (cycle 3: oversized path).
//
// The hashCode contract test (A7) is red against the scaffolded entity today:
// the scaffold hashes only content + artifactRef while == also compares the
// payload — equal results with distinct-but-equal map instances hash
// differently under Dart's identity-based map hashing.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_result/tool_result.dart';

void main() {
  group('spec 031 — ToolResult isError + equality/hashCode (cycle 1)', () {
    test('A7: equal results with distinct-but-equal payload instances share hashCode', () {
      final a = ToolResult(content: 'c', structuredPayload: {'k': 'v', 'n': 1});
      final b = ToolResult(content: 'c', structuredPayload: {'k': 'v', 'n': 1});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('U4: payload hashing is order-independent across insertion orders', () {
      final a = ToolResult(content: 'c', structuredPayload: {'x': 1, 'y': 2, 'z': 3});
      final b = ToolResult(content: 'c', structuredPayload: {'z': 3, 'x': 1, 'y': 2});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('A8: results differing in content, payload, isError or artifactRef are unequal', () {
      final base = ToolResult(content: 'c', structuredPayload: {'k': 'v'});
      final otherContent = ToolResult(content: 'd', structuredPayload: {'k': 'v'});
      final otherPayload = ToolResult(content: 'c', structuredPayload: {'k': 'w'});
      final otherIsError = ToolResult.error(content: 'c');
      final ref = ArtifactRef(kind: 'file', id: 'a-1');
      final withRef = ToolResult(content: 'c', structuredPayload: {'k': 'v'}, artifactRef: ref);
      expect(base, isNot(equals(otherContent)));
      expect(base, isNot(equals(otherPayload)));
      expect(base, isNot(equals(otherIsError)));
      expect(base, isNot(equals(withRef)));
    });

    test('U1: success factory sets isError false; error factory sets isError true', () {
      final ok = ToolResult.success(content: 'done');
      final err = ToolResult.error(content: 'boom');
      expect(ok.isError, isFalse);
      expect(err.isError, isTrue);
    });

    test('U2: default construction stays isError=false (backward compat)', () {
      final result = ToolResult(content: 'legacy');
      expect(result.isError, isFalse);
    });

    test('U3: isError participates in equality', () {
      final ok = ToolResult.success(content: 'c');
      final err = ToolResult.error(content: 'c');
      expect(ok, isNot(equals(err)));
    });

    test('U5: null payload equals null only — never an empty map', () {
      const nullPayload = ToolResult(content: 'c');
      final emptyPayload = ToolResult(content: 'c', structuredPayload: {});
      expect(nullPayload, isNot(equals(emptyPayload)));
      expect(nullPayload.structuredPayload, isNull);
    });
  });

  group('spec 031 — ToolResult serialization (cycle 2)', () {
    test('A1: a success result with payload round-trips through JSON exactly', () {
      final original = ToolResult.success(
        content: 'processed',
        structuredPayload: {'rows': 3, 'truncated': false},
      );
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(parsed, equals(original));
      expect(parsed.isError, isFalse);
    });

    test('A2: an error result round-trips with isError true and content preserved', () {
      final original = ToolResult.error(
        content: 'MCP transport error: server crashed',
        structuredPayload: {'code': -32000},
      );
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(parsed, equals(original));
      expect(parsed.isError, isTrue);
      expect(parsed.content, equals('MCP transport error: server crashed'));
    });

    test('A3: an error result without payload serializes without a payload key', () {
      final original = ToolResult.error(content: 'denied by policy');
      final json = original.toJson();
      expect(json.containsKey('structuredPayload'), isFalse);
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(parsed, equals(original));
      expect(parsed.structuredPayload, isNull);
    });

    test('A6: an inline result serializes without artifactRef and isSummarized is false', () {
      final inline = ToolResult.success(content: 'inline body');
      expect(inline.isSummarized, isFalse);
      expect(inline.toJson().containsKey('artifactRef'), isFalse);
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(inline.toJson())) as Map<String, dynamic>);
      expect(parsed, equals(inline));
      expect(parsed.isSummarized, isFalse);
    });

    test('U8: fromJson round-trips a ref with null uri (nullable uri survives)', () {
      final original = ToolResult(content: 'sum', artifactRef: ArtifactRef(kind: 'file', id: 'a-9'));
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(parsed, equals(original));
      expect(parsed.artifactRef?.uri, isNull);
    });
  });

  group('spec 031 — ToolResult oversized path (cycle 3)', () {
    test('A4: the oversized path yields summary + artifactRef + isSummarized true', () {
      final ref = ArtifactRef(kind: 'scrape', id: 'big-1', uri: 'artifact://big-1');
      final result = ToolResult.oversized(summary: '2 MB scrape summarized', artifactRef: ref);
      expect(result.content, equals('2 MB scrape summarized'));
      expect(result.artifactRef, equals(ref));
      expect(result.isSummarized, isTrue);
    });

    test('A5: a summarized result artifactRef survives the round-trip', () {
      final ref = ArtifactRef(kind: 'scrape', id: 'big-2', uri: 'artifact://big-2');
      final original = ToolResult.oversized(summary: 'summary text', artifactRef: ref);
      final parsed = ToolResult.fromJson(jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(parsed, equals(original));
      expect(parsed.artifactRef?.kind, equals('scrape'));
      expect(parsed.artifactRef?.id, equals('big-2'));
      expect(parsed.artifactRef?.uri, equals('artifact://big-2'));
      expect(parsed.isSummarized, isTrue);
    });

    test('U6: oversized constructor requires summary + artifactRef (assert contract)', () {
      final ref = ArtifactRef(kind: 'file', id: 'a-1');
      expect(
        () => ToolResult.oversized(summary: 's', artifactRef: ref),
        returnsNormally,
      );
    });

    test('U7: oversized error results are constructible (edge-5)', () {
      final ref = ArtifactRef(kind: 'stderr', id: 'e-1');
      final result = ToolResult.oversized(
        summary: 'error body too large',
        artifactRef: ref,
        isError: true,
      );
      expect(result.isError, isTrue);
      expect(result.isSummarized, isTrue);
    });
  });
}
