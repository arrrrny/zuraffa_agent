// SuiteRunner for the eval harness (issue #115).
//
// Runs golden mission suites and collects pass@k and pass^k metrics.
// Each run replays the mission's cassette through the real engine loop
// (MissionReplayRunner) and grades the replayed summary.

import '../domain/entities/golden_mission/golden_mission.dart';
import '../domain/entities/pass_at_k/pass_at_k.dart';
import '../domain/entities/suite/suite.dart';
import 'mission_replay.dart';
import 'suite_gate.dart';

/// Result of running a single mission k times.
class MissionRunResult {
  const MissionRunResult({
    required this.missionId,
    required this.k,
    required this.outcomes,
    required this.passAtK,
    required this.passK,
  });

  /// The mission ID.
  final String missionId;

  /// The number of runs (k).
  final int k;

  /// The outcomes of each run (true = passed, false = failed).
  final List<bool> outcomes;

  /// The unbiased pass@k metric.
  final double passAtK;

  /// The empirical pass^k metric (fraction of runs that passed).
  final double passK;

  /// Number of correct runs.
  int get correctCount => outcomes.where((p) => p).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionRunResult &&
          runtimeType == other.runtimeType &&
          missionId == other.missionId &&
          k == other.k &&
          _listsEqual(outcomes, other.outcomes) &&
          passAtK == other.passAtK &&
          passK == other.passK);

  @override
  int get hashCode => Object.hash(
    missionId,
    k,
    Object.hashAll(outcomes),
    passAtK,
    passK,
  );

  @override
  String toString() =>
      'MissionRunResult($missionId, k: $k, pass@k: $passAtK, pass^k: $passK)';
}

/// Result of running an entire suite.
class SuiteRunResult {
  const SuiteRunResult({
    required this.suite,
    required this.missionResults,
    required this.decision,
    required this.passKByTask,
  });

  /// The suite that was run.
  final Suite suite;

  /// Results for each mission in the suite.
  final Map<String, MissionRunResult> missionResults;

  /// The gate decision (pass/fail, score, etc.).
  final GateDecision decision;

  /// Pass^k metric for each task (empirical fraction of passing runs).
  final Map<String, double> passKByTask;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuiteRunResult &&
          runtimeType == other.runtimeType &&
          suite == other.suite &&
          _mapsEqual(missionResults, other.missionResults) &&
          decision == other.decision &&
          _mapsEqual(passKByTask, other.passKByTask));

  @override
  int get hashCode => Object.hash(
    suite,
    Object.hashAllUnordered(missionResults.keys),
    decision,
    Object.hashAllUnordered(passKByTask.keys),
  );
}

/// Configuration for running a suite.
class SuiteRunnerConfig {
  const SuiteRunnerConfig({
    this.k = 2,
    this.maxTurns = 10,
    this.wallClockTimeoutMs = 60000,
    this.repetitionThreshold = 10,
  });

  /// The k parameter for pass@k and pass^k.
  final int k;

  /// Maximum turns per mission.
  final int maxTurns;

  /// Wall clock timeout in milliseconds.
  final int wallClockTimeoutMs;

  /// Repetition threshold for stopping.
  final int repetitionThreshold;
}

/// Runner for eval suites.
///
/// Runs golden missions from their cassettes through the real engine loop
/// ([MissionReplayRunner]) and grades each replayed summary with a
/// caller-supplied grader — every k sample is an independent replay of the
/// recorded corpus, so pass@k / pass^k see k real (deterministic) samples.
class SuiteRunner {
  const SuiteRunner();

  /// Runs [mission] k times, each run a fresh cassette replay, and returns
  /// the collected outcomes with pass@k / pass^k.
  ///
  /// [grader] receives the replayed summary and returns whether it passes.
  Future<MissionRunResult> runK(
    GoldenMission mission,
    int k, {
    required Future<bool> Function(String output) grader,
  }) async {
    final outcomes = <bool>[];
    for (var i = 0; i < k; i++) {
      final replay = MissionReplay(
        mission: mission,
        completions: _completionsOf(mission),
      );
      final result = await MissionReplayRunner.run(replay);
      final passed = result.completed && await grader(result.summary ?? '');
      outcomes.add(passed);
    }
    final passAtKValue = PassAtK.fromResults(outcomes, k: k).value;
    final passKValue = outcomes.where((p) => p).length / k;
    return MissionRunResult(
      missionId: mission.id,
      k: k,
      outcomes: List.unmodifiable(outcomes),
      passAtK: passAtKValue,
      passK: passKValue,
    );
  }

  /// Runs an entire suite: every task's mission replayed k times, graded,
  /// and fed through [SuiteGate.evaluate]. Throws [StateError] when a suite
  /// task has no cassette — a missing mission must fail loudly, never
  /// silently shrink the gate.
  Future<SuiteRunResult> runSuite(
    Suite suite, {
    required GoldenMission Function(String taskId) loadMission,
    required Future<bool> Function(String output, GoldenMission mission)
    resolveGrader,
  }) async {
    final missionResults = <String, MissionRunResult>{};
    final samples = <String, TaskSamples>{};
    final passKByTask = <String, double>{};

    for (final taskId in suite.tasks) {
      final mission = loadMission(taskId);
      final result = await runK(mission, suite.k, grader: (output) async {
        final verdict = await resolveGrader(output, mission);
        return verdict;
      });
      missionResults[taskId] = result;
      samples[taskId] = TaskSamples(
        n: result.k,
        c: result.correctCount,
      );
      passKByTask[taskId] = result.passK;
    }

    final decision = SuiteGate.evaluate(suite: suite, samples: samples);

    return SuiteRunResult(
      suite: suite,
      missionResults: Map.unmodifiable(missionResults),
      decision: decision,
      passKByTask: Map.unmodifiable(passKByTask),
    );
  }

  /// Runs a suite and returns the gate's exit code — the CI entry point.
  Future<int> runSuiteAndExit(
    Suite suite, {
    required GoldenMission Function(String taskId) loadMission,
    required Future<bool> Function(String output, GoldenMission mission)
    resolveGrader,
  }) async {
    final result = await runSuite(
      suite,
      loadMission: loadMission,
      resolveGrader: resolveGrader,
    );
    return result.decision.exitCode;
  }
}

List<Map<String, dynamic>> _completionsOf(GoldenMission mission) {
  final raw = mission.cassette['completions'];
  if (raw is! List || raw.isEmpty) {
    throw StateError(
      'SuiteRunner: mission ${mission.id} carries no recorded completions; '
      're-record the cassette before gating on it',
    );
  }
  return [
    for (final entry in raw)
      entry is Map<String, dynamic> ? entry : Map<String, dynamic>.from(entry as Map),
  ];
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
