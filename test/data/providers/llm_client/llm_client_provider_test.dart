// HAND-CURATED regression tests for the LlmClient value object +
// LlmClientProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/llm_client/llm_client.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/services/llm_client_service.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#5 - LlmClient value equality', () {
    test('LlmClient equality is value-based across all fields', () {
      final a = LlmClient(id: 'id-a', providerName: 'openai', model: 'gpt-4o', supportsStreaming: true, supportsThinking: true);
      final b = LlmClient(id: 'id-a', providerName: 'openai', model: 'gpt-4o', supportsStreaming: true, supportsThinking: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('LlmClient inequality differs when a field changes', () {
      final a = LlmClient(id: 'id-a', providerName: 'openai', model: 'gpt-4o', supportsStreaming: true, supportsThinking: true);
      final b = LlmClient(id: 'id-b', providerName: 'anthropic', model: 'claude-3', supportsStreaming: false, supportsThinking: false);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#5 - LlmClient clean-arch layers', () {
    final provider = LlmClientProvider(
      config: const ProviderConfig(
        id: 'kilo',
        providerKind: 'openai',
        baseUrl: 'https://example.invalid/v1',
        models: ['tencent/hy3:free'],
        timeoutMs: 30000,
      ),
      apiKey: 'test-key',
    );

    test('LlmClientProvider is a LlmClientService', () {
      expect(provider, isA<LlmClientService>());
    });

    test('LlmClientProvider.current returns the active LlmClient (no longer stubbed)', () async {
      final client = await provider.current(NoParams());
      expect(client, isA<LlmClient>());
      expect(client.providerName, 'kilo');
      expect(client.model, 'tencent/hy3:free');
      expect(client.supportsStreaming, isTrue);
      expect(client.supportsThinking, isTrue);
    });

    test('LlmClientProvider.count returns the number of usable clients', () async {
      expect(await provider.count(NoParams()), 1);
    });
  });
}
