// Concrete HTTP implementation of [LlmClient] for OpenAI-compatible
// chat-completions endpoints (OpenAI, Moonshot/Kimi, Groq, DeepSeek,
// OpenRouter, vLLM, Ollama's OpenAI shim, ...).
//
// Hand-written engine glue. Talks the OpenAI wire protocol only — no
// provider-specific branching.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../providers.dart'
    show LlmClient, LlmResponse, LlmResponseChunk, LlmUsage, ToolCall;

/// An [LlmClient] backed by an OpenAI-compatible `/chat/completions` endpoint.
///
/// Both [generate] (single non-streaming POST) and [stream] (SSE) are
/// implemented against the OpenAI wire format:
///
/// * tool call `arguments` travel as a JSON **string** on the wire and are
///   decoded into `Map<String, dynamic>` before being handed to the engine;
/// * streamed `delta.tool_calls` fragments are accumulated by their `index`
///   until the stream finishes, then emitted as one final chunk;
/// * `delta.reasoning_content` and `delta.reasoning` are both mapped onto
///   [LlmResponseChunk.thinking].
///
/// Example:
/// ```dart
/// final client = OpenAiCompatibleLlmClient(
///   baseUrl: 'https://api.moonshot.ai/v1',
///   apiKey: apiKey,
///   model: 'kimi-k2-0905-preview',
/// );
/// ```
class OpenAiCompatibleLlmClient implements LlmClient {
  /// Creates a client targeting `<baseUrl>/chat/completions`.
  ///
  /// [baseUrl] is normalized: a trailing slash is optional, and `/v1` is
  /// appended only when it is not already present, so both
  /// `https://api.openai.com` and `https://api.openai.com/v1/` resolve to the
  /// same endpoint. A [baseUrl] that already points at `/chat/completions` is
  /// used verbatim.
  ///
  /// When [httpClient] is supplied the caller keeps ownership of it and
  /// [close] leaves it open; otherwise an internal [http.Client] is created
  /// and closed by [close].
  OpenAiCompatibleLlmClient({
    required String baseUrl,
    required String apiKey,
    this.model = 'gpt-4o-mini',
    this.timeout = const Duration(seconds: 60),
    http.Client? httpClient,
    this.extraHeaders = const {},
  })  : _apiKey = apiKey,
        _endpoint = _resolveEndpoint(baseUrl),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  /// Model id sent as the `model` field of every request.
  final String model;

  /// Per-request timeout applied to both [generate] and [stream].
  final Duration timeout;

  /// Additional headers merged into every request (overriding the defaults).
  final Map<String, String> extraHeaders;

  final String _apiKey;
  final Uri _endpoint;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  /// The fully resolved chat-completions endpoint this client posts to.
  Uri get endpoint => _endpoint;

  @override
  Future<LlmResponse> generate({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async {
    final body = _buildBody(messages: messages, tools: tools, config: config);

    final response = await _httpClient
        .post(_endpoint, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response.statusCode, response.body));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'OpenAiCompatibleLlmClient: unexpected response shape from $_endpoint: '
        '${_truncate(response.body)}',
      );
    }

    final choices = decoded['choices'];
    final choice = (choices is List && choices.isNotEmpty)
        ? _asMap(choices.first)
        : const <String, dynamic>{};
    final message = _asMap(choice['message']);

    final content = message['content'] is String
        ? message['content'] as String
        : '';
    final toolCalls = _parseToolCalls(message['tool_calls']);
    final finishReason = choice['finish_reason'] is String
        ? choice['finish_reason'] as String
        : (toolCalls.isNotEmpty ? 'tool_calls' : 'stop');

