// HAND-CURATED regression tests for the ProviderConfig value object +
// ProviderConfigProvider. Pattern mirrors spec 033.
//
// spec 106 (issue #117): the provider no longer invents a default —
// constructing without an injected configuration fails closed at
// construction, and a configured provider serves the injected values
// verbatim. The former "no-arg construction returns the kilo.ai default"
// pins were retired with that invented-default behavior (the vendor strip
// is this spec's purpose).

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/provider_config/provider_config.dart';
import 'package:zuraffa_agent/src/domain/services/provider_config_service.dart';
import 'package:zuraffa_agent/src/data/providers/provider_config/provider_config_provider.dart';

const _explicitConfig = ProviderConfig(
  id: 'explicit',
  providerKind: 'openai',
  baseUrl: 'https://llm.example.internal/api',
  models: ['internal/model'],
  timeoutMs: 30000,
);

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

  group('spec 106 - fail-closed provider configuration (issue #117)', () {
    test(
        'U1: constructing without a configuration throws ArgumentError naming it',
        () {
      expect(
        () => ProviderConfigProvider(),
        throwsA(
          predicate((Object e) =>
              e is ArgumentError &&
              e.message.toString().contains('ProviderConfig')),
        ),
      );
    });

    test('U2: a configured provider serves the injected config verbatim',
        () async {
      final provider = ProviderConfigProvider(_explicitConfig);
      expect(provider, isA<ProviderConfigService>());
      final config = await provider.current(NoParams());
      expect(config, same(_explicitConfig));
      expect(config.baseUrl, 'https://llm.example.internal/api');
      expect(config.models, ['internal/model']);
      expect(await provider.count(NoParams()), 1);
    });

    test('A1: explicit construction never trips the fail-closed path',
        () async {
      // Constructing with a configuration must not throw on that path.
      final provider = ProviderConfigProvider(_explicitConfig);
      final config = await provider.current(NoParams());
      expect(config.id, 'explicit');
    });
  });
}
