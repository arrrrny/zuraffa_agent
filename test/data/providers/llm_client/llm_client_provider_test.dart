// HAND-CURATED regression tests for the LlmClient value object +
// LlmClientProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/llm_client/llm_client.dart';
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
    test('LlmClientProvider is a LlmClientService', () {
      final provider = LlmClientProvider();
      expect(provider, isA<LlmClientService>());
    });

    test('LlmClientProvider.current throws UnimplementedError on NoParams', () {
      final provider = LlmClientProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('LlmClientProvider.count throws UnimplementedError on NoParams', () {
      final provider = LlmClientProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
