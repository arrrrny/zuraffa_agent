// Spec 085 — R6 Eval suite health & release gate: pass@k gating (issue
// #96, parent epic #7).
//
// RED surface (new behavior):
//   T1  Zero-task suite at threshold 0.0 → passed == false, exitCode == 1,
//       report names the fail-closed reason (currently PASSES — fail-open).
//   T2  TaskSamples(n: 0) → no throw; the task scores 0.0 with a zero-runs
//       detail; the gate is vetoed (currently ArgumentError).
//   T3  Mixed missing + zero-run → incomplete == true with
//       incompleteTaskIds in suite order; complete suite → false/empty.
//
// Pins (existing behavior, previously unguarded at these edges):
//   T4  All tasks missing → fail, all ids listed, score 0.0.
//   T5  >= boundary: score exactly at threshold passes.
//   T6  Unbiased per-task value pass-through (n:10, c:4, k:1 → 0.4).
//   T7  Extra sample ids not declared by the suite are ignored.
//   T8  c > n still throws ArgumentError.

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/eval/suite_gate.dart';

const kSuiteId = 'gm-suite-085';

Suite suiteWith({
  required double gateThreshold,
  List<String> tasks = const ['GM-1', 'GM-2', 'GM-3'],
  int k = 1,
}) =>
    Suite(
      id: kSuiteId,
      name: 'golden missions 085',
      tasks: tasks,
      k: k,
      gateThreshold: gateThreshold,
    );

void main() {
  group('spec 085 — fail-closed edges (FR-005, FR-006, FR-007)', () {
    test('T1: a zero-task suite fails closed even at threshold 0.0', () {
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.0, tasks: const []),
        samples: const {},
      );

      expect(decision.passed, isFalse,
          reason: 'a gate over zero tasks is not evidence — fail closed');
      expect(decision.exitCode, 1);
      expect(decision.score, 0.0);
      expect(decision.breakdown, isEmpty);
      expect(decision.report, contains('no tasks'));
    });

    test('T2: a zero-run task vetoes instead of crashing', () {
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.3),
        samples: const {
          'GM-1': TaskSamples(n: 4, c: 4),
          'GM-2': TaskSamples(n: 0, c: 0), // crashed worker / empty glob
          'GM-3': TaskSamples(n: 4, c: 4),
        },
      );

      // Score without the veto would be (1.0 + 0.0 + 1.0) / 3 >= 0.3 —
      // the veto is what fails it.
      expect(decision.passed, isFalse);
      expect(decision.breakdown[1].taskId, 'GM-2');
      expect(decision.breakdown[1].passAtK, 0.0);
      expect(decision.breakdown[1].detail, contains('zero runs'));
      expect(decision.report, contains('zero runs'));
    });

    test('T3: the veto is machine-readable and in suite order', () {
      final vetoed = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.3),
        samples: const {
          'GM-2': TaskSamples(n: 4, c: 4),
          'GM-3': TaskSamples(n: 0, c: 0), // GM-1 missing entirely
        },
      );
      expect(vetoed.incomplete, isTrue);
      expect(vetoed.incompleteTaskIds, ['GM-1', 'GM-3']);
      expect(vetoed.passed, isFalse);

      final complete = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.3),
        samples: const {
          'GM-1': TaskSamples(n: 4, c: 4),
          'GM-2': TaskSamples(n: 4, c: 2),
          'GM-3': TaskSamples(n: 4, c: 4),
        },
      );
      expect(complete.incomplete, isFalse);
      expect(complete.incompleteTaskIds, isEmpty);
      expect(complete.passed, isTrue);
    });
  });

  group('spec 085 — pins', () {
    test('T4 (pin): all tasks missing → fail with every id listed', () {
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.0),
        samples: const {},
      );

      expect(decision.passed, isFalse);
      expect(decision.score, 0.0);
      expect(decision.incomplete, isTrue);
      expect(decision.incompleteTaskIds, ['GM-1', 'GM-2', 'GM-3']);
      for (final row in decision.breakdown) {
        expect(row.passAtK, 0.0);
        expect(row.detail, contains('no samples'));
      }
    });

    test('T5 (pin): a score exactly at the threshold passes (>=, not >)',
        () {
      // GM-1: pass@2 == 1.0 (n=4, c=4), GM-2: pass@2 == 0.0 (n=4, c=0),
      // GM-3: pass@2 == 0.5 (n=4, c=1 — C(3,2)/C(4,2) = 3/6)
      // → score = (1.0 + 0.0 + 0.5) / 3 = 0.5 == threshold.
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.5, k: 2),
        samples: const {
          'GM-1': TaskSamples(n: 4, c: 4),
          'GM-2': TaskSamples(n: 4, c: 0),
          'GM-3': TaskSamples(n: 4, c: 1),
        },
      );

      expect(decision.score, closeTo(0.5, 1e-9));
      expect(decision.passed, isTrue);
      expect(decision.exitCode, 0);
    });

    test('T6 (pin): per-task breakdown carries the unbiased pass@k value',
        () {
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.3, tasks: const ['GM-1'], k: 1),
        samples: const {'GM-1': TaskSamples(n: 10, c: 4)},
      );

      // Unbiased pass@1 with n=10, c=4: 1 - C(6,1)/C(10,1) = 1 - 6/10.
      expect(decision.breakdown.single.passAtK, closeTo(0.4, 1e-9));
      expect(decision.score, closeTo(0.4, 1e-9));
    });

    test('T7 (pin): sample ids the suite never declared are ignored', () {
      final decision = SuiteGate.evaluate(
        suite: suiteWith(gateThreshold: 0.5, tasks: const ['GM-1'], k: 1),
        samples: const {
          'GM-1': TaskSamples(n: 4, c: 4),
          'GM-UNKNOWN': TaskSamples(n: 100, c: 0), // not declared
        },
      );

      expect(decision.score, closeTo(1.0, 1e-9));
      expect(decision.passed, isTrue);
      expect(decision.incomplete, isFalse);
      expect(decision.breakdown.map((r) => r.taskId), ['GM-1']);
    });

    test('T8 (pin): c > n is a programming error, not an incomplete run',
        () {
      expect(
        () => SuiteGate.evaluate(
          suite: suiteWith(gateThreshold: 0.5, tasks: const ['GM-1']),
          samples: const {'GM-1': TaskSamples(n: 4, c: 5)},
        ),
        throwsArgumentError,
      );
    });
  });
}
