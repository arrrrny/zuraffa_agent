// Spec: issue arrrrny/zuraffa_agent#8 (Wave U — Generative UI) —
// MissionBudget + MissionBudgetEnforcer for UI tree caps (AC-3).
//
// Covers:
// - MissionBudget construction + equality + hasAnyUiCap
// - UiBudgetExceededError typed error
// - MissionBudgetEnforcer.checkUiTree:
//   * no-op when budget has no UI caps
//   * throws on depth cap exceeded
//   * throws on node-count cap exceeded
//   * returns silently when within caps
//   * O(1) — uses precomputed depth/nodeCount (no tree walk)

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/mission_budget/mission_budget.dart';
import 'package:zuraffa_agent/src/domain/entities/ui_tree_payload/ui_tree_payload.dart';

UiTreePayload _payload(Map<String, dynamic> tree) => UiTreePayload(
  vocabularyId: 'shadcn-ui@1.0.0',
  schemaVersion: '1.0.0',
  tree: tree,
);

void main() {
  group('issue #8 AC-3 — MissionBudget value object', () {
    test('construction and equality', () {
      expect(
        const MissionBudget(maxUiTreeDepth: 3, maxUiTreeNodeCount: 10),
        const MissionBudget(maxUiTreeDepth: 3, maxUiTreeNodeCount: 10),
      );
    });

    test('hasAnyUiCap is false when no caps set', () {
      expect(const MissionBudget().hasAnyUiCap, isFalse);
    });

    test('hasAnyUiCap is true when only depth set', () {
      expect(const MissionBudget(maxUiTreeDepth: 3).hasAnyUiCap, isTrue);
    });

    test('hasAnyUiCap is true when only nodeCount set', () {
      expect(const MissionBudget(maxUiTreeNodeCount: 10).hasAnyUiCap, isTrue);
    });
  });

  group('issue #8 AC-3 — UiBudgetExceededError', () {
    test('is a typed exception carrying field/actual/cap', () {
      final e = UiBudgetExceededError(field: 'depth', actual: 5, cap: 3);
      expect(e.field, 'depth');
      expect(e.actual, 5);
      expect(e.cap, 3);
      expect(e.toString(), contains('depth'));
      expect(e.toString(), contains('5'));
      expect(e.toString(), contains('3'));
    });
  });

  group('issue #8 AC-3 — MissionBudgetEnforcer.checkUiTree', () {
    test('no-op when budget has no UI caps', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget();
      enforcer.checkUiTree(_payload({'type': 'Column'}), budget);
    });

    test('returns silently when payload is within depth cap', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget(maxUiTreeDepth: 5);
      // 2-level tree → depth 2 ≤ 5.
      enforcer.checkUiTree(
        _payload({
          'type': 'Column',
          'children': [
            {'type': 'Text'},
          ],
        }),
        budget,
      );
    });

    test('returns silently when payload is within node-count cap', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget(maxUiTreeNodeCount: 10);
      enforcer.checkUiTree(
        _payload({
          'type': 'Column',
          'children': [
            {'type': 'Text'},
            {'type': 'Text'},
          ],
        }),
        budget,
      );
    });

    test('throws UiBudgetExceededError when depth exceeds cap', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget(maxUiTreeDepth: 2);
      // 3-level tree → depth 3 > 2.
      final payload = _payload({
        'type': 'Column',
        'children': [
          {
            'type': 'Row',
            'children': [
              {'type': 'Text'},
            ],
          },
        ],
      });
      expect(
        () => enforcer.checkUiTree(payload, budget),
        throwsA(isA<UiBudgetExceededError>()),
      );
    });

    test('throws UiBudgetExceededError when nodeCount exceeds cap', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget(maxUiTreeNodeCount: 2);
      // 3-node tree → nodeCount 3 > 2.
      final payload = _payload({
        'type': 'Column',
        'children': [
          {'type': 'Text'},
          {'type': 'Text'},
        ],
      });
      expect(
        () => enforcer.checkUiTree(payload, budget),
        throwsA(isA<UiBudgetExceededError>()),
      );
    });

    test(
      'O(1): enforcer does not walk the tree (depth/nodeCount are precomputed)',
      () {
        // A deep tree (depth 50) and a wide tree (1000 nodes) should both
        // pass the enforcer in O(1) — depth/nodeCount are precomputed by
        // UiTreePayload's constructor, so the enforcer is two int compares.
        const enforcer = MissionBudgetEnforcer();
        const budget = MissionBudget(
          maxUiTreeDepth: 100,
          maxUiTreeNodeCount: 10000,
        );

        // Deep tree (depth 50, nodeCount 50).
        Map<String, dynamic> deep = {'type': 'Leaf'};
        for (var i = 0; i < 49; i++) {
          deep = {
            'type': 'Node',
            'children': [deep],
          };
        }
        final deepPayload = _payload(deep);
        expect(deepPayload.depth, 50);
        expect(deepPayload.nodeCount, 50);
        enforcer.checkUiTree(deepPayload, budget);

        // Wide tree (depth 2, nodeCount 1001).
        final wide = {
          'type': 'Column',
          'children': [
            for (var i = 0; i < 1000; i++) {'type': 'Text'},
          ],
        };
        final widePayload = _payload(wide);
        expect(widePayload.nodeCount, 1001);
        enforcer.checkUiTree(widePayload, budget);
      },
    );

    test('depth checked before nodeCount (first exceeded cap throws)', () {
      const enforcer = MissionBudgetEnforcer();
      const budget = MissionBudget(maxUiTreeDepth: 1, maxUiTreeNodeCount: 1);
      // 2-level tree, 2 nodes → both caps exceeded. Depth is checked first.
      final payload = _payload({
        'type': 'Column',
        'children': [
          {'type': 'Text'},
        ],
      });
      expect(
        () => enforcer.checkUiTree(payload, budget),
        throwsA(
          predicate(
            (Object? e) => e is UiBudgetExceededError && e.field == 'depth',
          ),
        ),
      );
    });
  });
}
