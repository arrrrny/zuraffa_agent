// SuiteRunner for the eval harness (issue #115).
//
// Runs golden mission suites and collects pass@k and pass^k metrics.
// Integrates with CassetteReplayLlmClient to replay recorded missions
// deterministically, and with GraderRegistry to evaluate mission outputs.

import '../domain/entities/golden_mission/golden_mission.dart';
import '../domain/entities/pass_at_k/pass_at_k.dart';
import '../domain/entities/suite/suite.dart';
import '../engine/mission_runner.dart';
import '../engine/tool_dispatcher.dart';
import 'cassette_replay_llm_client.dart';
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
          outcomes == other.outcomes &&
          passAtK == other.passAtK &&
          passK == other.passK);

  @override
  int get hashCode => Object.hash(missionId, k, outcomes, passAtK, passK);

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
          missionResults == other.missionResults &&
          decision == other.decision &&
          passKByTask == other.passKByTask);

  @override
  int get hashCode =>
      Object.hash(suite, missionResults, decision, passKByTask);
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
/// Runs golden missions using cassette replay and evaluates them with
/// registered graders. Collects both pass@k (unbiased estimator) and
/// pass^k (empirical) metrics.
class SuiteRunner {
  final MissionRunner _missionRunner;
  final ToolDispatcher _toolDispatcher;
  final SuiteRunnerConfig _config;

  SuiteRunner({
    required MissionRunner missionRunner,
    required ToolDispatcher toolDispatcher,
    SuiteRunnerConfig config = const SuiteRunnerConfig(),
  })  : _missionRunner = missionRunner,
        _toolDispatcher = toolDispatcher,
        _config = config;

  /// Runs [mission] k times and returns the result.
  ///
  /// Each run uses the cassette from [mission] to replay deterministically.
  /// The mission output is graded using the graders specified in
  /// [mission.graderBindings].
  ///
  /// [grader] is a function that takes the mission output and returns whether
  /// it passed. This is typically resolved from the mission's grader bindings.
  Future<MissionRunResult> runK(
    GoldenMission mission,
    int k, {
      required Future<bool> Function(String output) grader,
    }) async {
    final outcomes = <bool>[];

    for (var i = 0; i < k; i++) {
      final client = CassetteReplayLlmClient.fromGoldenMission(mission);

      final result = await _missionRunner.run(
        missionId: mission.id,
        messages: const [],
      );

      final output = result.summary ?? '';
      final passed = await grader(output);
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

  /// Runs an entire suite and returns the result.
  ///
  /// For each task in the suite, loads the corresponding golden mission,
  /// runs it k times, and collects the results. Then evaluates the suite
  /// gate and returns the complete result.
  ///
  /// [loadMission] is a function that loads a GoldenMission by its task ID.
  /// [resolveGrader] is a function that resolves a grader for a mission's
  /// grader bindings.
  Future<SuiteRunResult> runSuite(
    Suite suite, {
      required GoldenMission Function(String taskId) loadMission,
      required Future<bool> Function(String output, GoldenMission mission) resolveGrader,
    }) async {
    final missionResults = <String, MissionRunResult>{};
    final samples = <String, TaskSamples>{};
    final passKByTask = <String, double>{};

    for (final taskId in suite.tasks) {
      final mission = loadMission(taskId);
      final result = await runK(
        mission,
        suite.k,
        grader: (output) => resolveGrader(output, mission),
      );

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

  /// Runs a suite and returns the exit code from the gate decision.
  ///
  /// This is the entry point for CI integration. Returns the exit code
  /// that should be used to exit the CI job (0 for pass, 1 for fail).
  Future<int> runSuiteAndExit(
    Suite suite, {
      required GoldenMission Function(String taskId) loadMission,
      required Future<bool> Function(String output, GoldenMission mission) resolveGrader,
    }) async {
    final result = await runSuite(
      suite,
      loadMission: loadMission,
      resolveGrader: resolveGrader,
    );
    return result.decision.exitCode;
  }
}
