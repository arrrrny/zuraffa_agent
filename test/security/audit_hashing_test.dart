// Issue arrrrny/zuraffa_agent#132 — hashing for the audit trail.
//
// The audit log stores SHA-256 digests of tool-call arguments and results,
// never the payloads themselves. `crypto` is deliberately NOT a dependency
// (constitution IX: no new deps without a spec change), so SHA-256 is
// implemented in-tree per FIPS 180-4 and pinned here against the standard
// NIST test vectors.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/security/audit_hashing.dart';

void main() {
  group('sha256Hex (FIPS 180-4)', () {
    test('empty string', () {
      expect(
        sha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('"abc" (NIST vector 1)', () {
      expect(
        sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('two-block boundary message (NIST vector 2, 56 bytes)', () {
      expect(
        sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('multi-block message (NIST vector 3)', () {
      expect(
        sha256Hex('The quick brown fox jumps over the lazy dog'),
        'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592',
      );
    });

    test('one million "a" characters (NIST vector 4)', () {
      expect(
        sha256Hex('a' * 1000000),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
      );
    });

    test('digest is lowercase hex, 64 characters', () {
      final digest = sha256Hex('zuraffa');
      expect(digest, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });

  group('canonicalJson', () {
    test('map keys are sorted recursively', () {
      final a = canonicalJson({
        'b': {'d': 1, 'c': 2},
        'a': 3,
      });
      final b = canonicalJson({
        'a': 3,
        'b': {'c': 2, 'd': 1},
      });
      expect(a, b);
      expect(a, '{"a":3,"b":{"c":2,"d":1}}');
    });

    test('arrays keep their order (order is semantic)', () {
      final a = canonicalJson({
        'list': [3, 1, 2],
      });
      final b = canonicalJson({
        'list': [1, 2, 3],
      });
      expect(a, isNot(b));
      expect(a, '{"list":[3,1,2]}');
    });

    test('scalars and null round-trip through jsonDecode unchanged', () {
      // Keys already in sorted order so canonicalJson and jsonEncode agree
      // byte-for-byte; the nested list keeps its order.
      final value = {
        'a': 'text',
        'b': 42,
        'c': 1.5,
        'd': true,
        'e': null,
        'f': [1, 'two', false],
      };
      expect(canonicalJson(value), jsonEncode(value));
      expect(jsonDecode(canonicalJson(value)), equals(value));
    });

    test('string escapes match jsonEncode', () {
      expect(
        canonicalJson({'k': 'quote " backslash \\ newline \n'}),
        jsonEncode({'k': 'quote " backslash \\ newline \n'}),
      );
    });
  });

  group('auditHash', () {
    test('returns a 64-char lowercase hex digest', () {
      expect(
        auditHash({'tool': 'shell', 'cmd': 'ls'}),
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    });

    test('key order never changes the digest', () {
      final a = auditHash({
        'a': 1,
        'b': 2,
        'c': {'x': 1, 'y': 2},
      });
      final b = auditHash({
        'c': {'y': 2, 'x': 1},
        'b': 2,
        'a': 1,
      });
      expect(a, b);
    });

    test('different payloads hash differently', () {
      expect(auditHash({'cmd': 'ls'}), isNot(auditHash({'cmd': 'rm -rf /'})));
    });

    test('the digest never echoes the payload (not raw payload)', () {
      final payload = 'SECRET-API-KEY-MATERIAL';
      final digest = auditHash(payload);
      expect(digest.contains(payload), isFalse);
    });

    test('null and scalars are hashable', () {
      expect(auditHash(null), matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(auditHash(42), matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}
