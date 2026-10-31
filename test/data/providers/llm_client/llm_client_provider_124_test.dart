// Issue arrrrny/zuraffa_agent#124 — LlmClientProvider vs LlmTransport seam
// dual-path (red pin).
//
// LlmClientProvider.complete() used to call LlmHttpTransport.complete()
// directly — a parallel path that never went through the spec-007 seam
// (LlmTransport -> OpenAiCompatibleClient -> LlmClient), so the retry policy
// (and anything else built on LlmClient) did not apply to the provider the
// engine drives in production.
//
// This test drives the provider's DEFAULT path against a loopback gateway
// that answers 429 twice and then 200. The canonical seam path retries the
// rate-limits and succeeds (3 HTTP requests); the legacy direct path makes
// exactly one request and throws.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';

void main() {
  group('arrrrny/zuraffa_agent#124 - seam dual-path', () {
    test(
      'complete() retries 429/5xx through the canonical seam path',
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
          request.response.write(
            jsonEncode({
              'choices': [
                {
                  'finish_reason': 'stop',
                  'message': {'role': 'assistant', 'content': 'ok'},
                },
              ],
              'usage': {
                'prompt_tokens': 3,
                'completion_tokens': 2,
                'total_tokens': 5,
              },
            }),
          );
          await request.response.close();
          answered.complete();
        });
        addTearDown(() async {
          await sub.cancel();
          await server.close(force: true);
        });

        final provider = LlmClientProvider(
          config: ProviderConfig(
            id: 'kilo',
            providerKind: 'openai',
            baseUrl: 'http://127.0.0.1:${server.port}',
            models: ['tencent/hy3:free'],
            timeoutMs: 30000,
          ),
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
  });
}
