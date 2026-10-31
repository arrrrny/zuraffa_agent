// Coverage gate (issue #113): parses the lcov report produced by
//
//   rm -rf coverage
//   dart test --coverage=coverage
//   dart run coverage:format_coverage --lcov --in=coverage \
//     --out=coverage/lcov.info --report-on=lib
//
// and enforces a minimum line-coverage threshold. Exit codes:
//   0 — coverage at or above the threshold
//   1 — coverage below the threshold (the CI gate failure)
//   2 — usage error (missing/unreadable report, unparsable threshold,
//       malformed report record, or a report that measured no gated lines)
//
// The `rm -rf coverage` first line is not optional: `dart test
// --coverage=DIR` APPENDS to an existing DIR and `format_coverage --in=DIR`
// collects it recursively, so isolate data left by an earlier run would be
// merged into the number this gate checks (and can only ever raise it).
//
// Threshold policy (issue #113, "min-coverage: 80 after baseline
// measurement"): the gate enforces 80% over HAND-WRITTEN lib/ lines.
// Baseline (measured with the pinned 3.13.7 SDK when the gate landed):
//   hand-written lib/  86.32%  (7400/8573)  <- gated, floor 80
//   generated          18.55%  ( 598/3224)  <- reported, not gated
//   total lib/         67.80%  (7998/11797)
// This header is the ONE place the baseline is recorded — the workflow
// comments point here and at the previous run's `coverage-lcov` artifact
// instead of restating the numbers, because the tool prints live numbers on
// every run and a stale copy is worse than none.
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

/// Formats `hit/found` as a percentage, or `n/a` when the bucket is empty —
/// an empty bucket must never render as `NaN%`.
String _percent(int hit, int found) =>
    found == 0 ? 'n/a' : '${(hit * 100 / found).toStringAsFixed(2)}%';

/// A report record the gate cannot interpret. `main` maps it to the
/// documented usage-error exit code 2 instead of dying on a raw
/// `FormatException` — a truncated or hand-edited report is exactly when the
/// gate's message matters most.
final class CoverageParseException implements Exception {
  const CoverageParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parsed lcov totals, split into the gated (hand-written) and reported
/// (generated) buckets.
final class CoverageTotals {
  const CoverageTotals({
    required this.files,
    required this.generatedFiles,
    required this.linesFound,
    required this.linesHit,
    required this.handFound,
    required this.handHit,
  });

  /// Total `SF:` records in the report.
  final int files;

  /// `SF:` records whose path is committed build_runner output.
  final int generatedFiles;

  /// Total `LF:` (lines found) across every record.
  final int linesFound;

  /// Total `LH:` (lines hit) across every record.
  final int linesHit;

  /// `LF:` summed over hand-written records — the gated denominator.
  final int handFound;

  /// `LH:` summed over hand-written records — the gated numerator.
  final int handHit;

  int get handFiles => files - generatedFiles;
  int get generatedFound => linesFound - handFound;
  int get generatedHit => linesHit - handHit;

  /// Gated percentage. Only meaningful when [handFound] > 0, which `main`
  /// enforces before it is used: an unguarded `0/0` is `NaN`, and
  /// `NaN < threshold` is false, so a report that measured no hand-written
  /// lines would walk straight past the failure branch and exit 0.
  double get handPercent => handHit * 100 / handFound;
}

/// Scans an lcov report body. Pure over the text (no filesystem access), so
/// the gate's whole contract is unit-testable — see
/// `test/tool/check_coverage_test.dart`.
///
/// Throws [CoverageParseException] on a malformed `LF:`/`LH:` value and on a
/// `LF:`/`LH:` record that precedes the first `SF:` — the latter has no
/// owning file, and silently attributing it to the hand-written bucket is
/// how a mis-shaped report would skew the gated number.
CoverageTotals parseLcov(String contents) {
  var files = 0;
  var generatedFiles = 0;
  var linesFound = 0;
  var linesHit = 0;
  var handFound = 0;
  var handHit = 0;
  var currentIsGenerated = false;
  var sawFile = false;

  int recordValue(String line, String kind) {
    final raw = line.substring(3).trim();
    final value = int.tryParse(raw);
    if (value == null || value < 0) {
      throw CoverageParseException(
        'malformed $kind record: "$line" (expected a non-negative integer)',
      );
    }
    return value;
  }

  for (final line in contents.split('\n')) {
    if (line.startsWith('SF:')) {
      files++;
      sawFile = true;
      currentIsGenerated = _isGenerated(line.substring(3).trim());
      if (currentIsGenerated) generatedFiles++;
    } else if (line.startsWith('LF:')) {
      if (!sawFile) {
        throw const CoverageParseException(
          'LF: record before the first SF: record — it has no owning file',
        );
      }
      final value = recordValue(line, 'LF:');
      linesFound += value;
      if (!currentIsGenerated) handFound += value;
    } else if (line.startsWith('LH:')) {
      if (!sawFile) {
        throw const CoverageParseException(
          'LH: record before the first SF: record — it has no owning file',
        );
      }
      final value = recordValue(line, 'LH:');
      linesHit += value;
      if (!currentIsGenerated) handHit += value;
    }
  }

  return CoverageTotals(
    files: files,
    generatedFiles: generatedFiles,
    linesFound: linesFound,
    linesHit: linesHit,
    handFound: handFound,
    handHit: handHit,
  );
}

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
      '  rm -rf coverage\n'
      '  dart test --coverage=coverage\n'
      '  dart run coverage:format_coverage --lcov --in=coverage '
      '--out=coverage/lcov.info --report-on=lib\n'
      'first (issue #113 pipeline step order). The `rm -rf` is required: '
      '`dart test --coverage=DIR` appends to DIR.',
    );
    exit(2);
  }

  final String contents;
  try {
    contents = file.readAsStringSync();
  } on FileSystemException catch (e) {
    stderr.writeln('coverage gate: cannot read $lcovPath — ${e.message}');
    exit(2);
  }

  final CoverageTotals totals;
  try {
    totals = parseLcov(contents);
  } on CoverageParseException catch (e) {
    stderr.writeln('coverage gate: $lcovPath: ${e.message}');
    exit(2);
  }

  if (totals.files == 0 || totals.linesFound == 0) {
    stderr.writeln(
      'coverage gate: no coverage data in $lcovPath '
      '(files=${totals.files}, lines=${totals.linesFound}) — '
      'was --report-on=lib used?',
    );
    exit(2);
  }
  if (totals.handFound == 0) {
    stderr.writeln(
      'coverage gate: no hand-written lines in $lcovPath '
      '(${totals.generatedFiles} generated file(s), ${totals.files} total) — '
      'a gate that measured nothing must not pass (issue #113).',
    );
    exit(2);
  }

  final handPercent = totals.handPercent;
  stdout.writeln(
    'coverage gate: hand-written lib/ ${handPercent.toStringAsFixed(2)}% '
    '(${totals.handHit}/${totals.handFound} lines over '
    '${totals.handFiles} files) — '
    'minimum ${threshold.toStringAsFixed(0)}%',
  );
  stdout.writeln(
    'coverage gate: generated lib/ '
    '${_percent(totals.generatedHit, totals.generatedFound)} '
    '(${totals.generatedHit}/${totals.generatedFound} lines over '
    '${totals.generatedFiles} files) and total lib/ '
    '${_percent(totals.linesHit, totals.linesFound)} '
    '(${totals.linesHit}/${totals.linesFound}) — reported, not gated',
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
