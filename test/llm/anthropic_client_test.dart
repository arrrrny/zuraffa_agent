// Tests for lib/src/llm/anthropic_client.dart — Spec 007 US2.
// Behaviors U15..U18 — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/llm/anthropic_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

const _generateBody = '''
{
  "id": "msg_1",
  "content": [
    {"type": "thinking", "thinking": "Let me check the weather."},
    {"type": "text", "text": "It is sunny in Paris."},
    {"type": "tool_use", "id": "toolu_1", "name": "get_weather", "input": {"city": "Paris"}}
  ],
  "stop_reason": "end_turn",
  "usage": {"input_tokens": 25, "output_tokens": 42, "cache_read_input_tokens": 8}
}
''';

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  AnthropicClient makeClient(FakeLlmTransport transport,
          {RetryConfig? retryConfig}) =>
      AnthropicClient(
        transport: transport,
        baseUrl: 'https://api.test/v1',
        model: 'test-model',
        apiKey: 'test-key',
        retryConfig: retryConfig ?? const RetryConfig(maxAttempts: 1),
        clock: clock,
        jitter: (_) => 0,
      );

  group('AnthropicClient (U15..U18)', () {
    test('U15: generate() builds the Messages body (system, messages, tools) and parses content blocks incl. thinking', () async {
      final transport = FakeLlmTransport(
        provider: 'anthropic',
        script: [
          const ScriptedResponse(
            statusCode: 200,
            headers: {'content-type': 'application/json'},
            body: _generateBody,
          ),
        ],
      );
      final client = makeClient(transport);

      final response = await client.generate(LlmRequest(
        systemPrompt: 'You are helpful.',
        messages: [
          UserMessage(content: [
            const TextBlock('Weather in Paris?'),
            const ImageBlock(data: 'AAAA', mimeType: 'image/png'),
            const DocumentBlock(data: 'REhBUg==', mimeType: 'application/pdf'),
          ]),
          AssistantMessage(content: [
            const ToolCallBlock(
              id: 'toolu_1',
              name: 'get_weather',
              arguments: {'city': 'Paris'},
            ),
          ]),
          ToolResultMessage(
            toolCallId: 'toolu_1',
            toolName: 'get_weather',
            content: 'sunny, 24C',
          ),
        ],
        tools: const [
          LlmToolSpec(
            name: 'get_weather',
            description: 'Get current weather',
            parameters: {'type': 'object'},
          ),
        ],
        maxTokens: 1024,
      ));

      // Request mapping.
      final sent = transport.requests.single;
      expect(sent.uri.toString(), 'https://api.test/v1/messages');
      expect(sent.headers['x-api-key'], 'test-key');
      expect(
          sent.headers['anthropic-version'], AnthropicClient.apiVersion);
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['max_tokens'], 1024);
      expect(body['system'], 'You are helpful.');

      final messages = body['messages'] as List;
      expect(messages[0]['role'], 'user');
      expect(messages[0]['content'], [
        {'type': 'text', 'text': 'Weather in Paris?'},
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': 'image/png', 'data': 'AAAA'},
        },
        {
          'type': 'document',
          'source': {
            'type': 'base64',
            'media_type': 'application/pdf',
            'data': 'REhBUg==',
          },
        },
      ]);
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], [
        {
          'type': 'tool_use',
          'id': 'toolu_1',
          'name': 'get_weather',
          'input': {'city': 'Paris'},
        },
      ]);
      expect(messages[2]['role'], 'user');
      expect(messages[2]['content'], [
        {
          'type': 'tool_result',
          'tool_use_id': 'toolu_1',
          'content': 'sunny, 24C',
        },
      ]);

      final tools = body['tools'] as List;
      expect(tools.single['name'], 'get_weather');
      expect(tools.single['input_schema'], {'type': 'object'});

      // Response parsing.
      expect(response.content, 'It is sunny in Paris.');
      expect(response.thinking, 'Let me check the weather.');
      expect(
        response.toolCalls.single,
        equals(const LlmToolCall(
          id: 'toolu_1',
          name: 'get_weather',
          arguments: {'city': 'Paris'},
        )),
      );
      expect(
        response.usage,
        equals(const LlmUsage(
          inputTokens: 25,
          outputTokens: 42,
          cachedTokens: 8,
        )),
      );
      expect(response.finishReason, 'stop');
    });

    test('U16: stream() parses message_start usage, thinking/text deltas, and message_delta stop reason + output usage', () async {
      final transport = FakeLlmTransport(
        provider: 'anthropic',
        script: [
          ScriptedResponse(
            statusCode: 200,
            lines: [
              'event: message_start',
              'data: {"type":"message_start","message":{"usage":{"input_tokens":25,"output_tokens":1}}}',
              '',
              'event: content_block_start',
              'data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}',
              '',
              'event: content_block_delta',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Hmm, weather."}}',
              '',
              'event: content_block_delta',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hel"}}',
              '',
              'event: content_block_delta',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo"}}',
              '',
              'event: message_delta',
              'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":42}}',
              '',
              'event: message_stop',
              'data: {"type":"message_stop"}',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks =
          await client.stream(LlmRequest(messages: [UserMessage.text('hi')])).toList();

      final thinking = chunks.where((c) => c.thinking != null).toList();
      expect(thinking, hasLength(1));
      expect(thinking.single.thinking, 'Hmm, weather.');

      final text = chunks.where((c) => c.content != null).toList();
      expect(text.map((c) => c.content).toList(), ['Hel', 'lo']);

      final last = chunks.last;
      expect(last.isComplete, isTrue);
      expect(last.finishReason, 'stop');
      expect(last.usage,
          equals(const LlmUsage(inputTokens: 25, outputTokens: 42)));
    });

    test('U17: tool_use blocks assemble from input_json_delta partial_json fragments', () async {
      final transport = FakeLlmTransport(
        provider: 'anthropic',
        script: [
          ScriptedResponse(
            statusCode: 200,
            lines: [
              'data: {"type":"message_start","message":{"usage":{"input_tokens":10,"output_tokens":1}}}',
              'data: {"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"toolu_2","name":"get_weather","input":{}}}',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{\\"ci"}}',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"ty\\": \\"Par"}}',
              'data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"is\\"}"}}',
              'data: {"type":"content_block_stop","index":0}',
              'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":9}}',
              'data: {"type":"message_stop"}',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('weather?')]))
          .toList();

      final toolChunk = chunks.firstWhere((c) => c.toolCalls.isNotEmpty);
      expect(
        toolChunk.toolCalls.single,
        equals(const LlmToolCall(
          id: 'toolu_2',
          name: 'get_weather',
          arguments: {'city': 'Paris'},
        )),
      );
      expect(chunks.last.isComplete, isTrue);
      expect(chunks.last.finishReason, 'tool_calls');
    });

    test('U18: a non-2xx response raises a typed error', () async {
      final transport = FakeLlmTransport(
        provider: 'anthropic',
        script: [
          const ScriptedResponse(
            statusCode: 400,
            body: '{"type":"error","error":{"type":"invalid_request_error"}}',
          ),
        ],
      );
      final client = makeClient(transport);

      await expectLater(
        client.generate(LlmRequest(messages: [UserMessage.text('hi')])),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.provider, 'provider', 'anthropic')),
      );
      // Non-retryable 4xx: exactly one request, zero backoffs.
      expect(transport.requests, hasLength(1));
      expect(clock.sleeps, isEmpty);
    });
  });
}
