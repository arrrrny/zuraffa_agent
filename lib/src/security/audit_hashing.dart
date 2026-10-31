// Issue arrrrny/zuraffa_agent#132 — hashing helpers for the audit trail.
//
// SHA-256 is implemented in-tree per FIPS 180-4 because `crypto` is
// deliberately not a dependency (constitution IX: no new deps without a
// spec change). Correctness is pinned against the standard NIST test
// vectors in test/security/audit_hashing_test.dart.
//
// [auditHash] digests the CANONICAL JSON of a value, so two structurally
// equal arguments (any key order) produce the same digest — the property
// that makes args/result hashes comparable across runs. Pure Dart: no I/O,
// no clock (constitution VII).

import 'dart:convert';

const int _mask = 0xFFFFFFFF;

/// The 64 round constants of SHA-256 (FIPS 180-4 §4.2.2).
const List<int> _k = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, //
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _mask;

/// SHA-256 of the UTF-8 encoding of [input], as 64 lowercase hex chars.
String sha256Hex(String input) {
  final bytes = utf8.encode(input);

  // Padding (FIPS 180-4 §5.1.1): append 0x80, zero-fill to ≡ 56 (mod 64),
  // then the 64-bit big-endian bit length.
  final bitLength = bytes.length * 8;
  final padded = List<int>.of(bytes)
    ..add(0x80)
    ..addAll(List<int>.filled((56 - (bytes.length + 1) % 64) % 64, 0));
  for (var shift = 56; shift >= 0; shift -= 8) {
    padded.add((bitLength >> shift) & 0xFF);
  }

  // Initial hash values (FIPS 180-4 §5.3.3).
  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;

  final w = List<int>.filled(64, 0);
  for (var block = 0; block < padded.length; block += 64) {
    for (var t = 0; t < 16; t++) {
      final i = block + t * 4;
      w[t] =
          (padded[i] << 24) |
          (padded[i + 1] << 16) |
          (padded[i + 2] << 8) |
          padded[i + 3];
    }
    for (var t = 16; t < 64; t++) {
      final s0 = _rotr(w[t - 15], 7) ^ _rotr(w[t - 15], 18) ^ (w[t - 15] >> 3);
      final s1 = _rotr(w[t - 2], 17) ^ _rotr(w[t - 2], 19) ^ (w[t - 2] >> 10);
      w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & _mask;
    }

    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (var t = 0; t < 64; t++) {
      final bigS1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & _mask) & g);
      final temp1 = (h + bigS1 + ch + _k[t] + w[t]) & _mask;
      final bigS0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (bigS0 + maj) & _mask;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & _mask;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & _mask;
    }

    h0 = (h0 + a) & _mask;
    h1 = (h1 + b) & _mask;
    h2 = (h2 + c) & _mask;
    h3 = (h3 + d) & _mask;
    h4 = (h4 + e) & _mask;
    h5 = (h5 + f) & _mask;
    h6 = (h6 + g) & _mask;
    h7 = (h7 + h) & _mask;
  }

  final digest = [h0, h1, h2, h3, h4, h5, h6, h7];
  return [
    for (final word in digest) word.toRadixString(16).padLeft(8, '0'),
  ].join();
}

/// JSON encoding with recursively sorted object keys — the canonical form
/// [auditHash] digests. Arrays keep their order (order is semantic); every
/// other value renders exactly as [jsonEncode] renders it.
String canonicalJson(Object? value) {
  if (value is Map) {
    final keys = [for (final key in value.keys) key.toString()]..sort();
    final entries = [
      for (final key in keys) '${jsonEncode(key)}:${canonicalJson(value[key])}',
    ];
    return '{${entries.join(',')}}';
  }
  if (value is List) {
    return '[${[for (final item in value) canonicalJson(item)].join(',')}]';
  }
  return jsonEncode(value);
}

/// The audit digest of [value]: SHA-256 of [canonicalJson]. Equal
/// structures hash equal regardless of key order; the digest never
/// contains the payload itself.
///
/// Deliberately UNSALTED (issue #132 review, design note): a per-install
/// salt or HMAC key would close the offline dictionary oracle — anyone
/// holding the audit file can confirm guesses about low-entropy arguments
/// by hashing candidates and comparing — but a salt changes every stored
/// digest, which is a v:1 → v:2 storage-format change. Per constitution
/// IX that needs a spec change, so it is flagged for the pool as the
/// follow-up, not merged ad hoc here.
String auditHash(Object? value) => sha256Hex(canonicalJson(value));