    return LlmResponse(
      content: content,
      toolCalls: toolCalls,
      usage: _parseUsage(decoded['usage']) ??
          const LlmUsage(inputTokens: 0, outputTokens: 0),
      finishReason: finishReason,
    );
  }

  @override
  Stream<LlmResponseChunk> stream({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) async* {
    final body = _buildBody(messages: messages, tools: tools, config: config)
      ..['stream'] = true
      ..['stream_options'] = <String, dynamic>{'include_usage': true};

    final request = http.Request('POST', _endpoint)
      ..headers.addAll(_headers())
      ..body = jsonEncode(body);

    final response = await _httpClient.send(request).timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(_errorMessage(response.statusCode, errorBody));
    }

    final fragments = <int, _ToolCallFragment>{};
    LlmUsage? usage;
    String? finishReason;

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final rawLine in lines) {
      final line = rawLine.trim();
      // Blank keep-alive lines and `:` comments carry no payload.
      if (line.isEmpty || line.startsWith(':')) continue;
      if (!line.startsWith('data:')) continue;

      final payload = line.substring('data:'.length).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;

      Object? decoded;
      try {
        decoded = jsonDecode(payload);
      } on FormatException {
        continue; // Tolerate partial/garbage frames rather than dying.
      }
      if (decoded is! Map<String, dynamic>) continue;

      final parsedUsage = _parseUsage(decoded['usage']);
      if (parsedUsage != null) usage = parsedUsage;

      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) continue; // usage-only chunk
      final choice = _asMap(choices.first);

      if (choice['finish_reason'] is String) {
        finishReason = choice['finish_reason'] as String;
      }

      final delta = _asMap(choice['delta']);

      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        yield LlmResponseChunk(
          content: content,
          toolCalls: const [],
          isComplete: false,
        );
      }

      final reasoning = delta['reasoning_content'] ?? delta['reasoning'];
      if (reasoning is String && reasoning.isNotEmpty) {
        yield LlmResponseChunk(
          content: '',
          thinking: reasoning,
          toolCalls: const [],
          isComplete: false,
        );
      }

      _accumulateToolCallFragments(delta['tool_calls'], fragments);
    }

    final assembledToolCalls = _assembleToolCalls(fragments);

    yield LlmResponseChunk(
      content: '',
      toolCalls: assembledToolCalls,
      usage: usage,
      isComplete: true,
      finishReason: finishReason ??
          (assembledToolCalls.isNotEmpty ? 'tool_calls' : 'stop'),
    );
  }

  @override
  Future<void> close() async {
    // Never close a client the caller handed us — they may still be using it.
    if (_ownsHttpClient) _httpClient.close();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Map<String, String> _headers() => <String, String>{
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
        ...extraHeaders,
      };

  Map<String, dynamic> _buildBody({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required Map<String, dynamic> config,
  }) {
    return <String, dynamic>{
      'model': model,
      'messages': messages,
      if (tools.isNotEmpty) 'tools': tools,
      if (tools.isNotEmpty) 'tool_choice': 'auto',
      ...config,
    };
  }

  /// Normalizes [baseUrl] into a `/chat/completions` endpoint.
  static Uri _resolveEndpoint(String baseUrl) {
    var normalized = baseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.endsWith('/chat/completions')) {
      return Uri.parse(normalized);
    }
    if (!normalized.endsWith('/v1')) {
      normalized = '$normalized/v1';
    }
    return Uri.parse('$normalized/chat/completions');
  }

  static void _accumulateToolCallFragments(
    Object? raw,
    Map<int, _ToolCallFragment> fragments,
  ) {
    if (raw is! List) return;
    for (final entry in raw) {
      final map = _asMap(entry);
      if (map.isEmpty) continue;
      final index = (map['index'] as num?)?.toInt() ?? fragments.length;
      final fragment =
          fragments.putIfAbsent(index, () => _ToolCallFragment(index));

      final id = map['id'];
      if (id is String && id.isNotEmpty) fragment.id = id;

      final function = _asMap(map['function']);
      final name = function['name'];
      if (name is String && name.isNotEmpty) fragment.name = name;
      final arguments = function['arguments'];
      if (arguments is String) fragment.arguments.write(arguments);
    }
  }

  static List<ToolCall> _assembleToolCalls(
    Map<int, _ToolCallFragment> fragments,
  ) {
    final indexes = fragments.keys.toList()..sort();
    return [
      for (final index in indexes)
        ToolCall(
          id: fragments[index]!.id ?? 'call_$index',
          name: fragments[index]!.name ?? '',
          arguments: _decodeArguments(fragments[index]!.arguments.toString()),
        ),
    ];
  }

  static List<ToolCall> _parseToolCalls(Object? raw) {
    if (raw is! List) return const [];
    final calls = <ToolCall>[];
    for (var i = 0; i < raw.length; i++) {
      final map = _asMap(raw[i]);
      if (map.isEmpty) continue;
      final function = _asMap(map['function']);
      calls.add(ToolCall(
        id: map['id'] is String ? map['id'] as String : 'call_$i',
        name: function['name'] is String ? function['name'] as String : '',
        arguments: _decodeArguments(function['arguments']),
      ));
    }
    return calls;
  }

  /// Decodes the OpenAI `function.arguments` JSON **string** into a map,
  /// tolerating null, empty and malformed payloads as `{}`.
  static Map<String, dynamic> _decodeArguments(Object? raw) {
    if (raw is Map) return _asMap(raw);
    if (raw is! String) return <String, dynamic>{};
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is Map ? _asMap(decoded) : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  static LlmUsage? _parseUsage(Object? raw) {
    if (raw is! Map) return null;
    final usage = _asMap(raw);
    if (usage.isEmpty) return null;
    var cachedTokens = 0;
    final details = usage['prompt_tokens_details'];
    if (details is Map) {
      cachedTokens = (_asMap(details)['cached_tokens'] as num?)?.toInt() ?? 0;
    }
    return LlmUsage(
      inputTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
      cachedTokens: cachedTokens,
    );
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  String _errorMessage(int statusCode, String body) =>
      'OpenAiCompatibleLlmClient: HTTP $statusCode from $_endpoint: '
      '${_truncate(body)}';

  static String _truncate(String value, [int maxLength = 500]) =>
      value.length <= maxLength
          ? value
          : '${value.substring(0, maxLength)}... (truncated)';
}

/// Mutable accumulator for a streamed tool call, keyed by its wire `index`.
class _ToolCallFragment {
  _ToolCallFragment(this.index);

  final int index;
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();
}
