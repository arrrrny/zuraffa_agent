// Spec 29 — ToolCallSignature datasource pair tests (TDD cycles 2-3).
//
// Traces: tdd/test-list.md A1, A2, U7..U9 (FR-004..006, AC US1-1..2,
// SC-001, SC-002, edge-4).
// Supersedes the pre-refinement UnimplementedError stub assertions — the
// refined spec ships the capture/lookup persistence contract. The
// scaffolded current() is dropped (documented in spec.md Assumptions);
// lookup(key) is the richer replacement.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/data/datasources/tool_call_signature/tool_call_signature_datasource.dart';
import 'package:zuraffa_agent/src/data/datasources/tool_call_signature/tool_call_signature_mock_datasource.dart';
import 'package:zuraffa_agent/src/domain/entities/tool_call_signature/tool_call_signature.dart';

void main() {
  group('spec 029 — ToolCallSignature datasource pair', () {
    test('U7: ToolCallSignatureMockDatasource is a ToolCallSignatureDatasource', () {
      expect(ToolCallSignatureMockDatasource(), isA<ToolCallSignatureDatasource>());
    });

    group('A1..A2 + U8..U9 capture/lookup (cycle 2)', () {
      test('A1: capture(sig) then lookup(sig.key) returns the equal signature', () async {
        final ds = ToolCallSignatureMockDatasource();
        const sig = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 1);
        await ds.capture(sig);
        final found = await ds.lookup(sig.key);
        expect(found, isNotNull);
        expect(found, equals(sig));
      });

      test('A2 + U8: lookup of a never-captured key reports absence (null, no throw)', () async {
        final ds = ToolCallSignatureMockDatasource();
        final found = await ds.lookup('never@1:captured');
        expect(found, isNull);
      });

      test('U9: empty toolName / argument hash are valid content with well-formed keys', () async {
        final ds = ToolCallSignatureMockDatasource();
        const emptyContent = ToolCallSignature(toolName: '', argumentHash: '');
        expect(emptyContent.key, equals('@1:'));
        await ds.capture(emptyContent);
        expect(await ds.lookup('@1:'), equals(emptyContent));
      });

      test('A1: two distinct contents coexist in the store', () async {
        final ds = ToolCallSignatureMockDatasource();
        const a = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h1');
        const b = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h2');
        await ds.capture(a);
        await ds.capture(b);
        expect(await ds.lookup(a.key), equals(a));
        expect(await ds.lookup(b.key), equals(b));
      });
    });

    group('A5..A7 idempotency + bounded store (cycle 3)', () {
      test('A5: capturing the same content twice holds one entry', () async {
        final ds = ToolCallSignatureMockDatasource();
        const a = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h');
        const b = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h');
        await ds.capture(a);
        await ds.capture(b);
        expect(await ds.count(), equals(1));
      });

      test('A6: count reflects distinct captured signatures', () async {
        final ds = ToolCallSignatureMockDatasource();
        await ds.capture(const ToolCallSignature(toolName: 'a', argumentHash: 'h'));
        await ds.capture(const ToolCallSignature(toolName: 'b', argumentHash: 'h'));
        await ds.capture(const ToolCallSignature(toolName: 'c', argumentHash: 'h'));
        expect(await ds.count(), equals(3));
      });

      test('A7: reset() zeroes count and clears every lookup', () async {
        final ds = ToolCallSignatureMockDatasource();
        const sig = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h');
        await ds.capture(sig);
        expect(await ds.count(), equals(1));

        await ds.reset();

        expect(await ds.count(), equals(0));
        expect(await ds.lookup(sig.key), isNull);
      });
    });
  });
}
