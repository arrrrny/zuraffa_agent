// HAND-CURATED regression tests for the LlmClient value object +
// LlmClientProvider. Pattern mirrors spec 033.

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_completion.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/chat_message.dart';
import 'package:zuraffa_agent/src/domain/entities/llm_client/llm_client.dart';
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/services/llm_client_service.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_client_provider.dart';
import 'package:zuraffa_agent/src/data/providers/llm_client/llm_http_transport.dart';

// Mock of the concrete platform-I/O transport so we can assert exactly which
// arguments LlmClientProvider forwards into the completion call (U11).
class MockLlmHttpTransport extends Mock implements LlmHttpTransport {}

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

  group('arrarrny/zuraffa_agent#5 - timeout forwarding (U11)', () {
    late MockLlmHttpTransport transport;
    late LlmClientProvider provider;

    setUpAll(() {
      registerFallbackValue(
        <ChatMessage>[const ChatMessage(role: 'user', content: 'x')],
      );
    });

    setUp(() {
      transport = MockLlmHttpTransport();
      provider = LlmClientProvider(
        config: const ProviderConfig(
          id: 'kilo',
          providerKind: 'openai',
          baseUrl: 'https://example.invalid/v1',
          models: ['tencent/hy3:free'],
          timeoutMs: 30000,
        ),
        apiKey: 'test-key',
        transport: transport,
      );
    });

    test('forwards ProviderConfig.timeoutMs to the transport completion timeout', () async {
      when(() => transport.complete(
        baseUrl: any(named: 'baseUrl'),
        apiKey: any(named: 'apiKey'),
        proxyUrl: any(named: 'proxyUrl'),
        model: any(named: 'model'),
        messages: any(named: 'messages'),
        timeout: any(named: 'timeout'),
      )).thenAnswer((_) async => const ChatCompletion(
        content: 'ok',
        finishReason: 'stop',
        usage: TokenUsage(promptTokens: 1, completionTokens: 1, totalTokens: 2),
      ));

      await provider.complete([const ChatMessage(role: 'user', content: 'hi')]);

      verify(() => transport.complete(
        baseUrl: any(named: 'baseUrl'),
        apiKey: any(named: 'apiKey'),
        proxyUrl: any(named: 'proxyUrl'),
        model: any(named: 'model'),
        messages: any(named: 'messages'),
        timeout: const Duration(milliseconds: 30000),
      )).called(1);
    });
  });
}
