// Ported from dart_agent_core (MIT License, Copyright (c) 2024-2026
// contributors) — see NOTICE. dart_agent_core is NOT a dependency of this
// package (spec 007 FR-007, constitution VIII): the behavior is re-implemented
// in-tree per specs/007-llm-provider-clients/spec.md with this attribution
// retained.
//
// NOTE (constitution VII — engine purity): this is the single dart:io adapter
// file for the LLM layer. All provider clients stay dart:io-free by talking to
// the LlmTransport seam; this file is the only concrete IO implementation and
// is registered in the CI purity allowlist (.github/workflows/pipeline.yml)
// with this justification, following the gate's documented review process.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'llm_client.dart';
import 'llm_transport.dart';

/// dart:io-backed [LlmTransport] (spec 007 plan: `io_llm_transport.dart`).
class IoLlmTransport implements LlmTransport {
  final String provider;
  final HttpClient _client;

  IoLlmTransport({this.provider = 'io', HttpClient? client})
      : _client = client ?? HttpClient();

  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async {
    final response = await _open(request);
    final body = await utf8.decoder.bind(response).join();
    return LlmHttpResponse(
      statusCode: response.statusCode,
      headers: _headerMap(response),
      body: body,
    );
  }

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) async {
    final response = await _open(request);
    return LlmStreamResponse(
      statusCode: response.statusCode,
      headers: _headerMap(response),
      lines: utf8.decoder.bind(response).transform(const LineSplitter()),
    );
  }

  /// Releases the underlying [HttpClient].
  Future<void> close() async => _client.close();

  Future<HttpClientResponse> _open(LlmHttpRequest request) async {
    final bodyBytes = utf8.encode(request.body);
    try {
      final ioRequest = await _client.openUrl(request.method, request.uri);
      request.headers.forEach(ioRequest.headers.set);
      ioRequest.contentLength = bodyBytes.length;
      ioRequest.add(bodyBytes);
      return await ioRequest.close();
    } on SocketException catch (e) {
      throw LlmNetworkException(provider: provider, cause: e);
    } on HttpException catch (e) {
      throw LlmNetworkException(provider: provider, cause: e);
    }
  }

  static Map<String, String> _headerMap(HttpClientResponse response) {
    final map = <String, String>{};
    response.headers.forEach((name, values) {
      map[name.toLowerCase()] = values.join(',');
    });
    return map;
  }
}
