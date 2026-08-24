// HAND-CURATED regression tests for the FallbackChain value object +
// FallbackChainProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/fallback_chain/fallback_chain.dart';
import 'package:zuraffa_agent/src/domain/services/fallback_chain_service.dart';
import 'package:zuraffa_agent/src/data/providers/fallback_chain/fallback_chain_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#5 - FallbackChain value equality', () {
    test('FallbackChain equality is value-based across all fields', () {
      final a = FallbackChain(id: 'id-a', providerIds: const ['a','b'], currentProviderIndex: 10, advances: 10, lastErrorClass: null);
      final b = FallbackChain(id: 'id-a', providerIds: const ['a','b'], currentProviderIndex: 10, advances: 10, lastErrorClass: null);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('FallbackChain inequality differs when a field changes', () {
      final a = FallbackChain(id: 'id-a', providerIds: const ['a','b'], currentProviderIndex: 10, advances: 10, lastErrorClass: null);
      final b = FallbackChain(id: 'id-b', providerIds: const ['a','b','c'], currentProviderIndex: 20, advances: 20, lastErrorClass: null);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#5 - FallbackChain clean-arch layers', () {
    test('FallbackChainProvider is a FallbackChainService', () {
      final provider = FallbackChainProvider();
      expect(provider, isA<FallbackChainService>());
    });

    test('FallbackChainProvider.current throws UnimplementedError on NoParams', () {
      final provider = FallbackChainProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('FallbackChainProvider.count throws UnimplementedError on NoParams', () {
      final provider = FallbackChainProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
