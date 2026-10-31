// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.

/// An outbound HTTP request through the transport seam.
///
/// The engine's runtime paths never import `dart:io` (constitution VII); every
/// provider client talks to this interface instead. The concrete adapter is
/// `IoLlmTransport` (the single CI-allowlisted `dart:io` file); tests replay
/// recorded fixtures through a fake implementation.
class LlmHttpRequest {
  /// The URI.
  final Uri uri;

  /// The method.
  final String method;

  /// The headers.
  final Map<String, String> headers;

  /// The body.
  final String body;

  /// Creates an LLM HTTP request.
  const LlmHttpRequest({
    required this.uri,
    this.method = 'POST',
    this.headers = const {},
    this.body = '',
  });
}

/// A complete (non-streaming) HTTP response.
class LlmHttpResponse {
  /// The status code.
  final int statusCode;

  /// The headers.
  final Map<String, String> headers;

  /// The body.
  final String body;

  /// Creates an LLM HTTP response.
  const LlmHttpResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = '',
  });

  /// Whether the LLM HTTP response is ok.
  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// A streaming HTTP response exposing a decoded line stream (SSE lines for
/// OpenAI/Anthropic, JSON lines for Gemini).
class LlmStreamResponse {
  /// The status code.
  final int statusCode;

  /// The headers.
  final Map<String, String> headers;

  /// The lines.
  final Stream<String> lines;

  /// Creates an LLM stream response.
  const LlmStreamResponse({
    required this.statusCode,
    this.headers = const {},
    required this.lines,
  });

  /// Whether the LLM stream response is ok.
  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Transport seam for all provider clients
/// (spec 007 plan: `llm_transport.dart`).
abstract interface class LlmTransport {
  /// Sends a request and awaits the complete response.
  ///
  /// Throws `LlmNetworkException` on connection-level failure (no HTTP status
  /// arrived). HTTP error statuses are RETURNED, not thrown — retry policy
  /// needs to inspect them.
  Future<LlmHttpResponse> send(LlmHttpRequest request);

  /// Sends a request and opens a streaming response (line stream).
  Future<LlmStreamResponse> openStream(LlmHttpRequest request);

  /// Releases the transport's resources (sockets, connection pools).
  ///
  /// Ownership (issue #159 review): the closer owns the transport. A
  /// transport injected into more than one client is closed for ALL of them
  /// when any closer closes it — share a transport only when its lifetime
  /// is managed above the clients.
  Future<void> close();
}
