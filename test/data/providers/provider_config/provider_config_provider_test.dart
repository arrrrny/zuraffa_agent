// HAND-CURATED regression tests for the ProviderConfig value object +
// ProviderConfigProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/services/provider_config_service.dart';
import 'package:zuraffa_agent/src/data/providers/provider_config/provider_config_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#5 - ProviderConfig value equality', () {
    test('ProviderConfig equality is value-based across all fields', () {
      final a = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.openai.com', models: const ['a','b'], timeoutMs: 10);
      final b = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.openai.com', models: const ['a','b'], timeoutMs: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ProviderConfig inequality differs when a field changes', () {
      final a = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.openai.com', models: const ['a','b'], timeoutMs: 10);
      final b = ProviderConfig(id: 'id-b', providerKind: 'anthropic', baseUrl: 'https://api.anthropic.com', models: const ['a','b','c'], timeoutMs: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#5 - ProviderConfig clean-arch layers', () {
    test('ProviderConfigProvider is a ProviderConfigService', () {
      final provider = ProviderConfigProvider();
      expect(provider, isA<ProviderConfigService>());
    });

    test('ProviderConfigProvider.current throws UnimplementedError on NoParams', () {
      final provider = ProviderConfigProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('ProviderConfigProvider.count throws UnimplementedError on NoParams', () {
      final provider = ProviderConfigProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
