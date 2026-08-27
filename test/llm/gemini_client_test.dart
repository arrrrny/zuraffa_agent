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

    test('U20: stream() parses JSONL chunks into text parts and function calls, completing cleanly', () async {
      final transport = FakeLlmTransport(
        provider: 'gemini',
        script: [
          ScriptedResponse(
            statusCode: 200,
            lines: [
              'data: {"candidates":[{"content":{"parts":[{"text":"Hel"}],"role":"model"},"index":0}]}',
              '',
              'data: {"candidates":[{"content":{"parts":[{"text":"lo"}],"role":"model"},"index":0}]}',
              'data: {"candidates":[{"content":{"parts":[{"functionCall":{"name":"get_weather","args":{"city":"Paris"}}}],"role":"model"},"index":0,"finishReason":"STOP"}]}',
              'data: {"candidates":[{"finishReason":"STOP","index":0}],"usageMetadata":{"promptTokenCount":25,"candidatesTokenCount":9}}',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('hi')]))
          .toList();

      expect(
          chunks.where((c) => c.content != null).map((c) => c.content).toList(),
          ['Hel', 'lo']);
      final toolChunk = chunks.firstWhere((c) => c.toolCalls.isNotEmpty);
      expect(
        toolChunk.toolCalls.single,
        equals(const LlmToolCall(
          id: 'call_0',
          name: 'get_weather',
          arguments: {'city': 'Paris'},
        )),
      );
      final last = chunks.last;
      expect(last.isComplete, isTrue);
      expect(last.finishReason, 'stop');
      expect(last.usage,
          equals(const LlmUsage(inputTokens: 25, outputTokens: 9)));

      final sent =
          jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
      expect(sent.keys, contains('contents'));
      expect(transport.requests.single.uri.toString(),
          'https://api.test/v1beta/models/test-model:streamGenerateContent?alt=sse');
    });

    test('U21: a MALFORMED_FUNCTION_CALL finishReason surfaces in the response without throwing', () async {
      final transport = FakeLlmTransport(
        provider: 'gemini',
        script: [
          ScriptedResponse(
            statusCode: 200,
            lines: [
              'data: {"candidates":[{"content":{"parts":[{"text":"Let me try a tool call."}],"role":"model"},"index":0}]}',
              'data: {"candidates":[{"content":{"parts":[{"functionCall":{"name":"bad_","args":{"truncated":true}}}],"role":"model"},"index":0,"finishReason":"MALFORMED_FUNCTION_CALL"}]}',
            ],
          ),
        ],
      );
      final client = makeClient(transport);

      final chunks = await client
          .stream(LlmRequest(messages: [UserMessage.text('do it')]))
          .toList();

      // No throw: the malformed call is surfaced as a tool call chunk plus a
      // finishReason on the completing chunk.
      expect(chunks, isNotEmpty);
      final last = chunks.last;
      expect(last.isComplete, isTrue);
      expect(last.finishReason, 'malformed_function_call');
    });

    test('U22: a non-2xx response raises a typed error', () async {
      final transport = FakeLlmTransport(
        provider: 'gemini',
        script: [
          const ScriptedResponse(
            statusCode: 403,
            body: '{"error":{"code":403,"message":"API key not valid"}}',
          ),
        ],
      );
      final client = makeClient(transport);

      await expectLater(
        client.generate(LlmRequest(messages: [UserMessage.text('hi')])),
        throwsA(isA<LlmHttpException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.provider, 'provider', 'gemini')),
      );
      expect(transport.requests, hasLength(1));
      expect(clock.sleeps, isEmpty);
    });
  });
}
