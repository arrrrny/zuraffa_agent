// HAND-CURATED regression tests for the SubAgentContext value object +
// SubAgentContextProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/sub_agent_context/sub_agent_context.dart';
import 'package:zuraffa_agent/src/domain/services/sub_agent_context_service.dart';
import 'package:zuraffa_agent/src/data/providers/sub_agent_context/sub_agent_context_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 - SubAgentContext value equality', () {
    test('SubAgentContext equality is value-based across all fields', () {
      final a = SubAgentContext(id: 'id-a', subAgentSpecId: 'ref-1', sessionId: 'sess-1', toolAllowlist: const ['a','b'], budgetTurns: 10);
      final b = SubAgentContext(id: 'id-a', subAgentSpecId: 'ref-1', sessionId: 'sess-1', toolAllowlist: const ['a','b'], budgetTurns: 10);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SubAgentContext inequality differs when a field changes', () {
      final a = SubAgentContext(id: 'id-a', subAgentSpecId: 'ref-1', sessionId: 'sess-1', toolAllowlist: const ['a','b'], budgetTurns: 10);
      final b = SubAgentContext(id: 'id-b', subAgentSpecId: 'ref-2', sessionId: 'sess-2', toolAllowlist: const ['a','b','c'], budgetTurns: 20);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 - SubAgentContext clean-arch layers', () {
    test('SubAgentContextProvider is a SubAgentContextService', () {
      final provider = SubAgentContextProvider();
      expect(provider, isA<SubAgentContextService>());
    });

    test('SubAgentContextProvider.current throws UnimplementedError on NoParams', () {
      final provider = SubAgentContextProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('SubAgentContextProvider.count throws UnimplementedError on NoParams', () {
      final provider = SubAgentContextProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
