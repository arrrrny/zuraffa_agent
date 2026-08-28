// HAND-CURATED regression tests for the SubAgentInstance value object +
// SubAgentInstanceProvider. Pattern mirrors spec 033.

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

    test('SubAgentInstanceProvider.current returns the active instance', () async {
      final inst = await SubAgentInstanceProvider().current(NoParams());
      expect(inst, isA<SubAgentInstance>());
      expect(inst.id, 'instance-default');
      expect(inst.parentSessionId, 'session-default');
      expect(inst.totalRuns, 0);
      expect(inst.lastRunOutcome, isNull);
    });

    test('SubAgentInstanceProvider.current returns a supplied active instance', () async {
      final active = SubAgentInstance(id: 'inst-x', subAgentSpecId: 'spec-x', parentSessionId: 'sess-x', totalRuns: 3, lastRunOutcome: 'ok');
      expect(await SubAgentInstanceProvider(active).current(NoParams()), active);
    });

    test('SubAgentInstanceProvider.count returns 1', () async {
      expect(await SubAgentInstanceProvider().count(NoParams()), 1);
    });
  });
}
