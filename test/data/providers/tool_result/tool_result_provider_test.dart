// Regression test for arrarrny/zuraffa_agent#31.
//
// Asserts:
// - The ToolResult value object compiles WITHOUT an `id` field (zfa v6.0.0
//   hard-requires `id` for `zfa make <Entity>` and aborts; the hand-curated
//   surface ships the spec-exact shape: content + structuredPayload + artifactRef).
// - The clean-arch layers (ToolResultService + ToolResultProvider) are
//   wired correctly and compile.
// - The provider's UnimplementedError stubs fire.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;

import 'package:zuraffa_agent/src/domain/entities/artifact_ref/artifact_ref.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_result/tool_result.dart';
import 'package:zuraffa_agent/src/domain/services/tool_result_service.dart';
import 'package:zuraffa_agent/src/data/providers/tool_result/tool_result_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#31 — ToolResult value object (no id)', () {
    test('ToolResult is constructible with content + structuredPayload + artifactRef', () {
      final ref = ArtifactRef(kind: 'file', id: 'a-1', uri: 'file:///tmp/a-1');
      final result = ToolResult(
        content: 'summarized body',
        structuredPayload: {'k': 'v'},
        artifactRef: ref,
      );
      expect(result.content, 'summarized body');
      expect(result.structuredPayload, {'k': 'v'});
      expect(result.artifactRef, ref);
    });

    test('ToolResult.isSummarized is true when artifactRef is non-null', () {
      final ref = ArtifactRef(kind: 'file', id: 'a-2');
      final summarized = ToolResult(content: 'summary', artifactRef: ref);
      final inline = ToolResult(content: 'inline body');
      expect(summarized.isSummarized, isTrue);
      expect(inline.isSummarized, isFalse);
    });

    test('ToolResult equality is value-based (content + payload + artifactRef)', () {
      final ref = ArtifactRef(kind: 'file', id: 'a-3');
      final a = ToolResult(
        content: 'c',
        structuredPayload: {'k': 'v'},
        artifactRef: ref,
      );
      final b = ToolResult(
        content: 'c',
        structuredPayload: {'k': 'v'},
        artifactRef: ref,
      );
      final c = ToolResult(content: 'c', structuredPayload: {'k': 'w'}, artifactRef: ref);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('ToolResult has no `id` field — compile-time guard', () {
      // If a future refactor adds an `id` field, this test should be
      // updated to assert its non-presence; for now, the constructor
      // signature proves there is no required `id`.
      final result = ToolResult(content: 'hello');
      expect(result.content, 'hello');
    });
  });

  group('arrarrny/zuraffa_agent#31 — ToolResult clean-arch layers', () {
    test('ToolResultProvider is a ToolResultService', () {
      expect(ToolResultProvider(), isA<ToolResultService>());
    });

    test('ToolResultProvider.current throws UnimplementedError on NoParams', () {
      expect(
        () => ToolResultProvider().current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ToolResultProvider.count throws UnimplementedError on NoParams', () {
      expect(
        () => ToolResultProvider().count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
