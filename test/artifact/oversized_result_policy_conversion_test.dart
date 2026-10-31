// R3#3 acceptance (spec-003 §4.3, FR-005): a large tool result is
// auto-converted to a summarized ToolResult carrying an ArtifactRef; the full
// body is retrievable by artifact id and never reaches model context. by
// artifact id and never reaches model context.
// to a summarized ToolResult carrying an ArtifactRef; the full body is
// retrievable by artifact id and never reaches model context.
// by artifact id and never reaches model context.
//
// Traces: specs/003-tools-and-mcp tdd/test-list.md A9 (oversized result -> model
// summary + artifactRef only) and SC-003 (2 MB -> artifactRef, never in
// context).
//
// This is the threshold-enforcement discipline that was previously untested:
// the OversizedResultPolicy value object, the ArtifactService.store sink, and
// the ToolResult.oversized factory all existed, but nothing tied them together
// for a raw tool result. enforceOversizedResultPolicy is that seam. raw tool
// result. enforceOversizedResultPolicy is that seam.
// OversizedResultPolicy value object, the ArtifactService.store sink, and the
// ToolResult.oversized factory all existed, but nothing tied them together for
// a raw tool result. enforceOversizedResultPolicy is that seam.
// raw tool result. enforceOversizedResultPolicy is that seam.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/artifact/artifact_service.dart';
import 'package:zuraffa_agent/src/artifact/in_memory_artifact_store.dart';
import 'package:zuraffa_agent/src/artifact/oversized_result_policy_applier.dart';
import 'package:zuraffa_agent/src/domain/entities/oversized_result_policy/oversized_result_policy.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_result/tool_result.dart';

void main() {
  group('R3#3 - oversized tool result threshold enforcement', () {
    test(
      // SC-003 verbatim: a literal 2 MB tool result is reduced to a bounded
      // summary + artifactRef — the full body never appears in the content
      // that would enter model context, and round-trips through the store.
      'a 2 MB tool result is reduced to a bounded summary + artifactRef, '
      'never the body',
      () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 1024 * 1024),
        );
        const policy = OversizedResultPolicy(
          id: 'test',
          thresholdBytes: 1024 * 1024,
          summaryMaxChars: 64,
          artifactStore: './artifacts',
        );
        final body = 'x' * (2 * 1024 * 1024); // exactly 2 MB

        final converted = await enforceOversizedResultPolicy(
          result: ToolResult.success(content: body),
          policy: policy,
          artifactService: store,
        );

        expect(converted.isSummarized, isTrue);
        expect(converted.artifactRef, isNotNull);
        // The model-facing content is a bounded summary (header + short
        // preview), never the 2 MB body.
        expect(converted.content.length, lessThan(1024));
        // The body stays retrievable, byte-for-byte.
        final artifact = await store.fetch(converted.artifactRef!);
        expect(utf8.decode(artifact!.data), equals(body));
      },
    );

    test('a tool result exceeding the policy threshold is auto-converted to an '
        'ArtifactRef', () async {
      final store = InMemoryArtifactStore(
        config: const ArtifactServiceConfig(thresholdBytes: 100),
      );
      const policy = OversizedResultPolicy(
        id: 'test',
        thresholdBytes: 100,
        summaryMaxChars: 64,
        artifactStore: './artifacts',
      );
      final large = ToolResult.success(content: 'x' * 200);

      final converted = await enforceOversizedResultPolicy(
        result: large,
        policy: policy,
        artifactService: store,
      );

      expect(converted.isSummarized, isTrue);
      expect(converted.artifactRef, isNotNull);
      expect(converted.artifactRef!.kind, 'artifact');
    });

    test(
      'the full body of a converted result is retrievable by artifact id',
      () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 100),
        );
        const policy = OversizedResultPolicy(
          id: 'test',
          thresholdBytes: 100,
          summaryMaxChars: 64,
          artifactStore: './artifacts',
        );
        final body = 'x' * 200;
        final converted = await enforceOversizedResultPolicy(
          result: ToolResult.success(content: body),
          policy: policy,
          artifactService: store,
        );

        final artifact = await store.fetch(converted.artifactRef!);
        expect(artifact, isNotNull);
        expect(utf8.decode(artifact!.data), equals(body));
      },
    );

    test(
      'a tool result within the threshold is left unchanged (no artifactRef)',
      () async {
        final store = InMemoryArtifactStore(
          config: const ArtifactServiceConfig(thresholdBytes: 100),
        );
        const policy = OversizedResultPolicy(
          id: 'test',
          thresholdBytes: 100,
          summaryMaxChars: 64,
          artifactStore: './artifacts',
        );
        const small = ToolResult.success(content: 'small');

        final converted = await enforceOversizedResultPolicy(
          result: small,
          policy: policy,
          artifactService: store,
        );

        expect(converted.isSummarized, isFalse);
        expect(converted.artifactRef, isNull);
        expect(converted.content, equals('small'));
      },
    );
  });
}
