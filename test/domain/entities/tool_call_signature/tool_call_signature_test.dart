// Spec 29 — ToolCallSignature entity tests (TDD cycle 1).
//
// Traces: tdd/test-list.md A3, A4, U1..U6 (FR-001..003, SC-003, edge-3).
// The entity is the content-addressable invocation identity: toolName +
// argumentHash + version, with the canonical key derived from content.

import 'package:test/test.dart';

import 'package:zuraffa_agent/src/domain/entities/tool_call_signature/tool_call_signature.dart';

void main() {
  group('ToolCallSignature value object (A3, A4, U1..U6)', () {
    test('A3 + U1: equal content builds equal signatures with equal hashCodes and identical keys', () {
      const a = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 1);
      const b = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.key, equals(b.key));
      expect(a.id, equals(b.id));
    });

    test('A4 + U2: differing toolName, argumentHash or version makes signatures unequal with different keys', () {
      const base = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 1);
      const otherName = ToolCallSignature(toolName: 'fs.read', argumentHash: 'abc123', version: 1);
      const otherHash = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'xyz789', version: 1);
      const otherVersion = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 2);
      expect(base, isNot(equals(otherName)));
      expect(base, isNot(equals(otherHash)));
      expect(base, isNot(equals(otherVersion)));
      expect(base.key, isNot(equals(otherName.key)));
      expect(base.key, isNot(equals(otherHash.key)));
      expect(base.key, isNot(equals(otherVersion.key)));
    });

    test('U3: key is the canonical toolName@version:argumentHash string', () {
      const sig = ToolCallSignature(toolName: 'webview.browse', argumentHash: 'abc123', version: 2);
      expect(sig.key, equals('webview.browse@2:abc123'));
    });

    test('U4: version defaults to 1', () {
      const sig = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h');
      expect(sig.version, equals(1));
      expect(sig.key, equals('fs.read@1:h'));
    });

    test('U5: legacy ToolCallSignature(id: ...) construction keeps compiling', () {
      const legacy = ToolCallSignature(id: 'legacy-key');
      expect(legacy.id, equals('legacy-key'));
      expect(legacy.toolName, equals(''));
      expect(legacy.argumentHash, equals(''));
      expect(legacy.version, equals(1));
    });

    test('U6: equality ignores a legacy explicit id — the content triple decides', () {
      const withCustomId = ToolCallSignature(
        id: 'custom-id',
        toolName: 'fs.read',
        argumentHash: 'h',
        version: 1,
      );
      const derived = ToolCallSignature(toolName: 'fs.read', argumentHash: 'h', version: 1);
      expect(withCustomId, equals(derived));
    });
  });
}
