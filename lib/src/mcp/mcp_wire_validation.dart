// HAND-CURATED — DO NOT REGENERATE VIA zfa.
// See issue arrrrny/zuraffa_agent#131 (MCP wire boundary validation).
//
// McpWireValidator — the validation gate on the MCP wire boundary. Both
// real [McpWire] adapters (IoSseMcpTransport, IoStdioMcpTransport) run
// every server response through [validateResponse] before it becomes a
// `McpWireResponse`, so a malicious or buggy MCP server can no longer
// propagate arbitrary shapes toward the clients / engine as
// `McpCallOk(content: <anything>)` (issue #131).
//
// Rejections are `McpWireResponseError`s, not throws: a protocol
// violation means the peer is misbehaving, not that the transport
// dropped — throwing would send the clients' reconnect policy chasing
// a connection that is fine. Rejected responses surface at the engine
// boundary as `McpCallError` and are never retried (none of the codes
// below is in `transientCallCodes`).
//
// Rejection codes:
//   - `protocol-violation` — the JSON-RPC 2.0 envelope is malformed:
//     `jsonrpc` != "2.0", `id` missing or not matching the request,
//     `result`/`error` XOR broken, `error` or `result` not an object.
//   - `response-too-large` — the raw body exceeds the byte cap
//     ([defaultMcpWireMaxResponseBytes], 1 MiB by default).
//   - `invalid-content`   — a string in the result payload carries a
//     control character (C0 minus tab/newline/CR, DEL, C1) or an
//     unmatched UTF-16 surrogate pair.

import 'dart:convert';

import 'mcp_wire.dart';

/// Default cap for a single wire response: 1 MiB (issue #131).
const int defaultMcpWireMaxResponseBytes = 1024 * 1024;

/// Validates raw wire responses against the JSON-RPC 2.0 envelope before
/// they reach the MCP clients / engine. See the file header for the
/// rejection contract.
final class McpWireValidator {
  /// Maximum accepted response body size, in UTF-8 bytes.
  final int maxResponseBytes;

  const McpWireValidator({
    this.maxResponseBytes = defaultMcpWireMaxResponseBytes,
  });

  /// Validates one server response.
  ///
  /// [rawBody] is the response exactly as it arrived on the wire (the size
  /// cap runs on its UTF-8 byte length); [message] is its JSON decoding;
  /// [expectedId] is the id the client sent with the request.
  ///
  /// Returns an `McpWireResponseOk` carrying the `result` payload when the
  /// response is clean; any violation returns an `McpWireResponseError`
  /// (never throws) — see the file header for the codes.
  McpWireResponse validateResponse({
    required String rawBody,
    required Map<String, dynamic> message,
    required Object? expectedId,
  }) {
    // Size cap first: a body over the cap is rejected before it is
    // interpreted, whatever else is wrong with it. Measured in UTF-8
    // bytes (>= the UTF-16 code-unit count, so multibyte payloads can't
    // sneak under the cap).
    final byteLength = utf8.encode(rawBody).length;
    if (byteLength > maxResponseBytes) {
      return McpWireResponseError(
        code: 'response-too-large',
        message:
            'MCP wire: response body of $byteLength bytes exceeds the '
            '$maxResponseBytes-byte wire cap',
      );
    }
    final envelopeViolation = _envelopeViolation(message, expectedId);
    if (envelopeViolation != null) {
      return McpWireResponseError(
        code: 'protocol-violation',
        message: envelopeViolation,
      );
    }
    // XOR holds and `error` is an object here (checked above): an error
    // response maps to the typed error, per the wire dialect contract.
    final error = message['error'];
    if (error is Map) {
      return McpWireResponseError(
        code: error['code']?.toString() ?? '',
        message: error['message']?.toString() ?? '',
      );
    }
    final result = message['result'];
    if (result is! Map) {
      // `tools/list` / `tools/call` results are objects in the dialect
      // contract; anything else is an arbitrary shape and is rejected
      // instead of being silently mapped to an empty payload.
      return McpWireResponseError(
        code: 'protocol-violation',
        message:
            'MCP wire: invalid JSON-RPC envelope — "result" must be '
            'an object for tools/list and tools/call',
      );
    }
    final payload = result.cast<String, dynamic>();
    final contentViolation = _contentViolation(result, r'$.result');
    if (contentViolation != null) {
      return McpWireResponseError(
        code: 'invalid-content',
        message: contentViolation,
      );
    }
    return McpWireResponseOk(payload);
  }

  String? _envelopeViolation(Map<String, dynamic> message, Object? expectedId) {
    if (message['jsonrpc'] != '2.0') {
      return 'MCP wire: invalid JSON-RPC envelope — "jsonrpc" must be "2.0"';
    }
    if (!message.containsKey('id') || message['id'] != expectedId) {
      return 'MCP wire: invalid JSON-RPC envelope — response "id" does not '
          'match the request id';
    }
    final hasResult = message.containsKey('result');
    final hasError = message.containsKey('error');
    if (hasResult && hasError) {
      return 'MCP wire: invalid JSON-RPC envelope — "result" and "error" '
          'are mutually exclusive';
    }
    if (!hasResult && !hasError) {
      return 'MCP wire: invalid JSON-RPC envelope — response carries '
          'neither "result" nor "error"';
    }
    if (hasError && message['error'] is! Map) {
      return 'MCP wire: invalid JSON-RPC envelope — "error" must be an '
          'object';
    }
    return null;
  }

  /// Returns a violation message naming the JSON path, or null when every
  /// string reachable from [value] is clean.
  String? _contentViolation(Object? value, String path) {
    if (value is String) return _stringViolation(value, path);
    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        final violation = _contentViolation(value[i], '$path[$i]');
        if (violation != null) return violation;
      }
    } else if (value is Map) {
      for (final key in value.keys) {
        if (key is String) {
          final keyViolation = _stringViolation(key, '$path.<key>');
          if (keyViolation != null) return keyViolation;
        }
        final label = key is String ? key : '<key>';
        final violation = _contentViolation(value[key], '$path.$label');
        if (violation != null) return violation;
      }
    }
    return null;
  }

  /// Content policy (issue #131): reject C0 control characters except tab,
  /// newline and carriage return (legitimate whitespace), reject DEL and
  /// the C1 range, and reject unmatched UTF-16 surrogate pairs (lone
  /// surrogates corrupt every downstream UTF-8 round-trip).
  String? _stringViolation(String s, String path) {
    for (var i = 0; i < s.length; i++) {
      final unit = s.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        final next = i + 1 < s.length ? s.codeUnitAt(i + 1) : 0;
        if (next < 0xDC00 || next > 0xDFFF) {
          return 'MCP wire: tool-result content at $path contains an '
              'unmatched high surrogate (U+${unit.toRadixString(16)})';
        }
        i++; // valid pair — skip its low half so it is not re-examined
      } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
        return 'MCP wire: tool-result content at $path contains an '
            'unmatched low surrogate (U+${unit.toRadixString(16)})';
      } else if (unit < 0x20) {
        if (unit != 0x09 && unit != 0x0A && unit != 0x0D) {
          return 'MCP wire: tool-result content at $path contains control '
              'character U+${unit.toRadixString(16).padLeft(4, '0')}';
        }
      } else if (unit == 0x7F || (unit >= 0x80 && unit <= 0x9F)) {
        return 'MCP wire: tool-result content at $path contains control '
            'character U+${unit.toRadixString(16).padLeft(4, '0')}';
      }
    }
    return null;
  }
}
