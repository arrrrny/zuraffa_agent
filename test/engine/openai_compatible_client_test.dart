// Tests for OpenAiCompatibleLlmClient — the shipped HTTP implementation of
// LlmClient against an OpenAI-compatible /chat/completions endpoint.
//
// The wire protocol is exercised through package:http MockClient so no real
// network traffic is involved.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/providers/openai_compatible_client.dart';

/// Builds a streaming MockClient that replays [lines] as an SSE body.
///
/// Each entry is emitted as its own chunk followed by the SSE record
/// separator, mirroring how a real endpoint dribbles frames out.
MockClient _sseClient(
  List<String> lines, {
  int statusCode = 200,
  void Function(http.BaseRequest request, String body)? onRequest,
}) {
  return MockClient.streaming((request, bodyStream) async {
    if (onRequest != null) {
      onRequest(request, utf8.decode(await bodyStream.toBytes()));
    }
    final body = Stream<List<int>>.fromIterable(
      lines.map((line) => utf8.encode('$line\n\n')),
    );
    return http.StreamedResponse(body, statusCode, request: request);
  });
}

String _data(Map<String, dynamic> payload) => 'data: ${jsonEncode(payload)}';

Map<String, dynamic> _delta(Map<String, dynamic> delta, {String? finishReason}) {
  return {
    'choices': [
      {'index': 0, 'delta': delta, 'finish_reason': finishReason},
    ],
  };
}

