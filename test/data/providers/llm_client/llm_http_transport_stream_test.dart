// Unit tests for LlmHttpTransport's streaming response-parse helper (issue
// #123). Pure-function coverage: SSE lines in, LlmResponseChunk out — no
// network, same shape as the non-streaming parse tests above it.
//
// The parser is shared with OpenAiCompatibleClient.stream
// (lib/src/llm/sse_chat_chunk_parser.dart, issue #123 review): one wire
// implementation for both OpenAI-compatible streaming paths.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_http_transport.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';

Stream<LlmResponseChunk> parse(List<String> lines) =>
    parseChatCompletionChunkStream(Stream<String>.fromIterable(lines));

Future<List<LlmResponseChunk>> drain(Stream<LlmResponseChunk> chunks) =>
    chunks.toList();

String data(Object json) => 'data: ${jsonEncode(json)}';

void main() {
  group('parseChatCompletionChunkStream (issue #123)', () {
    test('yields one content chunk per non-empty delta.content', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'Hel'},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'lo'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks.map((c) => c.content), ['Hel', 'lo', null]);
      expect(chunks.last.isComplete, isTrue);
    });

    test('maps reasoning deltas to thinking chunks', () async {
      final chunks = await drain(
        parse([
          // OpenRouter-style `reasoning` and DeepSeek-style
          // `reasoning_content` both carry thinking text.
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning': 'step '},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning_content': 'one'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks.map((c) => c.thinking), ['step ', 'one', null]);
      expect(
        chunks.whereType<LlmResponseChunk>().every(
          (c) => c.content == null || c.content!.isEmpty,
        ),
        isTrue,
      );
    });

    test(
      'buffers tool_calls fragments and emits them on finish_reason',
      () async {
        final chunks = await drain(
          parse([
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'call_1',
                        'function': {'name': 'search', 'arguments': '{"q":'},
                      },
                    ],
                  },
                },
              ],
            }),
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': '"zuraffa"}'},
                      },
                    ],
                  },
                },
              ],
            }),
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': <String, dynamic>{},
                  'finish_reason': 'tool_calls',
                },
              ],
            }),
            'data: [DONE]',
          ]),
        );

        final toolChunk = chunks.firstWhere((c) => c.toolCalls.isNotEmpty);
        expect(toolChunk.toolCalls, hasLength(1));
        expect(toolChunk.toolCalls.single.id, 'call_1');
        expect(toolChunk.toolCalls.single.name, 'search');
        expect(toolChunk.toolCalls.single.arguments, {'q': 'zuraffa'});
        expect(toolChunk.finishReason, 'tool_calls');

        // Exactly one final chunk and no duplicates after [DONE].
        expect(chunks.where((c) => c.isComplete), hasLength(1));
      },
    );

    test(
      'captures usage from the trailing usage event and completes',
      () async {
        final chunks = await drain(
          parse([
            data({
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': 'ok'},
                },
              ],
            }),
            data({
              'choices': <Object>[],
              'usage': {
                'prompt_tokens': 5,
                'completion_tokens': 2,
                'prompt_tokens_details': {'cached_tokens': 1},
                'completion_tokens_details': {'reasoning_tokens': 1},
              },
            }),
            'data: [DONE]',
          ]),
        );

        // content delta, then the trailing usage event finalizes the stream.
        expect(chunks, hasLength(2));
        expect(chunks[1].usage, isNotNull);
        expect(chunks[1].usage!.inputTokens, 5);
        expect(chunks[1].usage!.outputTokens, 2);
        expect(chunks[1].usage!.cachedTokens, 1);
        expect(chunks[1].usage!.thoughtTokens, 1);
        expect(chunks[1].isComplete, isTrue);
      },
    );

    test('finalizes even when the stream ends without [DONE]', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'cut'},
              },
            ],
          }),
        ]),
      );

      expect(chunks, hasLength(2));
      expect(chunks.last.isComplete, isTrue);
      expect(chunks.last.finishReason, 'stop');
    });

    test('skips empty lines, comments, and malformed payloads', () async {
      final chunks = await drain(
        parse([
          '',
          ': keep-alive comment',
          'data: not-json',
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'ok'},
              },
            ],
          }),
          'data: [DONE]',
        ]),
      );

      expect(chunks, hasLength(2)); // content + final
      expect(chunks.first.content, 'ok');
    });

    test('empty and whitespace-only deltas yield no chunks', () async {
      final chunks = await drain(
        parse([
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'content': ''},
              },
            ],
          }),
          data({
            'choices': [
              {
                'index': 0,
                'delta': {'reasoning': ''},
              },
            ],
          }),
          data({
            'choices': [
              {'index': 0, 'delta': <String, dynamic>{}},
            ],
          }),
          'data: [DONE]',
        ]),
      );

      // Only the finalize chunk survives; empty deltas are dropped.
      expect(chunks, hasLength(1));
      expect(chunks.single.isComplete, isTrue);
    });

    test('cancel completes while the parser waits at await-for for the next '
        'line (issue #163)', () async {
      // Both lines below are delivered before the cancel, so the
      // generator is suspended at `await for` (requesting line 3) — the
      // suspension from which an async* cancel never resumes on Dart
      // 3.13.5: `subscription.cancel()` hung instead of completing.
      final controller = StreamController<String>();
      final sub = parseChatCompletionChunkStream(
        controller.stream,
      ).listen((_) {});

      controller.add(
        data({
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'a'},
            },
          ],
        }),
      );
      controller.add(
        data({
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'b'},
            },
          ],
        }),
      );
      await pumpEventQueue();

      await sub.cancel().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            fail('sub.cancel() did not complete (issue #163 wedge)'),
      );
      await controller.close();
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('streamComplete wire path (scripted fake HttpClient, issue #123)', () {
    test(
      'builds a streaming request with usage opt-in and auth headers',
      () async {
        final client = _ScriptedHttpClient('data: [DONE]\n\n');
        final transport = LlmHttpTransport(clientFactory: () => client);

        await transport
            .streamComplete(
              baseUrl: 'http://example.test/v1',
              apiKey: 'secret-key',
              model: 'tencent/hy3:free',
              messages: const [ChatMessage(role: 'user', content: 'hi')],
            )
            .toList();

        expect(client.requests, hasLength(1));
        final request = client.requests.single;
        expect(
          request.uri,
          Uri.parse('http://example.test/v1/chat/completions'),
        );
        expect(request.headers['content-type'], 'application/json');
        expect(request.headers['authorization'], 'Bearer secret-key');

        final body =
            jsonDecode(request.body.toString()) as Map<String, dynamic>;
        expect(body['stream'], isTrue);
        // Regression (issue #123 review, finding 1): the streamed request must
        // opt into usage reporting, or spec-compliant gateways never emit the
        // trailing usage event and every streaming turn reports zero tokens.
        expect(body['stream_options'], {'include_usage': true});
      },
    );

    test(
      'forwards SSE chunks, captures usage, and closes the client',
      () async {
        const sse =
            'data: {"choices":[{"index":0,"delta":{"content":"ok"}}]}\n'
            'data: {"choices":[],"usage":{"prompt_tokens":5,'
            '"completion_tokens":2}}\n'
            'data: [DONE]\n\n';
        final client = _ScriptedHttpClient(sse);
        final transport = LlmHttpTransport(clientFactory: () => client);

        final chunks = await transport
            .streamComplete(
              baseUrl: 'http://example.test',
              apiKey: 'k',
              model: 'm',
              messages: const [ChatMessage(role: 'user', content: 'hi')],
            )
            .toList();

        expect(chunks, hasLength(2));
        expect(chunks.first.content, 'ok');
        expect(chunks.last.isComplete, isTrue);
        // The usage event the request opt-in asks for really lands on the
        // final chunk (pairs with the request-build test above).
        expect(chunks.last.usage!.inputTokens, 5);
        expect(chunks.last.usage!.outputTokens, 2);
        expect(client.closedCount, 1);
      },
    );

    test(
      'maps a non-200 response to LlmTransportException and closes',
      () async {
        final client = _ScriptedHttpClient('boom', statusCode: 502);
        final transport = LlmHttpTransport(clientFactory: () => client);

        await expectLater(
          transport
              .streamComplete(
                baseUrl: 'http://example.test',
                apiKey: 'k',
                model: 'm',
                messages: const [ChatMessage(role: 'user', content: 'hi')],
              )
              .toList(),
          throwsA(
            isA<LlmTransportException>()
                .having((e) => e.statusCode, 'statusCode', 502)
                .having((e) => e.body, 'body', 'boom'),
          ),
        );
        expect(client.closedCount, 1);
      },
    );

    test('closes the client when the consumer cancels mid-stream', () async {
      // First chunk now, then stay open: the consumer cancels while the
      // producer is still live, which must tear the HttpClient down.
      final controller = StreamController<List<int>>();
      final client = _ScriptedHttpClient.serving(controller.stream);
      final transport = LlmHttpTransport(clientFactory: () => client);

      final firstChunk = Completer<void>();
      final sub = transport
          .streamComplete(
            baseUrl: 'http://example.test',
            apiKey: 'k',
            model: 'm',
            messages: const [ChatMessage(role: 'user', content: 'hi')],
          )
          .listen((chunk) {
            if (!firstChunk.isCompleted) firstChunk.complete();
          });

      controller.add(
        utf8.encode(
          'data: {"choices":[{"index":0,"delta":{"content":"first"}}]}\n',
        ),
      );
      await firstChunk.future;
      await sub.cancel();
      await controller.close();
      // Allow the generator's finally block to run.
      await pumpEventQueue();
      expect(client.closedCount, 1);
    });

    test('cancel completes and closes the client while the gateway keeps '
        'emitting (issue #163)', () async {
      // The wedge needs the cancel to land while the chain is suspended
      // at `await for` — waiting for the NEXT line — which is exactly the
      // shape of a gateway that is still streaming. The single-delivery
      // test above cancels at the `yield` suspension and never reproduced
      // issue #163; this one does: `sub.cancel()` never completed and the
      // HttpClient teardown in the `finally` never ran.
      final controller = StreamController<List<int>>();
      final client = _ScriptedHttpClient.serving(controller.stream);
      final transport = LlmHttpTransport(clientFactory: () => client);

      final sub = transport
          .streamComplete(
            baseUrl: 'http://example.test',
            apiKey: 'k',
            model: 'm',
            messages: const [ChatMessage(role: 'user', content: 'hi')],
          )
          .listen((_) {});

      for (var i = 0; i < 3; i++) {
        controller.add(
          utf8.encode(
            'data: {"choices":[{"index":0,"delta":{"content":"c$i"}}]}\n',
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }

      await sub.cancel().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            fail('sub.cancel() did not complete (issue #163 wedge)'),
      );
      await controller.close();
      await pumpEventQueue();
      expect(client.closedCount, 1);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('installs the proxy resolver when proxyUrl is set', () async {
      final client = _ScriptedHttpClient('data: [DONE]\n\n');
      final transport = LlmHttpTransport(clientFactory: () => client);

      await transport
          .streamComplete(
            baseUrl: 'http://example.test',
            apiKey: 'k',
            proxyUrl: 'http://localhost:8890',
            model: 'm',
            messages: const [ChatMessage(role: 'user', content: 'hi')],
          )
          .toList();

      expect(client.findProxyAssigned, isTrue);
      expect(client.findProxyDirective, 'PROXY localhost:8890');
    });
  });
}

/// Scripted HttpClient double (issue #123 review): `postUrl` records the
/// request and answers with the scripted body bytes — the `clientFactory`
/// seam makes the wire path unit-testable without any network. The response
/// is a real one-shot byte stream so the utf8/LineSplitter transforms run
/// unchanged.
class _ScriptedHttpClient implements HttpClient {
  _ScriptedHttpClient(String body, {this.statusCode = 200})
    : _bodyBytes = utf8.encode(body),
      _byteStream = null;

  _ScriptedHttpClient.serving(Stream<List<int>> byteStream)
    : _bodyBytes = null,
      _byteStream = byteStream,
      statusCode = 200;

  final int statusCode;
  final List<int>? _bodyBytes;
  final Stream<List<int>>? _byteStream;
  final requests = <_RecordedWireRequest>[];
  int closedCount = 0;
  bool findProxyAssigned = false;
  String? findProxyDirective;

  @override
  set findProxy(String Function(Uri)? f) {
    findProxyAssigned = true;
    findProxyDirective = f?.call(
      Uri.parse('http://example.test/chat/completions'),
    );
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = _ScriptedHttpClientRequest(this, url);
    requests.add(request.record);
    return request;
  }

  @override
  void close({bool force = false}) => closedCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}

class _ScriptedHttpClientRequest implements HttpClientRequest {
  _ScriptedHttpClientRequest(this._client, Uri url)
    : record = _RecordedWireRequest(url);

  final _ScriptedHttpClient _client;
  final _RecordedWireRequest record;

  @override
  HttpHeaders get headers => _RecordedHttpHeaders(record.headers);

  @override
  void write(Object? object) => record.body.write(object);

  @override
  Future<HttpClientResponse> close() => Future.value(
    _ScriptedHttpClientResponse(
      _client.statusCode,
      _client._bodyBytes,
      _client._byteStream,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}

/// Header double: records `set` calls (lower-cased) for request assertions.
class _RecordedHttpHeaders implements HttpHeaders {
  _RecordedHttpHeaders(this.store);

  final Map<String, String> store;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      store[name.toLowerCase()] = value.toString();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}

class _RecordedWireRequest {
  _RecordedWireRequest(this.uri);

  final Uri uri;
  final Map<String, String> headers = {};
  final StringBuffer body = StringBuffer();
}

/// Response double: either one scripted byte payload or a live byte stream
/// (for the close-on-cancel contract). Extends Stream so `transform` works
/// for free.
class _ScriptedHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ScriptedHttpClientResponse(this.statusCode, this._bodyBytes, this._stream);

  @override
  final int statusCode;
  final List<int>? _bodyBytes;
  final Stream<List<int>>? _stream;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> element)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final source =
        _stream ??
        Stream<List<int>>.fromIterable([if (_bodyBytes != null) _bodyBytes]);
    return source.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}
