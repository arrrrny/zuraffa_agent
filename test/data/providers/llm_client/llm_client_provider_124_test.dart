// Issue arrrrny/zuraffa_agent#124 — LlmClientProvider vs LlmTransport seam
// dual-path.
//
// LlmClientProvider.complete() used to call LlmHttpTransport.complete()
// directly — a parallel path that never went through the spec-007 seam
// (LlmTransport -> OpenAiCompatibleClient -> LlmClient), so the retry policy
// (and anything else built on LlmClient) did not apply to the provider the
// engine drives in production.
//
// The canonical path is now the seam. These tests pin:
//  - the default path retries 429/5xx (loopback gateway, no injection);
//  - `transport:` / `client:` injections route through the seam, with
//    ChatMessage <-> LlmRequest / LlmResponse <-> ChatCompletion conversions;
//  - the canonical path exercises retry, circuit-breaker and fallback-chain
//    behavior (acceptance criterion 3) via a FallbackChainClient injection.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/llm/circuit_breaker.dart';
import 'package:zuraffa_agent/src/llm/fallback_chain_client.dart';
import 'package:zuraffa_agent/src/llm/llm_clock.dart';
import 'package:zuraffa_agent/src/llm/openai_compatible_client.dart';
import 'package:zuraffa_agent/src/llm/retry.dart';

import '../../../llm/fake_llm_transport.dart';

String _completionBody(String content, {String? reasoning}) => jsonEncode({
  'choices': [
    {
      'finish_reason': 'stop',
      'message': {
        'role': 'assistant',
        'content': content,
        'reasoning': ?reasoning,
      },
    },
  ],
  'usage': {'prompt_tokens': 3, 'completion_tokens': 2, 'total_tokens': 5},
});

ProviderConfig _config({required String baseUrl}) => ProviderConfig(
  id: 'kilo',
  providerKind: 'openai',
  baseUrl: baseUrl,
  models: const ['tencent/hy3:free'],
  timeoutMs: 30000,
);

