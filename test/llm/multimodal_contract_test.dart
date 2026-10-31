// Issue #138 — multimodal request contract tests.
//
// One parameterized loop over the three providers, in the shape of the
// shared suite harness in test/llm/llm_client_contract_test.dart: sends an
// ImageBlock through each provider client, replays the
// generate_multimodal.json fixture as the response, and asserts the
// recorded request body carries the base64 payload in the provider-specific
// wire shape:
//   openai    → {"type":"image_url","image_url":{"url":"data:<mime>;base64,<data>"}}
//   anthropic → {"type":"image","source":{"type":"base64","media_type":<mime>,"data":<data>}}
//   gemini    → {"inlineData":{"mimeType":<mime>,"data":<data>}}
//
// The arrange (transport → client → generate → recorded body) and the
// provider-independent assertions (two content parts, text prompt first,
// base64 payload present in the raw body, fixture reply) live in the loop;
// only the per-provider body navigation and image-part shape assertions
// differ, and those are parameterized below.

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

/// One provider's multimodal case: client construction plus the
/// provider-specific request-body navigation (user message's content parts,
/// role asserted) and image-part shape assertions. Everything else — the
/// arrange, the shared assertions, the fixture replay — is the loop in
/// [main], so a change to the multimodal setup needs one edit, not three.
class MultimodalCase {
  const MultimodalCase({
    required this.provider,
    required this.makeClient,
    required this.userContentParts,
    required this.expectImagePart,
  });

  final String provider;
  final LlmClient Function(FakeLlmTransport transport) makeClient;

  /// Extracts the user message's content parts from the recorded request
  /// body, asserting the message's role (openai/anthropic:
  /// `messages.last.content`; gemini: `contents.last.parts`).
  final List<Map<String, dynamic>> Function(Map<String, dynamic> body)
  userContentParts;

  /// Asserts the image part's provider-specific wire shape (`parts[1]`).
  final void Function(Map<String, dynamic> imagePart) expectImagePart;
}

final multimodalCases = [
  MultimodalCase(
    provider: 'openai',
    makeClient: (transport) => OpenAiCompatibleClient(
      transport: transport,
      baseUrl: 'https://api.test/v1',
      model: 'test-model',
      apiKey: 'test-key',
      clock: FakeLlmClock(),
    ),
    userContentParts: (body) {
      final message = (body['messages'] as List).last as Map<String, dynamic>;
      expect(message['role'], 'user');
      final parts = (message['content'] as List).cast<Map<String, dynamic>>();
      expect(parts.first['type'], 'text');
      return parts;
    },
    expectImagePart: (part) {
      expect(part['type'], 'image_url');
      expect(part['image_url']['url'], 'data:image/png;base64,$pngBase64');
    },
  ),
  MultimodalCase(
    provider: 'anthropic',
    makeClient: (transport) => AnthropicClient(
      transport: transport,
      baseUrl: 'https://api.test/v1',
      model: 'test-model',
      apiKey: 'test-key',
      clock: FakeLlmClock(),
    ),
    userContentParts: (body) {
      final message = (body['messages'] as List).last as Map<String, dynamic>;
      expect(message['role'], 'user');
      final parts = (message['content'] as List).cast<Map<String, dynamic>>();
      expect(parts.first['type'], 'text');
      return parts;
    },
    expectImagePart: (part) {
      expect(part['type'], 'image');
      expect(part['source']['type'], 'base64');
      expect(part['source']['media_type'], 'image/png');
      expect(part['source']['data'], pngBase64);
    },
  ),
  MultimodalCase(
    provider: 'gemini',
    makeClient: (transport) => GeminiClient(
      transport: transport,
      baseUrl: 'https://api.test/v1beta',
      model: 'test-model',
      apiKey: 'test-key',
      clock: FakeLlmClock(),
    ),
    userContentParts: (body) {
      final content = (body['contents'] as List).last as Map<String, dynamic>;
      expect(content['role'], 'user');
      return (content['parts'] as List).cast<Map<String, dynamic>>();
    },
    expectImagePart: (part) {
      expect(part['inlineData']['mimeType'], 'image/png');
      expect(part['inlineData']['data'], pngBase64);
    },
  ),
];

void main() {
  group(
    'multimodal request contract — ImageBlock serialization (issue #138)',
    () {
      for (final c in multimodalCases) {
        test(
          '${c.provider}: image part in the provider-native wire shape',
          () async {
            final transport = FakeLlmTransport(
              provider: c.provider,
              script: [
                ScriptedResponse(
                  statusCode: 200,
                  body: await _fixture(c.provider),
                ),
              ],
            );
            final client = c.makeClient(transport);

            final response = await client.generate(multimodalRequest());

            final body =
                jsonDecode(transport.requests.single.body)
                    as Map<String, dynamic>;
            // Shared arrange assertions: the user message carries exactly
            // the text prompt and the image, in that order.
            final parts = c.userContentParts(body);
            expect(parts, hasLength(2));
            expect(parts.first['text'], imagePrompt);
            c.expectImagePart(parts[1]);
            // The raw request body itself carries the base64 payload.
            expect(transport.requests.single.body, contains(pngBase64));
            expect(response.content, multimodalReply);
          },
        );
      }
    },
  );
}