void main() {
  group('OpenAiCompatibleLlmClient - endpoint normalization', () {
    test('appends /v1/chat/completions to a bare base URL', () {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com',
        apiKey: 'k',
      );
      expect(
        client.endpoint.toString(),
        'https://api.example.com/v1/chat/completions',
      );
    });

    test('does not double /v1 and tolerates a trailing slash', () {
      final withV1 = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1/',
        apiKey: 'k',
      );
      expect(
        withV1.endpoint.toString(),
        'https://api.example.com/v1/chat/completions',
      );
    });

    test('accepts a full chat/completions URL verbatim', () {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/openai/v1/chat/completions',
        apiKey: 'k',
      );
      expect(
        client.endpoint.toString(),
        'https://api.example.com/openai/v1/chat/completions',
      );
    });
  });

  group('OpenAiCompatibleLlmClient.stream', () {
    test('emits content deltas and one final complete chunk', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          _data(_delta({'role': 'assistant', 'content': ''})),
          _data(_delta({'content': 'Hello'})),
          _data(_delta({'content': ' world'})),
          _data(_delta({}, finishReason: 'stop')),
          'data: [DONE]',
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
        tools: const [],
        config: const {},
      ).toList();

      final contentChunks = chunks.where((c) => c.content.isNotEmpty).toList();
      expect(contentChunks.map((c) => c.content).toList(), ['Hello', ' world']);
      expect(contentChunks.every((c) => !c.isComplete), isTrue);

      final finalChunks = chunks.where((c) => c.isComplete).toList();
      expect(finalChunks.length, 1);
      expect(finalChunks.single.finishReason, 'stop');
      expect(finalChunks.single.toolCalls, isEmpty);
      expect(finalChunks.single.usage, isNull);
    });

    test('maps reasoning_content and reasoning onto thinking', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          _data(_delta({'reasoning_content': 'step one'})),
          _data(_delta({'reasoning': 'step two'})),
          _data(_delta({'content': 'answer'}, finishReason: 'stop')),
          'data: [DONE]',
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      final thinking = chunks
          .where((c) => (c.thinking ?? '').isNotEmpty)
          .map((c) => c.thinking)
          .toList();
      expect(thinking, ['step one', 'step two']);
    });

    test('assembles a tool call from streamed argument fragments', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          _data(_delta({
            'tool_calls': [
              {
                'index': 0,
                'id': 'call_abc',
                'type': 'function',
                'function': {'name': 'search_products', 'arguments': ''},
              },
            ],
          })),
          _data(_delta({
            'tool_calls': [
              {
                'index': 0,
                'function': {'arguments': '{"query":"red '},
              },
            ],
          })),
          _data(_delta({
            'tool_calls': [
              {
                'index': 0,
                'function': {'arguments': 'shoes","limit":5}'},
              },
            ],
          })),
          _data(_delta({}, finishReason: 'tool_calls')),
          'data: [DONE]',
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      final finalChunk = chunks.singleWhere((c) => c.isComplete);
      expect(finalChunk.finishReason, 'tool_calls');
      expect(finalChunk.toolCalls.length, 1);
      expect(finalChunk.toolCalls.single.id, 'call_abc');
      expect(finalChunk.toolCalls.single.name, 'search_products');
      expect(finalChunk.toolCalls.single.arguments,
          {'query': 'red shoes', 'limit': 5});
    });

    test('assembles parallel tool calls keyed by index', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          _data(_delta({
            'tool_calls': [
              {
                'index': 1,
                'id': 'call_second',
                'function': {'name': 'b', 'arguments': '{"i":2}'},
              },
              {
                'index': 0,
                'id': 'call_first',
                'function': {'name': 'a', 'arguments': '{"i":1}'},
              },
            ],
          })),
          'data: [DONE]',
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      final finalChunk = chunks.singleWhere((c) => c.isComplete);
      expect(finalChunk.toolCalls.map((c) => c.id).toList(),
          ['call_first', 'call_second']);
      expect(finalChunk.toolCalls.map((c) => c.name).toList(), ['a', 'b']);
      // finish_reason never arrived, but tool calls did.
      expect(finalChunk.finishReason, 'tool_calls');
    });

    test('stops at [DONE] and ignores blank lines, comments and junk',
        () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          ': keep-alive comment',
          '',
          'event: message',
          'data: {not json at all',
          _data(_delta({'content': 'kept'})),
          'data: [DONE]',
          _data(_delta({'content': 'must be ignored'})),
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      expect(
        chunks.where((c) => c.content.isNotEmpty).map((c) => c.content).toList(),
        ['kept'],
      );
      expect(chunks.where((c) => c.isComplete).length, 1);
    });

    test('parses the trailing usage-only chunk', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: _sseClient([
          _data(_delta({'content': 'hi'}, finishReason: 'stop')),
          _data({
            'choices': <Map<String, dynamic>>[],
            'usage': {
              'prompt_tokens': 120,
              'completion_tokens': 7,
              'prompt_tokens_details': {'cached_tokens': 64},
            },
          }),
          'data: [DONE]',
        ]),
      );
      addTearDown(client.close);

      final chunks = await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      final usage = chunks.singleWhere((c) => c.isComplete).usage;
      expect(usage, isNotNull);
      expect(usage!.inputTokens, 120);
      expect(usage.outputTokens, 7);
      expect(usage.cachedTokens, 64);
      expect(usage.totalTokens, 127);
    });

    test('sends stream flags, auth header and tool_choice', () async {
      http.BaseRequest? seenRequest;
      String? seenBody;
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        model: 'test-model',
        extraHeaders: const {'X-Trace': 'abc'},
        httpClient: _sseClient(
          ['data: [DONE]'],
          onRequest: (request, body) {
            seenRequest = request;
            seenBody = body;
          },
        ),
      );
      addTearDown(client.close);

      await client.stream(
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
        tools: [
          {
            'type': 'function',
            'function': {'name': 'search_products'},
          },
        ],
        config: const {'temperature': 0.3},
      ).toList();

      expect(seenRequest!.method, 'POST');
      expect(seenRequest!.url.toString(),
          'https://api.example.com/v1/chat/completions');
      expect(seenRequest!.headers['Authorization'], 'Bearer secret');
      expect(seenRequest!.headers['X-Trace'], 'abc');

      final body = jsonDecode(seenBody!) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['stream'], isTrue);
      expect(body['stream_options'], {'include_usage': true});
      expect(body['tool_choice'], 'auto');
      expect(body['temperature'], 0.3);
      expect((body['tools'] as List).length, 1);
    });

    test('omits the Authorization header when the API key is empty', () async {
      http.BaseRequest? seenRequest;
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'http://localhost:11434/v1',
        apiKey: '',
        httpClient: _sseClient(
          ['data: [DONE]'],
          onRequest: (request, _) => seenRequest = request,
        ),
      );
      addTearDown(client.close);

      await client.stream(
        messages: const [],
        tools: const [],
        config: const {},
      ).toList();

      expect(seenRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('throws with status code and body on a non-2xx response', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'secret',
        httpClient: MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable(
                [utf8.encode('{"error":{"message":"bad tool message"}}')]),
            400,
            request: request,
          );
        }),
      );
      addTearDown(client.close);

      await expectLater(
        client.stream(
          messages: const [],
          tools: const [],
          config: const {},
        ).toList(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(contains('400'), contains('bad tool message')),
        )),
      );
    });
  });

  group('OpenAiCompatibleLlmClient.generate', () {
    test('parses content, tool calls, finish reason and usage', () async {
      String? seenBody;
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com',
        apiKey: 'secret',
        model: 'test-model',
        httpClient: MockClient((request) async {
          seenBody = request.body;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'index': 0,
                  'message': {
                    'role': 'assistant',
                    'content': 'Here you go',
                    'tool_calls': [
                      {
                        'id': 'call_1',
                        'type': 'function',
                        'function': {
                          'name': 'search_products',
                          'arguments': '{"query":"boots"}',
                        },
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
              'usage': {'prompt_tokens': 11, 'completion_tokens': 3},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);

      final response = await client.generate(
        messages: [
          {'role': 'user', 'content': 'boots?'},
        ],
        tools: const [],
        config: const {},
      );

      expect(response.content, 'Here you go');
      expect(response.finishReason, 'tool_calls');
      expect(response.toolCalls.single.name, 'search_products');
      expect(response.toolCalls.single.arguments, {'query': 'boots'});
      expect(response.usage.inputTokens, 11);
      expect(response.usage.outputTokens, 3);

      final body = jsonDecode(seenBody!) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body.containsKey('stream'), isFalse);
      // tools were empty, so neither key is sent.
      expect(body.containsKey('tools'), isFalse);
      expect(body.containsKey('tool_choice'), isFalse);
    });

    test('tolerates malformed tool arguments as an empty map', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com',
        apiKey: 'secret',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': null,
                    'tool_calls': [
                      {
                        'id': 'call_1',
                        'function': {'name': 'ping', 'arguments': 'not-json'},
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final response = await client.generate(
        messages: const [],
        tools: const [],
        config: const {},
      );

      expect(response.content, '');
      expect(response.toolCalls.single.arguments, isEmpty);
      // No finish_reason on the wire, but tool calls were present.
      expect(response.finishReason, 'tool_calls');
      expect(response.usage.totalTokens, 0);
    });

    test('throws with status code and body on a non-2xx response', () async {
      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com',
        apiKey: 'secret',
        httpClient: MockClient((request) async {
          return http.Response('server exploded', 503);
        }),
      );
      addTearDown(client.close);

      await expectLater(
        client.generate(
          messages: const [],
          tools: const [],
          config: const {},
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(contains('503'), contains('server exploded')),
        )),
      );
    });
  });

  group('OpenAiCompatibleLlmClient.close', () {
    test('leaves a caller-supplied http client open', () async {
      var closed = false;
      final inner = MockClient((request) async => http.Response('{}', 200));
      final tracking = _CloseTrackingClient(inner, () => closed = true);

      final client = OpenAiCompatibleLlmClient(
        baseUrl: 'https://api.example.com',
        apiKey: 'secret',
        httpClient: tracking,
      );
      await client.close();

      expect(closed, isFalse);
    });
  });
}

/// Wraps a client so the test can observe whether [close] was called.
class _CloseTrackingClient extends http.BaseClient {
  _CloseTrackingClient(this._inner, this._onClose);

  final http.Client _inner;
  final void Function() _onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {
    _onClose();
    _inner.close();
  }
}
