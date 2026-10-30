// Issue #138 — multimodal request contract tests.
//
// Sends an ImageBlock through each provider client, replays the
// generate_multimodal.json fixture as the response, and asserts the recorded
// request body carries the base64 payload in the provider-specific wire
// shape:
//   openai    → {"type":"image_url","image_url":{"url":"data:<mime>;base64,<data>"}}
//   anthropic → {"type":"image","source":{"type":"base64","media_type":<mime>,"data":<data>}}
//   gemini    → {"inlineData":{"mimeType":<mime>,"data":<data>}}

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/llm/anthropic_client.dart';
import 'package:zuraffa_agent/src/llm/gemini_client.dart';
import 'package:zuraffa_agent/src/llm/llm_client.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';
import 'package:zuraffa_agent/src/types.dart';

import 'fake_llm_clock.dart';
import 'fake_llm_transport.dart';

/// Canonical 1x1 transparent PNG, base64-encoded.
const pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const imagePrompt = 'Describe this image.';
const multimodalReply = 'It looks like a tiny red square.';

LlmRequest multimodalRequest() => LlmRequest(
  messages: [
    UserMessage(
      content: [
        const TextBlock(imagePrompt),
        const ImageBlock(data: pngBase64, mimeType: 'image/png'),
      ],
    ),
  ],
);

Future<String> _fixture(String provider) =>
    File('test/fixtures/llm/$provider/generate_multimodal.json').readAsString();

void main() {
  group(
    'multimodal request contract — ImageBlock serialization (issue #138)',
    () {
      test('openai: image_url data URI inside the content parts', () async {
        final transport = FakeLlmTransport(
          provider: 'openai',
          script: [
            ScriptedResponse(statusCode: 200, body: await _fixture('openai')),
          ],
        );
        final client = OpenAiCompatibleClient(
          transport: transport,
          baseUrl: 'https://api.test/v1',
          model: 'test-model',
          apiKey: 'test-key',
          clock: FakeLlmClock(),
        );

        final response = await client.generate(multimodalRequest());

        final body =
            jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
        final messages = (body['messages'] as List)
            .cast<Map<String, dynamic>>();
        final userMessage = messages.last;
        expect(userMessage['role'], 'user');
        final parts = (userMessage['content'] as List)
            .cast<Map<String, dynamic>>();
        expect(parts, hasLength(2));
        expect(parts.first['type'], 'text');
        expect(parts.first['text'], imagePrompt);
        expect(parts[1]['type'], 'image_url');
        expect(
          parts[1]['image_url']['url'],
          'data:image/png;base64,$pngBase64',
        );
        // The raw request body itself carries the base64 payload.
        expect(transport.requests.single.body, contains(pngBase64));
        expect(response.content, multimodalReply);
      });

      test('anthropic: base64 source block with media_type', () async {
        final transport = FakeLlmTransport(
          provider: 'anthropic',
          script: [
            ScriptedResponse(
              statusCode: 200,
              body: await _fixture('anthropic'),
            ),
          ],
        );
        final client = AnthropicClient(
          transport: transport,
          baseUrl: 'https://api.test/v1',
          model: 'test-model',
          apiKey: 'test-key',
          clock: FakeLlmClock(),
        );

        final response = await client.generate(multimodalRequest());

        final body =
            jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
        final messages = (body['messages'] as List)
            .cast<Map<String, dynamic>>();
        final userMessage = messages.last;
        expect(userMessage['role'], 'user');
        final blocks = (userMessage['content'] as List)
            .cast<Map<String, dynamic>>();
        expect(blocks, hasLength(2));
        expect(blocks.first['type'], 'text');
        expect(blocks.first['text'], imagePrompt);
        expect(blocks[1]['type'], 'image');
        expect(blocks[1]['source']['type'], 'base64');
        expect(blocks[1]['source']['media_type'], 'image/png');
        expect(blocks[1]['source']['data'], pngBase64);
        expect(transport.requests.single.body, contains(pngBase64));
        expect(response.content, multimodalReply);
      });

      test('gemini: inlineData part with mimeType', () async {
        final transport = FakeLlmTransport(
          provider: 'gemini',
          script: [
            ScriptedResponse(statusCode: 200, body: await _fixture('gemini')),
          ],
        );
        final client = GeminiClient(
          transport: transport,
          baseUrl: 'https://api.test/v1beta',
          model: 'test-model',
          apiKey: 'test-key',
          clock: FakeLlmClock(),
        );

        final response = await client.generate(multimodalRequest());

        final body =
            jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
        final contents = (body['contents'] as List)
            .cast<Map<String, dynamic>>();
        final userContent = contents.last;
        expect(userContent['role'], 'user');
        final parts = (userContent['parts'] as List)
            .cast<Map<String, dynamic>>();
        expect(parts, hasLength(2));
        expect(parts.first['text'], imagePrompt);
        expect(parts[1]['inlineData']['mimeType'], 'image/png');
        expect(parts[1]['inlineData']['data'], pngBase64);
        expect(transport.requests.single.body, contains(pngBase64));
        expect(response.content, multimodalReply);
      });
    },
  );
}