void main() {
  group('arrrrny/zuraffa_agent#124 - seam dual-path', () {
    test(
      'default path: complete() retries 429/5xx through the canonical seam path',
      () async {
        var requests = 0;
        final answered = Completer<void>();
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        late final StreamSubscription<HttpRequest> sub;
        sub = server.listen((request) async {
          requests += 1;
          await request.drain<void>();
          if (requests <= 2) {
            request.response.statusCode = 429;
            await request.response.close();
            return;
          }
          request.response.headers.contentType = ContentType.json;
          request.response.write(_completionBody('ok'));
          await request.response.close();
          answered.complete();
        });
        addTearDown(() async {
          await sub.cancel();
          await server.close(force: true);
        });

        final provider = LlmClientProvider(
          config: _config(baseUrl: 'http://127.0.0.1:${server.port}'),
          apiKey: 'test-key',
        );

        final completion = await provider.complete(const [
          ChatMessage(role: 'user', content: 'hi'),
        ]);
        await answered.future.timeout(const Duration(seconds: 5));

        expect(requests, 3, reason: 'two 429s must be retried before the 200');
        expect(completion.content, 'ok');
        expect(completion.finishReason, 'stop');
        expect(completion.usage.totalTokens, 5);
      },
    );

    test('injected seam transport carries the completion request', () async {
      final transport = FakeLlmTransport(
        script: [
          ScriptedResponse(statusCode: 200, body: _completionBody('ok')),
        ],
      );
      final provider = LlmClientProvider(
        config: _config(baseUrl: 'https://kilo.test/v1'),
        apiKey: 'test-key',
        transport: transport,
      );

      final completion = await provider.complete(const [
        ChatMessage(role: 'user', content: 'hi'),
      ]);

      expect(completion.content, 'ok');
      expect(transport.requests, hasLength(1));
      final request = transport.requests.single;
      expect(request.uri.toString(), 'https://kilo.test/v1/chat/completions');
      expect(request.headers['authorization'], 'Bearer test-key');
    });

    test(
      'a leading system message rides LlmRequest.systemPrompt (wire position preserved)',
      () async {
        final transport = FakeLlmTransport(
          script: [
            ScriptedResponse(statusCode: 200, body: _completionBody('ok')),
          ],
        );
        final provider = LlmClientProvider(
          config: _config(baseUrl: 'https://kilo.test/v1'),
          apiKey: 'test-key',
          transport: transport,
        );

        await provider.complete(const [
          ChatMessage(role: 'system', content: 'be terse'),
          ChatMessage(role: 'user', content: 'hi'),
        ]);

        final body =
            jsonDecode(transport.requests.single.body) as Map<String, dynamic>;
        expect(body['messages'], [
          {'role': 'system', 'content': 'be terse'},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'hi'},
            ],
          },
        ]);
      },
    );

    test(
      'seam response maps back onto ChatCompletion (reasoning, usage)',
      () async {
        final transport = FakeLlmTransport(
          script: [
            ScriptedResponse(
              statusCode: 200,
              body: _completionBody(
                'PONG',
                reasoning: 'the user asked for a single word',
              ),
            ),
          ],
        );
        final provider = LlmClientProvider(
          config: _config(baseUrl: 'https://kilo.test/v1'),
          apiKey: 'test-key',
          transport: transport,
        );

        final completion = await provider.complete(const [
          ChatMessage(role: 'user', content: 'hi'),
        ]);

        expect(completion.content, 'PONG');
        expect(completion.reasoning, 'the user asked for a single word');
        expect(completion.finishReason, 'stop');
        expect(completion.usage.promptTokens, 3);
        expect(completion.usage.completionTokens, 2);
        expect(completion.usage.totalTokens, 5);
      },
    );

    test(
      'canonical path exercises retry, breaker and fallback-chain behavior',
      () async {
        // Provider a: two 500s -> its client's retry budget (2 attempts)
        // exhausts, the chain's breaker records the failure, and the chain
        // advances to provider b, which answers on the first try.
        final firstTransport = FakeLlmTransport(
          provider: 'a',
          script: [
            const ScriptedResponse(statusCode: 500),
            const ScriptedResponse(statusCode: 500),
          ],
        );
        final secondTransport = FakeLlmTransport(
          provider: 'b',
          script: [
            ScriptedResponse(statusCode: 200, body: _completionBody('from-b')),
          ],
        );
        final chain = FallbackChainClient(
          providers: [
            (
              id: 'a',
              client: OpenAiCompatibleClient(
                providerName: 'a',
                transport: firstTransport,
                baseUrl: 'https://a.test/v1',
                model: 'tencent/hy3:free',
                apiKey: 'test-key',
                retryConfig: const RetryConfig(
                  maxAttempts: 2,
                  baseDelayMs: 1,
                  maxDelayMs: 2,
                ),
              ),
            ),
            (
              id: 'b',
              client: OpenAiCompatibleClient(
                providerName: 'b',
                transport: secondTransport,
                baseUrl: 'https://b.test/v1',
                model: 'tencent/hy3:free',
                apiKey: 'test-key',
                retryConfig: const RetryConfig(
                  maxAttempts: 2,
                  baseDelayMs: 1,
                  maxDelayMs: 2,
                ),
              ),
            ),
          ],
          clock: const SystemLlmClock(),
        );
        final provider = LlmClientProvider(
          config: _config(baseUrl: 'https://kilo.test/v1'),
          apiKey: 'test-key',
          client: chain,
        );

        final completion = await provider.complete(const [
          ChatMessage(role: 'user', content: 'hi'),
        ]);

        // Retry: provider a saw both attempts before its budget exhausted.
        expect(firstTransport.requests, hasLength(2));
        // Fallback chain: provider b answered the failed-over request.
        expect(secondTransport.requests, hasLength(1));
        expect(completion.content, 'from-b');
        // Breaker: the failure on a was recorded by its circuit breaker.
        expect(chain.breakers['a']!.consecutiveFailures, 1);
        expect(chain.breakers['b']!.state, CircuitState.closed);
      },
    );

    // Issue #159 review (functional correctness): the reroute must keep the
    // legacy empty-completion failure semantics — LlmHttpTransport's parser
    // threw on a 200 with no choices or empty content, and the resilience
    // stack only reacts to thrown errors.
    test(
      'a 200 with empty message content throws (legacy empty-content guard)',
      () async {
        final transport = FakeLlmTransport(
          script: [
            ScriptedResponse(statusCode: 200, body: _completionBody('')),
          ],
        );
        final provider = LlmClientProvider(
          config: _config(baseUrl: 'https://kilo.test/v1'),
          apiKey: 'test-key',
          transport: transport,
        );

        await expectLater(
          provider.complete(const [ChatMessage(role: 'user', content: 'hi')]),
          throwsA(
            isA<StateError>().having(
              (e) => e.message.toString(),
              'message',
              contains('completion content was empty'),
            ),
          ),
        );
      },
    );

    test('a 200 with no choices throws (legacy no-choices guard)', () async {
      final transport = FakeLlmTransport(
        script: [
          ScriptedResponse(
            statusCode: 200,
            body: jsonEncode({
              'usage': {
                'prompt_tokens': 1,
                'completion_tokens': 0,
                'total_tokens': 1,
              },
            }),
          ),
        ],
      );
      final provider = LlmClientProvider(
        config: _config(baseUrl: 'https://kilo.test/v1'),
        apiKey: 'test-key',
        transport: transport,
      );

      // The seam parser reduces a choices-less payload to empty content;
      // the provider boundary must still fail loudly.
      await expectLater(
        provider.complete(const [ChatMessage(role: 'user', content: 'hi')]),
        throwsA(isA<StateError>()),
      );
    });

    // Issue #159 review (stability): the default stack owns a long-lived
    // HttpClient; close() must reach the socket.
    test(
      'close() reaches the seam: provider.close() closes the injected transport',
      () async {
        final transport = _CloseCountingTransport(
          script: [
            ScriptedResponse(statusCode: 200, body: _completionBody('ok')),
          ],
        );
        final provider = LlmClientProvider(
          config: _config(baseUrl: 'https://kilo.test/v1'),
          apiKey: 'test-key',
          transport: transport,
        );

        expect(transport.closeCount, 0);
        await provider.close();
        expect(transport.closeCount, 1);
      },
    );

    test(
      'close() on the default stack closes the underlying HttpClient',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        late final StreamSubscription<HttpRequest> sub;
        sub = server.listen((request) async {
          await request.drain<void>();
          request.response.headers.contentType = ContentType.json;
          request.response.write(_completionBody('ok'));
          await request.response.close();
        });
        addTearDown(() async {
          await sub.cancel();
          await server.close(force: true);
        });

        final provider = LlmClientProvider(
          config: _config(baseUrl: 'http://127.0.0.1:${server.port}'),
          apiKey: 'test-key',
        );
        final first = await provider.complete(const [
          ChatMessage(role: 'user', content: 'hi'),
        ]);
        expect(first.content, 'ok');

        await provider.close();
        // dart:io answers a request on a closed HttpClient with
        // "Bad state: Client is closed" — proof the close reached the
        // socket the default IoLlmTransport holds.
        await expectLater(
          provider.complete(const [ChatMessage(role: 'user', content: 'hi')]),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}

/// Counts close() calls — pins that the provider's close path reaches the
/// injected seam transport (issue #159 review).
class _CloseCountingTransport extends FakeLlmTransport {
  _CloseCountingTransport({required super.script});

  int closeCount = 0;

  @override
  Future<void> close() async => closeCount++;
}
