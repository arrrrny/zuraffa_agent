// HAND-CURATED regression tests for the SubAgentInstance value object +
// SubAgentInstanceProvider stub. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/domain/entities/sub_agent_instance/sub_agent_instance.dart';
import 'package:zuraffa_agent/src/domain/services/sub_agent_instance_service.dart';
import 'package:zuraffa_agent/src/data/providers/sub_agent_instance/sub_agent_instance_provider.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 - SubAgentInstance value equality', () {
    test('SubAgentInstance equality is value-based across all fields', () {
      final a = SubAgentInstance(id: 'id-a', subAgentSpecId: 'ref-1', parentSessionId: 'sess-1', totalRuns: 10, lastRunOutcome: null);
      final b = SubAgentInstance(id: 'id-a', subAgentSpecId: 'ref-1', parentSessionId: 'sess-1', totalRuns: 10, lastRunOutcome: null);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SubAgentInstance inequality differs when a field changes', () {
      final a = SubAgentInstance(id: 'id-a', subAgentSpecId: 'ref-1', parentSessionId: 'sess-1', totalRuns: 10, lastRunOutcome: null);
      final b = SubAgentInstance(id: 'id-b', subAgentSpecId: 'ref-2', parentSessionId: 'sess-2', totalRuns: 20, lastRunOutcome: null);
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 - SubAgentInstance clean-arch layers', () {
    test('SubAgentInstanceProvider is a SubAgentInstanceService', () {
      final provider = SubAgentInstanceProvider();
      expect(provider, isA<SubAgentInstanceService>());
    });

    test('SubAgentInstanceProvider.current throws UnimplementedError on NoParams', () {
      final provider = SubAgentInstanceProvider();
      expect(
        () => provider.current(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('SubAgentInstanceProvider.count throws UnimplementedError on NoParams', () {
      final provider = SubAgentInstanceProvider();
      expect(
        () => provider.count(NoParams()),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
