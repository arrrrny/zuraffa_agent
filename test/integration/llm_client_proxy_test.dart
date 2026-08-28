// ACTUAL INTEGRATION TEST for the LlmClient (spec 065).
//
// Drives a real chat completion through the local proxy (http://localhost:8890)
// against the configured OpenAI-compatible gateway (kilo.ai). This is the
// end-to-end "agent talks to the model" check the user asked for.
//
// It is env-gated and self-skipping so the suite stays green in CI / without
// the proxy:
//   - KIMI_API_KEY  : required bearer token. If unset, all tests skip.
//   - LLM_BASE_URL  : default https://api.kilo.ai/api/gateway
//   - LLM_PROXY_URL : default http://localhost:8890 (empty = direct connect)
//   - LLM_MODEL     : default tencent/hy3:free
//
// Run locally with:
//   KIMI_API_KEY=<jwt> dart test test/integration/llm_client_proxy_test.dart

import 'dart:io';

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';

/// Returns true if the proxy host:port accepts a TCP connection quickly.
Future<bool> _proxyReachable(String proxyUrl) async {
  final uri = Uri.parse(proxyUrl);
  final host = uri.host;
  final port = uri.port;
  try {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
    socket.destroy();
    return true;
  } on Exception {
    return false;
  }
}

void main() {
  final apiKey = Platform.environment['KIMI_API_KEY'] ?? '';
  final baseUrl = Platform.environment['LLM_BASE_URL'] ?? 'https://api.kilo.ai/api/gateway';
  final proxyUrl = Platform.environment['LLM_PROXY_URL'] ?? 'http://localhost:8890';
  final model = Platform.environment['LLM_MODEL'] ?? 'tencent/hy3:free';

  final hasKey = apiKey.isNotEmpty;

  group('LlmClient live integration (via local proxy)', () {
    test('provider resolves the active client from config', () async {
      final provider = LlmClientProvider(
        config: ProviderConfig(
          id: 'kilo',
          providerKind: 'openai',
          baseUrl: baseUrl,
          models: [model],
          timeoutMs: 30000,
        ),
        apiKey: apiKey,
        proxyUrl: proxyUrl,
      );
      final client = await provider.current(NoParams());
      expect(client.providerName, 'kilo');
      expect(client.model, model);
    }, skip: hasKey ? false : 'KIMI_API_KEY not set');

    test('performs a real completion through the proxy', () async {
      if (!hasKey) return; // skip handled below
      if (!await _proxyReachable(proxyUrl)) {
        await Future<void>.value(); // no-op; skip via markTestSkipped
        markTestSkipped('proxy $proxyUrl not reachable');
      }
      final provider = LlmClientProvider(
        config: ProviderConfig(
          id: 'kilo',
          providerKind: 'openai',
          baseUrl: baseUrl,
          models: [model],
          timeoutMs: 30000,
        ),
        apiKey: apiKey,
        proxyUrl: proxyUrl,
      );
      final completion = await provider.complete(const [
        ChatMessage(role: 'user', content: 'Reply with the single word: PONG'),
      ]);
      expect(completion.content, isNotEmpty);
      expect(completion.finishReason, isNotEmpty);
      expect(completion.usage.totalTokens, greaterThan(0));
      print('[integration] model=${completion.usage} content="${completion.content}"');
    }, skip: hasKey ? false : 'KIMI_API_KEY not set');
  });
}
