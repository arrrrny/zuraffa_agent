// Tests for lib/src/llm/openai_compatible_client.dart — Spec 007 US1 (MVP).
// Behaviors U11..U14 — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
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

  OpenAiCompatibleClient makeClient(FakeLlmTransport transport,
          {RetryConfig? retryConfig}) =>
      OpenAiCompatibleClient(
        transport: transport,
        baseUrl: 'https://api.test/v1',
        model: 'test-model',
        apiKey: 'test-key',
        retryConfig: retryConfig ?? const RetryConfig(maxAttempts: 1),
        clock: clock,
        jitter: (_) => 0,
      );

  group('OpenAiCompatibleClient (U11..U14)', () {
    test('U11: generate() builds the chat/completions body (model, multimodal messages, tools) and parses content, finishReason, usage', () async {
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

      final response = await client.generate(LlmRequest(
        systemPrompt: 'You are helpful.',
        messages: [
          UserMessage(content: [
            const TextBlock('What is the weather in Paris?'),
            const ImageBlock(data: 'AAAA', mimeType: 'image/png'),
          ]),
          AssistantMessage(content: [
            const ToolCallBlock(
              id: 'call_1',
              name: 'get_weather',
              arguments: {'city': 'Paris'},
            ),
          ]),
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
      ));

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
      expect(messages[1]['role'], 'user');
      expect(messages[1]['content'], [
        {'type': 'text', 'text': 'What is the weather in Paris?'},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,AAAA'},
        },
      ]);
      expect(messages[2]['role'], 'assistant');
      expect(messages[2]['tool_calls'], [
        {
          'id': 'call_1',
          'type': 'function',
          'function': {'name': 'get_weather', 'arguments': '{"city":"Paris"}'},
        },
      ]);
      expect(messages[3],
          {'role': 'tool', 'tool_call_id': 'call_1', 'content': 'sunny, 24C'});

      final tools = body['tools'] as List;
      expect(tools.single['function']['name'], 'get_weather');
      expect(tools.single['function']['parameters']['properties']
          ['city']['type'], 'string');

      // Response parsing.
      expect(response.content, 'It is sunny in Paris.');
      expect(response.finishReason, 'tool_calls');
      expect(
        response.toolCalls.single,
        equals(const LlmToolCall(
          id: 'call_1',
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
          thoughtTokens: 7,
        )),
      );
    });
  });
}
