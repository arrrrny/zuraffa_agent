// HAND-CURATED regression tests for the SubAgentContext value object +
// SubAgentContextProvider. Pattern mirrors spec 033.

import 'package:test/test.dart';
import 'package:zuraffa/zuraffa.dart' show NoParams;
import 'package:zuraffa_agent/src/data/providers/sub_agent_context/sub_agent_context_provider.dart';
import 'package:zuraffa_agent/src/domain/entities/sub_agent_context/sub_agent_context.dart';
import 'package:zuraffa_agent/src/domain/services/sub_agent_context_service.dart';

void main() {
  group('arrarrny/zuraffa_agent#6 - SubAgentContext value equality', () {
    test('SubAgentContext equality is value-based across all fields', () {
      const a = SubAgentContext(
        id: 'id-a',
        subAgentSpecId: 'ref-1',
        sessionId: 'sess-1',
        toolAllowlist: ['a', 'b'],
        budgetTurns: 10,
      );
      const b = SubAgentContext(
        id: 'id-a',
        subAgentSpecId: 'ref-1',
        sessionId: 'sess-1',
        toolAllowlist: ['a', 'b'],
        budgetTurns: 10,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('SubAgentContext inequality differs when a field changes', () {
      const a = SubAgentContext(
        id: 'id-a',
        subAgentSpecId: 'ref-1',
        sessionId: 'sess-1',
        toolAllowlist: ['a', 'b'],
        budgetTurns: 10,
      );
      const b = SubAgentContext(
        id: 'id-b',
        subAgentSpecId: 'ref-2',
        sessionId: 'sess-2',
        toolAllowlist: ['a', 'b', 'c'],
        budgetTurns: 20,
      );
      expect(a == b, isFalse);
    });
  });

  group('arrarrny/zuraffa_agent#6 - SubAgentContext clean-arch layers', () {
    test('SubAgentContextProvider is a SubAgentContextService', () {
      final provider = SubAgentContextProvider();
      expect(provider, isA<SubAgentContextService>());
    });

    test(
      'SubAgentContextProvider.current returns the active context',
      () async {
        final ctx = await SubAgentContextProvider().current(const NoParams());
        expect(ctx, isA<SubAgentContext>());
        expect(ctx.id, 'ctx-default');
        expect(ctx.sessionId, 'session-default');
        expect(ctx.toolAllowlist, isEmpty);
        expect(ctx.budgetTurns, greaterThan(0));
      },
    );

    test(
      'SubAgentContextProvider.current returns a supplied active context',
      () async {
        const active = SubAgentContext(
          id: 'ctx-x',
          subAgentSpecId: 'spec-x',
          sessionId: 'sess-x',
          toolAllowlist: ['fs.read'],
          budgetTurns: 5,
        );
        expect(
          await SubAgentContextProvider(active).current(const NoParams()),
          active,
        );
      },
    );

    test(
      'SubAgentContextProvider.count returns the tracked context count',
      () async {
        expect(await SubAgentContextProvider().count(const NoParams()), 1);
      },
    );
  });
}
