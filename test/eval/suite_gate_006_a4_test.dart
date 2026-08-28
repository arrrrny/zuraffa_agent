// Spec 006 — acceptance behavior A4: given a release gate of pass@k ≥
// threshold, when a suite scores below it, CI fails with a per-task breakdown.
//
// Both sides of the threshold boundary are exercised (a suite exactly at the
// threshold must PASS — `≥`, not `>`), and the failing case must carry a
// breakdown naming every task with its own pass@k and verdict, so a red CI run
// says which task regressed rather than just "gate failed".

import 'package:test/test.dart';
import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/eval/suite_gate.dart';

const kSuiteId = 'gm-suite';

Suite suiteWith({required double gateThreshold}) => Suite(
      id: kSuiteId,
      name: 'golden missions',
      tasks: const ['GM-1', 'GM-2'],
      k: 2,
      gateThreshold: gateThreshold,
    );

void main() {
  test('A4: a suite scoring below the gate threshold fails with a per-task '
      'breakdown', () {
    // GM-1: 4 samples, all correct  -> pass@2 == 1.0
    // GM-2: 4 samples, none correct -> pass@2 == 0.0
    // suite score = mean = 0.5, threshold 0.8 -> below.
    final decision = SuiteGate.evaluate(
      suite: suiteWith(gateThreshold: 0.8),
      samples: const {
        'GM-1': TaskSamples(n: 4, c: 4),
        'GM-2': TaskSamples(n: 4, c: 0),
      },
    );

    expect(decision.passed, isFalse);
    expect(decision.exitCode, 1, reason: 'a failing gate fails CI');
    expect(decision.score, closeTo(0.5, 1e-9));

    // Per-task breakdown: every task, its pass@k, and its own verdict.
    expect(decision.breakdown.map((t) => t.taskId), ['GM-1', 'GM-2']);
    expect(decision.breakdown.first.passAtK, closeTo(1.0, 1e-9));
    expect(decision.breakdown.first.passed, isTrue);
    expect(decision.breakdown.last.passAtK, closeTo(0.0, 1e-9));
    expect(decision.breakdown.last.passed, isFalse);

    // The report a CI log shows names the offending task and the numbers.
    expect(decision.report, contains('GM-2'));
    expect(decision.report, contains('0.80'));
    expect(decision.report, contains('FAIL'));
  });

  test('A4: a suite exactly at the gate threshold passes (>=, not >)', () {
    // GM-1: pass@2 == 1.0, GM-2: pass@2 == 0.0 -> score 0.5 == threshold.
    final decision = SuiteGate.evaluate(
      suite: suiteWith(gateThreshold: 0.5),
      samples: const {
        'GM-1': TaskSamples(n: 4, c: 4),
        'GM-2': TaskSamples(n: 4, c: 0),
      },
    );

    expect(decision.passed, isTrue);
    expect(decision.exitCode, 0);
    expect(decision.score, closeTo(0.5, 1e-9));
  });

  test('A4: a task with no samples fails the gate loudly instead of being '
      'skipped', () {
    final decision = SuiteGate.evaluate(
      suite: suiteWith(gateThreshold: 0.5),
      samples: const {'GM-1': TaskSamples(n: 4, c: 4)},
    );

    expect(decision.passed, isFalse);
    expect(decision.breakdown.last.taskId, 'GM-2');
    expect(decision.breakdown.last.passAtK, 0.0);
    expect(decision.report, contains('no samples'));
  });
}
