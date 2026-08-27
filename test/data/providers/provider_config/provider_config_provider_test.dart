// HAND-CURATED regression tests for the ProviderConfig value object +
// ProviderConfigProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/services/provider_config_service.dart';
import 'package:zuraffa_agent/src/data/providers/provider_config/provider_config_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#5 - ProviderConfig value equality', () {
    test('ProviderConfig equality is value-based across all fields', () {
      final a = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.example.com', models: const ['a','b'], timeoutMs: 10);
      final b = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.example.com', models: const ['a','b'], timeoutMs: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('ProviderConfig inequality differs when a field changes', () {
      final a = ProviderConfig(id: 'id-a', providerKind: 'openai', baseUrl: 'https://api.example.com', models: const ['a','b'], timeoutMs: 10);
      final b = ProviderConfig(id: 'id-b', providerKind: 'anthropic', baseUrl: 'https://api.anthropic.com', models: const ['a','b','c'], timeoutMs: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#5 - ProviderConfig clean-arch layers', () {
    test('ProviderConfigProvider is a ProviderConfigService', () {
      expect(ProviderConfigProvider(), isA<ProviderConfigService>());
    });

    test('ProviderConfigProvider.current returns the active provider config', () async {
      final config = await ProviderConfigProvider().current(NoParams());
      expect(config, isA<ProviderConfig>());
      expect(config.id, 'kilo');
      expect(config.providerKind, 'openai');
      expect(config.models, contains('tencent/hy3:free'));
    });

    test('ProviderConfigProvider.count returns the configured provider count', () async {
      expect(await ProviderConfigProvider().count(NoParams()), 1);
    });
  });
}
