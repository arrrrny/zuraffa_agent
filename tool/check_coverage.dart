// Coverage gate (issue #113): parses the lcov report produced by
//
//   dart test --coverage=coverage
//   dart run coverage:format_coverage --lcov --in=coverage \
//     --out=coverage/lcov.info --report-on=lib
//
// and enforces a minimum line-coverage threshold. Exit codes:
//   0 — coverage at or above the threshold
//   1 — coverage below the threshold (the CI gate failure)
//   2 — usage error (missing/unreadable report, unparsable threshold)
//
// Threshold policy (issue #113, "min-coverage: 80 after baseline
// measurement"): the gate enforces 80% over HAND-WRITTEN lib/ lines.
// Baseline (measured with the pinned 3.13.7 SDK when the gate landed):
//   hand-written lib/  86.32%  (7400/8573)  <- gated, floor 80
//   generated          18.55%  ( 598/3224)  <- reported, not gated
//   total lib/         67.80%  (7998/11797)
// The generated set is the committed build_runner output (*.g.dart,
// *.zorphy.dart) — the repo's own rule is to never hand-edit generated
// files, so their JSON serialization boilerplate is reported for visibility
// but does not gate. Raise the threshold deliberately; never lower it to
// make a red run green.

import 'dart:io';

/// Minimum line coverage over hand-written lib/ lines (percent). Matches
/// the issue #113 acceptance criterion: min-coverage 80.
const double defaultMinCoverage = 80.0;

bool _isGenerated(String sfPath) =>
    sfPath.endsWith('.g.dart') || sfPath.endsWith('.zorphy.dart');

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final thresholdArg = args.length > 1 ? args[1] : null;

  final double threshold;
  if (thresholdArg == null) {
    threshold = defaultMinCoverage;
  } else {
    final parsed = double.tryParse(thresholdArg);
    if (parsed == null || parsed < 0 || parsed > 100) {
      stderr.writeln(
        'coverage gate: threshold must be a number in [0, 100], '
        'got "$thresholdArg"',
      );
      exit(2);
    }
    threshold = parsed;
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage gate: $lcovPath not found — run\n'
      '  dart test --coverage=coverage\n'
      '  dart run coverage:format_coverage --lcov --in=coverage '
      '--out=coverage/lcov.info --report-on=lib\n'
      'first (issue #113 pipeline step order).',
    );
    exit(2);
  }

  var files = 0;
  var generatedFiles = 0;
  var linesFound = 0;
  var linesHit = 0;
  var handFound = 0;
  var handHit = 0;
  var currentIsGenerated = false;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      files++;
      currentIsGenerated = _isGenerated(line.substring(3).trim());
      if (currentIsGenerated) generatedFiles++;
    } else if (line.startsWith('LF:')) {
      final value = int.parse(line.substring(3).trim());
      linesFound += value;
      if (!currentIsGenerated) handFound += value;
    } else if (line.startsWith('LH:')) {
      final value = int.parse(line.substring(3).trim());
      linesHit += value;
      if (!currentIsGenerated) handHit += value;
    }
  }
  if (files == 0 || linesFound == 0) {
    stderr.writeln(
      'coverage gate: no coverage data in $lcovPath '
      '(files=$files, lines=$linesFound) — was --report-on=lib used?',
    );
    exit(2);
  }

  final handPercent = handHit * 100 / handFound;
  stdout.writeln(
    'coverage gate: hand-written lib/ ${handPercent.toStringAsFixed(2)}% '
    '($handHit/$handFound lines over ${files - generatedFiles} files) — '
    'minimum ${threshold.toStringAsFixed(0)}%',
  );
  stdout.writeln(
    'coverage gate: generated lib/ '
    '${((linesHit - handHit) * 100 / (linesFound - handFound)).toStringAsFixed(2)}% '
    '(${linesHit - handHit}/${linesFound - handFound} lines over '
    '$generatedFiles files) and total lib/ '
    '${(linesHit * 100 / linesFound).toStringAsFixed(2)}% '
    '($linesHit/$linesFound) — reported, not gated',
  );
  if (handPercent + 1e-9 < threshold) {
    stderr.writeln(
      '::error::coverage gate FAILED: hand-written lib/ coverage '
      '${handPercent.toStringAsFixed(2)}% < $threshold% minimum (issue '
      '#113). Add tests for the uncovered lib/ code — do not lower the '
      'gate.',
    );
    exit(1);
  }
}
