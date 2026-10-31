// LLM wire snapshot codec — issue #128 AC-3.
//
// Canonical, deterministic serialization of the PARSED provider responses
// (LlmResponse / LlmResponseChunk), used by the byte-level snapshot tests in
// llm_wire_snapshot_test.dart:
//
//   - fixed key order (declaration order, not JSON-map order)
//   - 2-space indentation so snapshots are human-diffable in review
//   - byte comparison against the `*.expected.json` siblings under
//     test/fixtures/llm/<provider>/
//
// Drift reports are byte-level: first differing offset, byte values, and the
// offending line — NOT a bare "expected X got Y" (that was the gap the issue
// called out).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:zuraffa_agent/src/llm/llm_client.dart';

const _encoder = JsonEncoder.withIndent('  ');

/// Canonical snapshot JSON for a parsed non-streaming response.
String canonicalResponse(LlmResponse response) {
  final json = <String, dynamic>{
    'content': response.content,
    'thinking': response.thinking,
    'toolCalls': [
      for (final call in response.toolCalls)
        <String, dynamic>{
          'id': call.id,
          'name': call.name,
          'arguments': call.arguments,
        },
    ],
    'usage': <String, dynamic>{
      'inputTokens': response.usage.inputTokens,
      'outputTokens': response.usage.outputTokens,
      'cachedTokens': response.usage.cachedTokens,
      'thoughtTokens': response.usage.thoughtTokens,
    },
    'finishReason': response.finishReason,
  };
  return _encoder.convert(json);
}

/// Canonical snapshot JSON for an assembled chunk stream.
String canonicalChunks(List<LlmResponseChunk> chunks) {
  final json = [
    for (final chunk in chunks)
      <String, dynamic>{
        'content': chunk.content,
        'thinking': chunk.thinking,
        'toolCalls': [
          for (final call in chunk.toolCalls)
            <String, dynamic>{
              'id': call.id,
              'name': call.name,
              'arguments': call.arguments,
            },
        ],
        'usage': chunk.usage == null
            ? null
            : <String, dynamic>{
                'inputTokens': chunk.usage!.inputTokens,
                'outputTokens': chunk.usage!.outputTokens,
                'cachedTokens': chunk.usage!.cachedTokens,
                'thoughtTokens': chunk.usage!.thoughtTokens,
              },
        'isComplete': chunk.isComplete,
        'finishReason': chunk.finishReason,
      },
  ];
  return _encoder.convert(json);
}

/// Byte-level comparison of [actual] against the [expected] snapshot bytes.
///
/// Returns null when identical (modulo a single trailing newline that the
/// committed file carries for POSIX friendliness). On drift returns a report
/// naming the first differing byte offset, both byte values, and the first
/// differing line — the failure message a maintainer diffs against.
String? byteDiff(String expected, String actual) {
  final expectedBytes = _stripTrailingNewline(utf8.encode(expected));
  final actualBytes = _stripTrailingNewline(utf8.encode(actual));
  if (_bytesEqual(expectedBytes, actualBytes)) return null;

  final shared = _sharedPrefixLength(expectedBytes, actualBytes);
  final buffer = StringBuffer(
    'snapshot drift at byte offset $shared '
    '(expected ${expectedBytes.length} bytes, actual ${actualBytes.length})\n',
  );
  if (shared < expectedBytes.length && shared < actualBytes.length) {
    buffer.write(
      'expected byte 0x${expectedBytes[shared].toRadixString(16)} '
      "('${asciiSafe(expectedBytes[shared])}'), "
      'actual byte 0x${actualBytes[shared].toRadixString(16)} '
      "('${asciiSafe(actualBytes[shared])}')\n",
    );
  }
  final expectedLines = utf8.decode(expectedBytes).split('\n');
  final actualLines = utf8.decode(actualBytes).split('\n');
  for (var i = 0; i < expectedLines.length || i < actualLines.length; i++) {
    final e = i < expectedLines.length ? expectedLines[i] : '<absent>';
    final a = i < actualLines.length ? actualLines[i] : '<absent>';
    if (e != a) {
      buffer.write('first differing line ${i + 1}:\n');
      buffer.write('  expected: $e\n');
      buffer.write('  actual:   $a\n');
      break;
    }
  }
  return buffer.toString();
}

int _stripTrailingNewlineByte(Uint8List bytes) =>
    bytes.isNotEmpty && bytes.last == 0x0A ? bytes.length - 1 : bytes.length;

Uint8List _stripTrailingNewline(List<int> bytes) {
  final list = Uint8List.fromList(bytes);
  return Uint8List.sublistView(list, 0, _stripTrailingNewlineByte(list));
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _sharedPrefixLength(Uint8List a, Uint8List b) {
  final n = a.length < b.length ? a.length : b.length;
  var i = 0;
  while (i < n && a[i] == b[i]) {
    i++;
  }
  return i;
}

String asciiSafe(int byte) =>
    byte >= 0x20 && byte < 0x7F ? String.fromCharCode(byte) : '?';
