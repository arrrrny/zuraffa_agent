// Tests for lib/src/llm/openai_compatible_client.dart — Spec 007 US1 (MVP).
// Behaviors U11..U14 — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_transport.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

const _generateBody = '''
{
  "id": "chatcmpl-1",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "It is sunny in Paris.",
        "tool_calls": [
          {
            "id": "call_1",
            "type": "function",
            "function": {
              "name": "get_weather",
              "arguments": "{\\"city\\":\\"Paris\\"}"
            }
          }
        ]
      },
      "finish_reason": "tool_calls"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 42,
    "prompt_tokens_details": {"cached_tokens": 8},
    "completion_tokens_details": {"reasoning_tokens": 7}
  }
}
''';

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  OpenAiCompatibleClient makeClient(
    LlmTransport transport, {
    RetryConfig? retryConfig,
  }) => OpenAiCompatibleClient(
    transport: transport,
    baseUrl: 'https://api.test/v1',
    model: 'test-model',
    apiKey: 'test-key',
    retryConfig: retryConfig ?? const RetryConfig(maxAttempts: 1),
    clock: clock,
    jitter: (_) => 0,
  );

  group('OpenAiCompatibleClient (U11..U14)', () {
    test(
      'U11: generate() builds the chat/completions body (model, multimodal messages, tools) and parses content, finishReason, usage',
      () async {
        final transport = FakeLlmTransport(
          provider: 'openai',
          script: [
            const ScriptedResponse(
              statusCode: 200,
              headers: {'content-type': 'application/json'},
              body: _generateBody,
            ),
          ],
        );
        final client = makeClient(transport);

        final response = await client.generate(
          LlmRequest(
            systemPrompt: 'You are helpful.',
            messages: [
              UserMessage(
                content: [
                  const TextBlock('What is the weather in Paris?'),
                  const ImageBlock(data: 'AAAA', mimeType: 'image/png'),
                ],
              ),
              AssistantMessage(
                content: [
                  const ToolCallBlock(
                    id: 'call_1',
                    name: 'get_weather',
                    arguments: {'city': 'Paris'},
                  ),
                ],
              ),
              ToolResultMessage(
                toolCallId: 'call_1',
                toolName: 'get_weather',
                content: 'sunny, 24C',
              ),
            ],
            tools: const [
              LlmToolSpec(
                name: 'get_weather',
                description: 'Get current weather',
                parameters: {
                  'type': 'object',
                  'properties': {
                    'city': {'type': 'string'},
                  },
                },
              ),
            ],
          ),
        );

        // Request mapping.
        expect(transport.requests, hasLength(1));
        final sent = transport.requests.single;
        expect(sent.uri.toString(), 'https://api.test/v1/chat/completions');
        expect(sent.headers['authorization'], 'Bearer test-key');
        final body = jsonDecode(sent.body) as Map<String, dynamic>;
        expect(body['model'], 'test-model');
        expect(body['stream'], isNull);

        final messages = body['messages'] as List;
        expect(messages[0], {'role': 'system', 'content': 'You are helpful.'});
        final userTurn = messages[1] as Map<String, dynamic>;
        expect(userTurn['role'], 'user');
        expect(userTurn['content'], [
          {'type': 'text', 'text': 'What is the weather in Paris?'},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/png;base64,AAAA'},
          },
        ]);
        final assistantTurn = messages[2] as Map<String, dynamic>;
        expect(assistantTurn['role'], 'assistant');
        expect(assistantTurn['tool_calls'], [
          {
            'id': 'call_1',
            'type': 'function',
            'function': {
              'name': 'get_weather',
              'arguments': '{"city":"Paris"}',
            },
          },
        ]);
        expect(messages[3], {
          'role': 'tool',
          'tool_call_id': 'call_1',
          'content': 'sunny, 24C',
        });

        final tools = body['tools'] as List;
        final tool = tools.single as Map<String, dynamic>;
        final function = tool['function'] as Map<String, dynamic>;
        expect(function['name'], 'get_weather');
        final parameters = function['parameters'] as Map<String, dynamic>;
        final properties = parameters['properties'] as Map<String, dynamic>;
        final city = properties['city'] as Map<String, dynamic>;
        expect(city['type'], 'string');

        // Response parsing.
        expect(response.content, 'It is sunny in Paris.');
        expect(response.finishReason, 'tool_calls');
        expect(
          response.toolCalls.single,
          equals(
            const LlmToolCall(
              id: 'call_1',
              name: 'get_weather',
              arguments: {'city': 'Paris'},
            ),
          ),
        );
        expect(
          response.usage,
          equals(
            const LlmUsage(
              inputTokens: 25,
              outputTokens: 42,
              cachedTokens: 8,
              thoughtTokens: 7,
            ),
          ),
        );
      },
    );

    test('U11a: responseFormat is emitted verbatim as response_format, omitted '
        'when null', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 200,
            headers: {'content-type': 'application/json'},
            body: _generateBody,
          ),
          const ScriptedResponse(
            statusCode: 200,
            headers: {'content-type': 'application/json'},
            body: _generateBody,
          ),
        ],
      );
      final client = makeClient(transport);

      await client.generate(
        LlmRequest(
          messages: [UserMessage.text('hi')],
          responseFormat: {'type': 'json_object'},
        ),
      );
      await client.generate(LlmRequest(messages: [UserMessage.text('hi')]));

      final bodies = transport.requests
          .map((r) => jsonDecode(r.body) as Map<String, dynamic>)
          .toList();
      expect(bodies[0]['response_format'], {'type': 'json_object'});
      expect(bodies[1].containsKey('response_format'), isFalse);
    });

    test(
      'U12: stream() parses SSE data lines to content deltas; the final chunk '
      'carries usage; [DONE] yields isComplete',
      () async {
        final transport = FakeLlmTransport(
          provider: 'openai',
          script: [
            const ScriptedResponse(
              statusCode: 200,
              headers: {'content-type': 'text/event-stream'},
              lines: [
                '',
                'data: {"id":"1","choices":[{"index":0,"delta":{"role":"assista'
                    'nt","content":"Hel"}}]}',
                ': keep-alive comment line',
                'data: {"id":"1","choices":[{"index":0,"delta":{"content":"lo"}'
                    '}]}',
                'data: {"id":"1","choices":[{"index":0,"delta":{},"finish_reaso'
                    'n":"stop"}]}',
                'data: {"id":"1","choices":[],"usage":{"prompt_tokens":25,"comp'
                    'letion_tokens":9}}',
                'data: [DONE]',
              ],
            ),
          ],
        );
        final client = makeClient(transport);

        final chunks = await client
            .stream(LlmRequest(messages: [UserMessage.text('hi')]))
            .toList();

        expect(chunks, hasLength(3));
        expect(chunks[0].content, 'Hel');
        expect(chunks[0].isComplete, isFalse);
        expect(chunks[1].content, 'lo');
        expect(chunks[1].isComplete, isFalse);
        expect(chunks[2].isComplete, isTrue);
        expect(
          chunks[2].usage,
          equals(const LlmUsage(inputTokens: 25, outputTokens: 9)),
        );
        expect(chunks[2].finishReason, 'stop');

        // The request asked for a streamed completion with usage accounting.
        final sent =
            jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
        expect(sent['stream'], isTrue);
        expect(sent['stream_options'], {'include_usage': true});
      },
    );

    test('reasoning deltas surface as thinking chunks (issue #123 review: '
        'the shared SSE parser gives the provider-client path the same '
        'reasoning mapping the legacy transport path already had)', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 200,
            lines: [
              // OpenRouter-style `reasoning` and DeepSeek-style
              // `reasoning_content` both carry thinking text.
              'data: {"id":"1","choices":[{"index":0,"delta":{"reasoning":"step'
                  ' "}}]}',
              'data: {"id":"1","choices":[{"index":0,"delta":{"reasoning_conten'
                  't":"one"}}]}',
              'data: {"id":"1","choices":[{"index":0,"delta":{"content":"done"}'
                  '}]}',
              'data: [DONE]',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('think')]))
          .toList();

      expect(chunks[0].thinking, 'step ');
      expect(chunks[1].thinking, 'one');
      expect(chunks[2].content, 'done');
      expect(chunks.last.isComplete, isTrue);
    });

    test('U13: tool-call fragments assemble by index across chunks; malformed '
        'arguments default to an empty map', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: [
          const ScriptedResponse(
            statusCode: 200,
            lines: [
              // Two interleaved tool streams (index 0 and 1) + one malformed
              // argument payload on index 1.
              'data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call_a","type":"function","function":{"name":"get_weather","arguments":"{\\"ci"}}]}}]}',
              'data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":1'
                  ',"id":"call_b","type":"function","function":{"name":"get_t'
                  'ime","arguments":"{bad json"}}]}}]}',
              'data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"arguments":"ty\\":\\"Paris\\"}"}}]}}]}',
              'data: {"choices":[{"index":0,"delta":{},"finish_reason":"tool_'
                  'calls"}]}',
              'data: {"choices":[],"usage":{"prompt_tokens":10,"completion_to'
                  'kens":5}}',
              'data: [DONE]',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('call tools')]))
          .toList();

      final toolChunk = chunks.firstWhere((c) => c.toolCalls.isNotEmpty);
      expect(toolChunk.toolCalls, hasLength(2));
      expect(
        toolChunk.toolCalls[0],
        equals(
          const LlmToolCall(
            id: 'call_a',
            name: 'get_weather',
            arguments: {'city': 'Paris'},
          ),
        ),
      );
      // Malformed argument JSON tolerates gracefully (AC-2): empty map.
      expect(
        toolChunk.toolCalls[1],
        equals(
          const LlmToolCall(id: 'call_b', name: 'get_time', arguments: {}),
        ),
      );
      expect(chunks.last.isComplete, isTrue);
    });

    test('U14: a non-2xx response raises LlmHttpException with statusCode and '
        'body', () async {
      final transport = FakeLlmTransport(
        provider: 'openai',
        script: List.filled(
          3,
          const ScriptedResponse(
            statusCode: 500,
            body: '{"error":{"message":"upstream boom"}}',
          ),
        ),
      );
      final client = makeClient(
        transport,
        retryConfig: const RetryConfig(maxAttempts: 3, baseDelayMs: 10),
      );

      await expectLater(
        client.generate(LlmRequest(messages: [UserMessage.text('hi')])),
        throwsA(
          isA<LlmHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.body,
                'body',
                '{"error":{"message":"upstream boom"}}',
              )
              .having((e) => e.provider, 'provider', 'openai'),
        ),
      );
      expect(transport.requests, hasLength(3));
    });

    test('U163: cancelling stream() mid-stream completes and detaches the '
        'lines (issue #163)', () async {
      // Full three-layer chain (client async* -> parser async* ->
      // await-for): the gateway keeps emitting, so the cancel lands while
      // the innermost generator waits at `await for`. On the unfixed tree
      // `sub.cancel()` never completed (issue #163).
      final controller = StreamController<String>();
      final transport = _LiveLinesTransport(controller.stream);
      final client = makeClient(transport);

      final sub = client
          .stream(LlmRequest(messages: [UserMessage.text('hi')]))
          .listen((_) {});
      await transport.opened.future;
      await pumpEventQueue();

      for (var i = 0; i < 3; i++) {
        controller.add(
          jsonEncode({
            'choices': [
              {
                'index': 0,
                'delta': {'content': 'c$i'},
              },
            ],
          }),
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
      expect(transport.linesCancelled, greaterThan(0));
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}

/// Transport double serving one LIVE line stream (issue #163): lets a test
/// keep the gateway "still emitting" while it cancels `stream()`, and
/// records whether the cancel reached the lines subscription (the fix's
/// onCancel must cancel the inner subscription — a direct subscription
/// cancel completes, an async* one never did).
class _LiveLinesTransport implements LlmTransport {
  _LiveLinesTransport(this._lines);

  final Stream<String> _lines;
  final opened = Completer<void>();
  int linesCancelled = 0;

  @override
  Future<LlmHttpResponse> send(LlmHttpRequest request) async =>
      throw UnimplementedError('stream-only fake');

  @override
  Future<LlmStreamResponse> openStream(LlmHttpRequest request) async {
    if (!opened.isCompleted) opened.complete();
    return LlmStreamResponse(statusCode: 200, lines: _observed(_lines));
  }

  Stream<String> _observed(Stream<String> source) {
    late StreamController<String> controller;
    StreamSubscription<String>? inner;
    controller = StreamController<String>(
      onListen: () {
        inner = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onPause: () => inner?.pause(),
      onResume: () => inner?.resume(),
      onCancel: () async {
        linesCancelled++;
        await inner?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> close() async {}
}
