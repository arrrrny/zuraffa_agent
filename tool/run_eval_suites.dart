// Eval suite release gate (issue #115).
//
// CLI entry point that runs golden-mission suites as a release gate. Owns
// the file-I/O boundary (the lib/ eval runtime stays dart:io-free, FR-005):
// it reads suite YAML files from eval/suites/ and mission cassettes from
// eval/cassettes/, feeds the text through the pure SuiteLoader /
// MissionReplay parsers, replays every mission through the real engine loop
// (CassetteReplayLlmClient → EngineLoopExecutor → MissionRunner), grades the
// replays, and evaluates the SuiteGate on the real results.
//
// Usage:
//   dart run tool/run_eval_suites.dart [suite-id]
//
// If suite-id is provided, only that suite runs; otherwise all suites run.
// A suite file or cassette that fails to parse FAILS the gate (non-zero
// exit) — a corrupt corpus must never silently shrink the gate.
//
// Exit codes: 0 gate passed, 1 gate failed, 2 setup error.

import 'dart:convert';
import 'dart:io';

import 'package:zuraffa_agent/src/domain/entities/suite/suite.dart';
import 'package:zuraffa_agent/src/eval/graders/exact_match_grader.dart';
import 'package:zuraffa_agent/src/eval/graders/grader.dart';
import 'package:zuraffa_agent/src/eval/mission_replay.dart';
import 'package:zuraffa_agent/src/eval/suite_gate.dart';
import 'package:zuraffa_agent/src/eval/suite_loader.dart';

const _exitSuccess = 0;
const _exitFailure = 1;
const _exitError = 2;

Future<void> main(List<String> args) async {
  try {
    // Replay is deterministic: no LLM_API_KEY is needed. The key would only
    // matter for a live-model run, which replay never falls through to.
    final suiteId = args.isNotEmpty ? args.first : null;

    // ---- I/O boundary: read every suite file and cassette from disk ----
    final suiteDir = Directory('eval/suites');
    if (!suiteDir.existsSync()) {
      stderr.writeln('No eval/suites directory found.');
      exit(_exitError);
    }
    final yamlBySource = <String, String>{};
    for (final entity in suiteDir.listSync()) {
      if (entity is File && entity.path.endsWith('.yaml')) {
        yamlBySource[entity.path] = entity.readAsStringSync();
      }
    }
    if (yamlBySource.isEmpty) {
      stderr.writeln('No suite files found in eval/suites/.');
      exit(_exitError);
    }

    final catalog = const SuiteLoader().loadAll(yamlBySource);
    for (final failure in catalog.failures) {
      stderr.writeln('Suite load FAILED: $failure');
    }
    if (catalog.failures.isNotEmpty) {
      // A corrupt suite file must fail the gate, not shrink it.
      stderr.writeln(
        'Failing the gate: ${catalog.failures.length} suite '
        'file(s) failed to load.',
      );
      exit(_exitFailure);
    }

    final suites = catalog.suites;
    Suite? requested;
    if (suiteId != null) {
      requested = suites[suiteId];
      if (requested == null) {
        stderr.writeln('Suite "$suiteId" not found.');
        exit(_exitError);
      }
    }
    final suitesToRun = requested != null
        ? <String, Suite>{requested.id: requested}
        : suites;

    // Load the cassette corpus up front: a corrupt or missing cassette for
    // any declared task fails the gate loudly.
    final cassetteDir = Directory('eval/cassettes');
    final replays = <String, MissionReplay>{};
    if (cassetteDir.existsSync()) {
      for (final entity in cassetteDir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final doc = (jsonDecode(entity.readAsStringSync()) as Map)
              .cast<String, dynamic>();
          final replay = MissionReplay.fromJson(doc);
          replays[replay.mission.id] = replay;
        } catch (e) {
          stderr.writeln('Cassette load FAILED for ${entity.path}: $e');
          exit(_exitFailure);
        }
      }
    }

    var overallExitCode = _exitSuccess;
    for (final suiteEntry in suitesToRun.entries) {
      final suite = suiteEntry.value;
      stdout.writeln(
        '\n=== Suite ${suite.id} (${suite.name}) — '
        'k=${suite.k}, threshold=${suite.gateThreshold} ===',
      );

      // Cross-check: every task the suite declares must have a cassette.
      final missing = suite.tasks
          .where((t) => !replays.containsKey(t))
          .toList();
      if (missing.isNotEmpty) {
        stderr.writeln(
          'Suite ${suite.id}: missing cassettes for tasks: '
          '$missing — failing the gate.',
        );
        overallExitCode = _exitFailure;
        continue;
      }

      final samples = <String, TaskSamples>{};
      for (final taskId in suite.tasks) {
        final replay = replays[taskId]!;
        final passed = await _replayAndGrade(replay);
        samples[taskId] = TaskSamples(n: 1, c: passed ? 1 : 0);
        stdout.writeln('  $taskId: ${passed ? 'PASS' : 'FAIL'}');
      }

      final decision = SuiteGate.evaluate(suite: suite, samples: samples);
      stdout.writeln(decision.report);
      if (!decision.passed) {
        overallExitCode = _exitFailure;
      }
    }

    stdout.writeln('\n=== Eval suites complete — exit $overallExitCode ===');
    exit(overallExitCode);
  } catch (e, stackTrace) {
    stderr.writeln('Error running eval suites: $e');
    stderr.writeln(stackTrace.toString());
    exit(_exitError);
  }
}

/// Replays one mission from its cassette and grades the summary.
///
/// The corpus pins no separate "expected" field: the cassette's recorded
/// final completion IS the pinned ground truth, so replaying the cassette
/// through the real engine loop must reproduce it byte-for-byte. The exact
/// graders resolve the mission's `graderBindings` (every committed cassette
/// binds `exact`); an unresolvable binding fails the task loudly.
Future<bool> _replayAndGrade(MissionReplay replay) async {
  final mission = replay.mission;
  final expected = replay.completions.last['content'];
  if (expected is! String || expected.isEmpty) {
    stderr.writeln('${mission.id}: cassette pins no final content to grade');
    return false;
  }
  final graders = <Grader>[
    for (final binding in mission.graderBindings)
      _resolveGrader(binding, expected),
  ];
  if (graders.isEmpty) {
    stderr.writeln('${mission.id}: no grader bindings');
    return false;
  }
  try {
    final result = await MissionReplayRunner.run(replay);
    if (!result.completed) {
      stderr.writeln(
        '${mission.id}: replay did not complete '
        '(status summary: ${result.summary?.trim() ?? '<none>'})',
      );
      return false;
    }
    for (final grader in graders) {
      final verdict = await grader.grade(result.summary ?? '');
      if (!verdict.passed) {
        stderr.writeln('${mission.id}: ${grader.id}: ${verdict.reason}');
        return false;
      }
    }
    return true;
  } catch (e) {
    stderr.writeln('$mission.id: replay threw: $e');
    return false;
  }
}

Grader _resolveGrader(String binding, String expected) {
  if (binding == 'exact' || binding == 'exact-match') {
    return ExactMatchGrader(expected: expected);
  }
  throw StateError(
    'no CLI grader for binding "$binding" — register it in run_eval_suites',
  );
}
