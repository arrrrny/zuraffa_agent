// Release gate for the eval harness (spec 006 FR-002 / AC-2).
//
// Turns a suite's per-task sample counts into a CI verdict: pass@k per task
// (Chen et al. unbiased estimator, via the PassAtK value object), the suite
// score, a pass/fail decision against the suite's `gateThreshold`, and a
// per-task breakdown so a red CI run names the task that regressed.
//
// Pure Dart, no dart:io (FR-005: the eval runtime is dart:io-free). The exit
// code is returned as a value; whoever owns the process decides what to do with
// it.

import '../domain/entities/pass_at_k/pass_at_k.dart';
import '../domain/entities/suite/suite.dart';

/// Sample counts observed for one task: [n] runs of which [c] were correct.
class TaskSamples {
  const TaskSamples({required this.n, required this.c});

  /// Total samples drawn for the task.
  final int n;

  /// Correct samples (`c <= n`).
  final int c;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskSamples &&
          runtimeType == other.runtimeType &&
          n == other.n &&
          c == other.c);

  @override
  int get hashCode => Object.hash(n, c);

  @override
  String toString() => 'TaskSamples(n: $n, c: $c)';
}

/// One row of a gate decision's breakdown.
class TaskGateResult {
  const TaskGateResult({
    required this.taskId,
    required this.passAtK,
    required this.passed,
    required this.detail,
  });

  /// The task this row scores.
  final String taskId;

  /// The task's unbiased pass@k value (0.0 when it had no samples).
  final double passAtK;

  /// Whether this task cleared the suite's threshold on its own.
  final bool passed;

  /// Human-readable note — the sample counts, or why the task scored 0.
  final String detail;

  @override
  String toString() =>
      'TaskGateResult($taskId, pass@k: $passAtK, passed: $passed)';
}

/// The verdict for one suite run.
class GateDecision {
  const GateDecision({
    required this.suiteId,
    required this.score,
    required this.threshold,
    required this.passed,
    required this.breakdown,
    required this.report,
  });

  /// The suite that was gated.
  final String suiteId;

  /// The suite score: the mean of the per-task pass@k values.
  final double score;

  /// The threshold the score was compared against.
  final double threshold;

  /// True when `score >= threshold` — `≥`, so a suite exactly at the threshold
  /// ships.
  final bool passed;

  /// One row per task in the suite, in the suite's declared task order.
  final List<TaskGateResult> breakdown;

  /// The CI-log rendering: the verdict line followed by the per-task breakdown.
  final String report;

  /// The process exit code a CI runner should use: 0 on pass, 1 on fail.
  int get exitCode => passed ? 0 : 1;
}

/// Evaluates a suite's release gate.
class SuiteGate {
  const SuiteGate._();

  /// Scores [suite] against [samples] and returns the gate decision.
  ///
  /// Every task declared by the suite appears in the breakdown. A task with no
  /// entry in [samples] scores 0.0 and is reported as such: a missing task is a
  /// gate failure, never a silent skip, because skipping it would let a suite
  /// pass by not running its hardest mission.
  static GateDecision evaluate({
    required Suite suite,
    required Map<String, TaskSamples> samples,
  }) {
    final rows = <TaskGateResult>[];
    for (final taskId in suite.tasks) {
      final s = samples[taskId];
      if (s == null) {
        rows.add(TaskGateResult(
          taskId: taskId,
          passAtK: 0.0,
          passed: false,
          detail: 'no samples recorded',
        ));
        continue;
      }
      final k = suite.k <= s.n ? suite.k : s.n;
      final value = PassAtK.compute(n: s.n, c: s.c, k: k).value;
      rows.add(TaskGateResult(
        taskId: taskId,
        passAtK: value,
        passed: value >= suite.gateThreshold,
        detail: 'n=${s.n} c=${s.c} k=$k',
      ));
    }

    final score = rows.isEmpty
        ? 0.0
        : rows.map((r) => r.passAtK).reduce((a, b) => a + b) / rows.length;
    // An incomplete run cannot pass. A task with no samples was not evaluated,
    // and scoring it 0.0 into the mean is not enough on its own: a suite of
    // easy tasks could still clear the threshold while its hardest mission was
    // never run. Missing samples therefore veto the gate outright.
    final incomplete = suite.tasks.any((t) => !samples.containsKey(t));
    final passed = score >= suite.gateThreshold && !incomplete;

    final lines = <String>[
      '${passed ? 'PASS' : 'FAIL'} suite ${suite.id}: '
          'pass@${suite.k} ${score.toStringAsFixed(2)} '
          '${passed ? '>=' : '<'} threshold '
          '${suite.gateThreshold.toStringAsFixed(2)}',
      for (final r in rows)
        '  ${r.passed ? 'PASS' : 'FAIL'} ${r.taskId}: '
            '${r.passAtK.toStringAsFixed(2)} (${r.detail})',
    ];

    return GateDecision(
      suiteId: suite.id,
      score: score,
      threshold: suite.gateThreshold,
      passed: passed,
      breakdown: List.unmodifiable(rows),
      report: lines.join('\n'),
    );
  }
}
