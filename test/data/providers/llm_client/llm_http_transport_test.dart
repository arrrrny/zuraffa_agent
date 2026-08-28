// Unit tests for LlmHttpTransport's pure request-build and response-parse
// helpers. These cover request construction and response parsing WITHOUT any
// network access (FR-009), so they run in CI without the proxy.

import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_http_transport.dart';

// Inert HttpClient double: postUrl throws (no real network) and close is a
// no-op, while the findProxy setter is observed so we can prove the
// direct-connect path does not install a proxy resolver.
class MockHttpClient extends Mock implements HttpClient {
  // Records whether the proxy resolver (HttpClient.findProxy) was assigned.
  bool findProxyAssigned = false;

  @override
  set findProxy(String Function(Uri)? f) {
    findProxyAssigned = true;
  }
}

void main() {
  group('arrarrny/zuraffa_agent#5 - request build', () {
    test('builds an OpenAI-compatible body with messages and model', () {
      final body = buildChatCompletionRequest(
        model: 'tencent/hy3:free',
        messages: const [
          ChatMessage(role: 'system', content: 'be terse'),
          ChatMessage(role: 'user', content: 'hi'),
        ],
      );
      expect(body['model'], 'tencent/hy3:free');
      expect(body['stream'], isFalse);
      expect(body['messages'], hasLength(2));
      expect(body['messages'][0], {'role': 'system', 'content': 'be terse'});
      expect(body['messages'][1], {'role': 'user', 'content': 'hi'});
    });

    test('honors the stream flag', () {
      final body = buildChatCompletionRequest(
        model: 'm', messages: const [ChatMessage(role: 'user', content: 'x')], stream: true,
      );
      expect(body['stream'], isTrue);
    });
  });

  group('arrarrny/zuraffa_agent#5 - response parse', () {
    final validJson = {
      'id': 'gen-1',
      'object': 'chat.completion',
      'model': 'tencent/hy3',
      'choices': [
        {
          'index': 0,
          'finish_reason': 'stop',
          'message': {
            'role': 'assistant',
            'content': 'PONG',
            'reasoning': 'the user asked for a single word',
          },
        }
      ],
      'usage': {'prompt_tokens': 20, 'completion_tokens': 97, 'total_tokens': 117},
    };

    test('parses content, reasoning, finish reason and usage', () {
      final completion = parseChatCompletionResponse(validJson);
      expect(completion.content, 'PONG');
      expect(completion.reasoning, 'the user asked for a single word');
      expect(completion.finishReason, 'stop');
      expect(completion.usage.promptTokens, 20);
      expect(completion.usage.completionTokens, 97);
      expect(completion.usage.totalTokens, 117);
    });

    test('reassembles reasoning from reasoning_details when reasoning is absent', () {
      final json = Map<String, dynamic>.from(validJson);
      (json['choices'][0] as Map)['message'] = {
        'role': 'assistant',
        'content': 'PONG',
        'reasoning_details': [
          {'type': 'reasoning.text', 'text': 'step one'},
          {'type': 'reasoning.text', 'text': 'step two'},
        ],
      };
      final completion = parseChatCompletionResponse(json);
      expect(completion.content, 'PONG');
      expect(completion.reasoning, 'step one\nstep two');
    });

    test('throws when choices are missing', () {
      final json = Map<String, dynamic>.from(validJson)..remove('choices');
      expect(() => parseChatCompletionResponse(json), throwsA(isA<LlmTransportException>()));
    });

    test('throws when content is empty', () {
      final json = Map<String, dynamic>.from(validJson);
      (json['choices'][0] as Map)['message'] = {'role': 'assistant', 'content': ''};
      expect(() => parseChatCompletionResponse(json), throwsA(isA<LlmTransportException>()));
    });
  });

  group('arrarrny/zuraffa_agent#5 - proxy routing decision (U4)', () {
    late MockHttpClient client;
    late LlmHttpTransport transport;

    setUpAll(() {
      registerFallbackValue(Uri.parse('http://localhost'));
    });

    setUp(() {
      client = MockHttpClient();
      transport = LlmHttpTransport(clientFactory: () => client);
    });

    Future<void> exercise({required String? proxyUrl}) async {
      when(() => client.postUrl(any())).thenThrow(
        const SocketException('simulated network — no real connection'),
      );
      when(() => client.close(force: any(named: 'force'))).thenAnswer((_) {});

      await expectLater(
        transport.complete(
          baseUrl: 'http://example.test',
          apiKey: 'test-key',
          proxyUrl: proxyUrl,
          model: 'tencent/hy3:free',
          messages: const [ChatMessage(role: 'user', content: 'hi')],
        ),
        throwsA(isA<SocketException>()),
      );
    }

    test('connects directly (no findProxy) when proxyUrl is null or empty', () async {
      // null proxy
      await exercise(proxyUrl: null);
      expect(client.findProxyAssigned, isFalse,
          reason: 'findProxy must not be installed when proxyUrl is null');

      // empty proxy
      await exercise(proxyUrl: '');
      expect(client.findProxyAssigned, isFalse,
          reason: 'findProxy must not be installed when proxyUrl is empty');
    });
  });
}
