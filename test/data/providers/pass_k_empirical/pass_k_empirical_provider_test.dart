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

    test('PassKEmpiricalProvider.current returns the active pass^k snapshot', () async {
      final result = await PassKEmpiricalProvider().current(NoParams());
      expect(result, isA<PassKEmpirical>());
      expect(result.id, 'default');
      expect(result.taskId, 'mission-1');
      expect(result.empiricalRate, 1.0);
    });

    test('PassKEmpiricalProvider.current honors an injected snapshot', () async {
      final injected = const PassKEmpirical(
        id: 'p-1',
        taskId: 'ref-9',
        k: 5,
        successCount: 3,
        empiricalRate: 0.6,
      );
      final result = await PassKEmpiricalProvider(injected).current(NoParams());
      expect(result, same(injected));
    });

    test('PassKEmpiricalProvider.count returns 1', () async {
      expect(await PassKEmpiricalProvider().count(NoParams()), 1);
    });
  });
}
