// HAND-CURATED regression tests for the PassKEmpirical value object +
// PassKEmpiricalProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/pass_k_empirical/pass_k_empirical.dart';
import 'package:zuraffa_agent/src/domain/services/pass_k_empirical_service.dart';
import 'package:zuraffa_agent/src/data/providers/pass_k_empirical/pass_k_empirical_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#7 - PassKEmpirical value equality', () {
    test('PassKEmpirical equality is value-based across all fields', () {
      final a = PassKEmpirical(id: 'id-a', taskId: 'ref-1', k: 10, successCount: 10, empiricalRate: 0.5);
      final b = PassKEmpirical(id: 'id-a', taskId: 'ref-1', k: 10, successCount: 10, empiricalRate: 0.5);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('PassKEmpirical inequality differs when a field changes', () {
      final a = PassKEmpirical(id: 'id-a', taskId: 'ref-1', k: 10, successCount: 10, empiricalRate: 0.5);
      final b = PassKEmpirical(id: 'id-b', taskId: 'ref-2', k: 20, successCount: 20, empiricalRate: 0.75);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#7 - PassKEmpirical clean-arch layers', () {
    test('PassKEmpiricalProvider is a PassKEmpiricalService', () {
      final provider = PassKEmpiricalProvider();
      expect(provider, isA<PassKEmpiricalService>());
    });

    test('PassKEmpiricalProvider.current throws UnimplementedError on NoParams', () {
      final provider = PassKEmpiricalProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('PassKEmpiricalProvider.count throws UnimplementedError on NoParams', () {
      final provider = PassKEmpiricalProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
