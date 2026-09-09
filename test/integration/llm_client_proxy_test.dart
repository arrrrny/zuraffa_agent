// ACTUAL INTEGRATION TEST for the LlmClient (spec 065).
//
// Drives a real chat completion through the local proxy (http://localhost:8890)
// against an operator-configured OpenAI-compatible gateway. This is the
// end-to-end "agent talks to the model" check the user asked for.
//
// spec 106 (issue #117): there is NO default gateway — every endpoint value
// must be provided explicitly by the operator. The test self-skips with a
// stated reason when configuration is absent; it never falls back to a
// vendor.
//
// Required environment:
//   - KIMI_API_KEY  : bearer token (if unset, all tests skip).
//   - LLM_BASE_URL  : the gateway base URL (required — no default).
//   - LLM_MODEL     : the model id (required — no default).
// Optional environment:
//   - LLM_PROXY_URL : local proxy (default http://localhost:8890; empty = direct).
//
// Run locally with:
//   KIMI_API_KEY=<jwt> LLM_BASE_URL=<url> LLM_MODEL=<model> \
//     dart test test/integration/llm_client_proxy_test.dart

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
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return true;
  } on Exception {
    return false;
  }
}

void main() {
  final apiKey = Platform.environment['KIMI_API_KEY'] ?? '';
  final baseUrl = Platform.environment['LLM_BASE_URL'] ?? '';
  final proxyUrl =
      Platform.environment['LLM_PROXY_URL'] ?? 'http://localhost:8890';
  final model = Platform.environment['LLM_MODEL'] ?? '';

  final configured =
      apiKey.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
  final skipReason = configured
      ? false
      : 'live LLM integration requires KIMI_API_KEY, LLM_BASE_URL and '
            'LLM_MODEL to be set explicitly — no default gateway is provided '
            '(spec 106 / issue #117)';

  group('LlmClient live integration (via local proxy)', () {
    test('provider resolves the active client from config', () async {
      final provider = LlmClientProvider(
        config: ProviderConfig(
          id: 'integration',
          providerKind: 'openai',
          baseUrl: baseUrl,
          models: [model],
          timeoutMs: 30000,
        ),
        apiKey: apiKey,
        proxyUrl: proxyUrl,
      );
      final client = await provider.current(NoParams());
      expect(client.model, model);
    }, skip: skipReason);

    test('performs a real completion through the proxy', () async {
      if (!await _proxyReachable(proxyUrl)) {
        markTestSkipped('proxy $proxyUrl not reachable');
      }
      final provider = LlmClientProvider(
        config: ProviderConfig(
          id: 'integration',
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
      print(
        '[integration] model=${completion.usage} content="${completion.content}"',
      );
    }, skip: skipReason);
  });
}
