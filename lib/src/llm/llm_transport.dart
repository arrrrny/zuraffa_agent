// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.

/// An outbound HTTP request through the transport seam.
///
/// The engine's runtime paths never import `dart:io` (constitution VII); every
/// provider client talks to this interface instead. The concrete adapter is
/// [IoLlmTransport] (the single CI-allowlisted `dart:io` file); tests replay
/// recorded fixtures through a fake implementation.
class LlmHttpRequest {
  final Uri uri;
  final String method;
  final Map<String, String> headers;
  final String body;

  const LlmHttpRequest({
    required this.uri,
    this.method = 'POST',
    this.headers = const {},
    this.body = '',
  });
}

/// A complete (non-streaming) HTTP response.
class LlmHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  const LlmHttpResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = '',
  });

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// A streaming HTTP response exposing a decoded line stream (SSE lines for
/// OpenAI/Anthropic, JSON lines for Gemini).
class LlmStreamResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Stream<String> lines;

  const LlmStreamResponse({
    required this.statusCode,
    this.headers = const {},
    required this.lines,
  });

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Transport seam for all provider clients (spec 007 plan: `llm_transport.dart`).
abstract interface class LlmTransport {
  /// Sends a request and awaits the complete response.
  ///
  /// Throws [LlmNetworkException] on connection-level failure (no HTTP status
  /// arrived). HTTP error statuses are RETURNED, not thrown — retry policy
  /// needs to inspect them.
  Future<LlmHttpResponse> send(LlmHttpRequest request);

  /// Sends a request and opens a streaming response (line stream).
  Future<LlmStreamResponse> openStream(LlmHttpRequest request);
}
