// Tests for lib/src/llm/gemini_client.dart — Spec 007 US3.
// Behaviors U19..U22 — see specs/007-llm-provider-clients/tdd/test-list.md.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/gemini_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

const _generateBody = '''
{
  "candidates": [
    {
      "content": {
        "role": "model",
        "parts": [
          {"text": "It is sunny in Paris."},
          {"functionCall": {"name": "get_weather", "args": {"city": "Paris"}}}
        ]
      },
      "finishReason": "STOP",
      "index": 0
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 25,
    "candidatesTokenCount": 42,
    "cachedContentTokenCount": 8,
    "thoughtsTokenCount": 7
  }
}
''';

void main() {
  late FakeLlmClock clock;

  setUp(() {
    clock = FakeLlmClock();
  });

  GeminiClient makeClient(FakeLlmTransport transport,
          {RetryConfig? retryConfig}) =>
      GeminiClient(
        transport: transport,
        baseUrl: 'https://api.test/v1beta',
        model: 'test-model',
        apiKey: 'test-key',
        retryConfig: retryConfig ?? const RetryConfig(maxAttempts: 1),
        clock: clock,
        jitter: (_) => 0,
      );

  group('GeminiClient (U19..U22)', () {
    test('U19: generate() builds the generateContent body (contents/parts, tools) and parses text + usageMetadata', () async {
      final transport = FakeLlmTransport(
        provider: 'gemini',
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
            parameters: {'type': 'object'},
          ),
        ],
        temperature: 0.2,
        maxTokens: 512,
      ));

      // Request mapping.
      final sent = transport.requests.single;
      expect(sent.uri.toString(),
          'https://api.test/v1beta/models/test-model:generateContent');
      expect(sent.headers['x-goog-api-key'], 'test-key');
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['systemInstruction'],
          {'parts': [{'text': 'You are helpful.'}]});

      final contents = body['contents'] as List;
      expect(contents[0]['role'], 'user');
      expect(contents[0]['parts'], [
        {'text': 'Weather in Paris?'},
        {
          'inlineData': {'mimeType': 'image/png', 'data': 'AAAA'},
        },
      ]);
      expect(contents[1]['role'], 'model');
      expect(contents[1]['parts'], [
        {
          'functionCall': {'name': 'get_weather', 'args': {'city': 'Paris'}},
        },
      ]);
      expect(contents[2]['role'], 'user');
      expect(contents[2]['parts'], [
        {
          'functionResponse': {
            'name': 'get_weather',
            'response': {'result': 'sunny, 24C'},
          },
        },
      ]);

      final tools = body['tools'] as List;
      expect(tools.single['functionDeclarations'].single['name'],
          'get_weather');

      expect(body['generationConfig'],
          {'temperature': 0.2, 'maxOutputTokens': 512});

      // Response parsing.
      expect(response.content, 'It is sunny in Paris.');
      expect(
        response.toolCalls.single,
        equals(const LlmToolCall(
          id: 'call_0',
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
      expect(response.finishReason, 'stop');
    });
  });
}
