// Coverage gate contract — issue #113.
//
// `tool/check_coverage.dart` is the only thing standing between a coverage
// regression and a green PR, so its five counters are tested here: which
// lines are gated, which are only reported, and what happens at the
// boundary. Two real defects found in review (arrrrny/zuraffa_agent#174)
// are pinned as regression tests:
//
//   1. a report holding only generated records used to compute `0/0 == NaN`
//      and exit 0 — a gate that measured nothing must never pass;
//   2. a malformed `LF:`/`LH:` value used to escape as a raw
//      `FormatException` instead of the documented usage-error exit 2.
//
// The scan loop is pure over the report text, so every case here is a string
// fixture — no coverage run, no filesystem, no SDK dependency.

import 'package:test/test.dart';

import '../../tool/check_coverage.dart'
    show CoverageParseException, CoverageTotals, parseLcov;

/// An lcov record for one file. `FN:`/`DA:` lines are omitted: the gate
/// only reads `SF:`/`LF:`/`LH:`, so the fixtures stay minimal.
String record(String path, {required int found, required int hit}) =>
    'SF:$path\n'
    'LF:$found\n'
    'LH:$hit\n'
    'end_of_record\n';

void main() {
  group('parseLcov buckets', () {
    test('hand-written and generated records land in separate buckets', () {
      final totals = parseLcov(
        record('lib/engine/loop.dart', found: 100, hit: 90) +
            record('lib/engine/loop.g.dart', found: 50, hit: 5) +
            record('lib/domain/mission.zorphy.dart', found: 25, hit: 0),
      );

      expect(totals.files, 3);
      expect(totals.generatedFiles, 2);
      expect(totals.handFiles, 1);
      expect(totals.linesFound, 175);
      expect(totals.linesHit, 95);
      // Only the plain .dart file is gated.
      expect(totals.handFound, 100);
      expect(totals.handHit, 90);
      expect(totals.generatedFound, 75);
      expect(totals.generatedHit, 5);
      expect(totals.handPercent, closeTo(90.0, 1e-9));
    });

    test('a report with only generated records gates nothing', () {
      final totals = parseLcov(
        record('lib/a.g.dart', found: 100, hit: 10) +
            record('lib/b.zorphy.dart', found: 50, hit: 0),
      );

      // The shape that used to print `NaN%` and exit 0: main() must refuse
      // it (handFound == 0 -> exit 2), which is asserted here as the
      // parser-level precondition.
      expect(totals.files, 2);
      expect(totals.generatedFiles, 2);
      expect(totals.handFound, 0);
      expect(totals.handHit, 0);
      expect(totals.linesFound, 150);
    });

    test('an empty report parses to zero totals', () {
      final totals = parseLcov('');
      expect(totals.files, 0);
      expect(totals.linesFound, 0);
      expect(totals.handFound, 0);
    });

    test('LF/LH without a preceding SF is rejected, not mis-bucketed', () {
      expect(
        () => parseLcov('LF:10\nLH:5\nend_of_record\n'),
        throwsA(isA<CoverageParseException>()),
      );
    });
  });

  group('parseLcov malformed records', () {
    test('a non-numeric LF value raises the usage error', () {
      expect(
        () => parseLcov(
          record(
            'lib/a.dart',
            found: 10,
            hit: 5,
          ).replaceFirst('LF:10', 'LF:oops'),
        ),
        throwsA(
          isA<CoverageParseException>().having(
            (e) => e.message,
            'message',
            allOf(contains('malformed LF:'), contains('LF:oops')),
          ),
        ),
      );
    });

    test('a non-numeric LH value raises the usage error', () {
      expect(
        () => parseLcov(
          record(
            'lib/a.dart',
            found: 10,
            hit: 5,
          ).replaceFirst('LH:5', 'LH:five'),
        ),
        throwsA(isA<CoverageParseException>()),
      );
    });

    test('a negative value raises the usage error', () {
      expect(
        () => parseLcov(
          record(
            'lib/a.dart',
            found: 10,
            hit: 5,
          ).replaceFirst('LF:10', 'LF:-3'),
        ),
        throwsA(isA<CoverageParseException>()),
      );
    });

    test('an empty value raises the usage error', () {
      expect(
        () => parseLcov(
          record('lib/a.dart', found: 10, hit: 5).replaceFirst('LH:5', 'LH:'),
        ),
        throwsA(isA<CoverageParseException>()),
      );
    });
  });

  group('threshold boundary', () {
    // Mirrors the comparison in main(): `handPercent + 1e-9 < threshold`.
    bool passes(CoverageTotals totals, double threshold) =>
        !(totals.handPercent + 1e-9 < threshold);

    test('exactly at the threshold passes', () {
      final totals = parseLcov(record('lib/a.dart', found: 100, hit: 80));
      expect(totals.handPercent, closeTo(80.0, 1e-9));
      expect(passes(totals, 80.0), isTrue);
    });

    test('a hair under the threshold fails', () {
      // 7999/10000 = 79.99% — one line short of the 80% floor.
      final totals = parseLcov(record('lib/a.dart', found: 10000, hit: 7999));
      expect(passes(totals, 80.0), isFalse);
    });

    test('just above the threshold passes', () {
      final totals = parseLcov(record('lib/a.dart', found: 10000, hit: 8001));
      expect(passes(totals, 80.0), isTrue);
    });

    test('a generated-only report never reaches the comparison', () {
      // The old fail-open: `0/0 == NaN`, and `NaN + 1e-9 < 80` is false, so
      // the gate walked past the failure branch and exited 0. main() now
      // exits 2 on this shape before any percentage is computed — the guard
      // is the contract, so it is what this test pins.
      final totals = parseLcov(record('lib/a.g.dart', found: 10, hit: 1));
      expect(
        totals.handFound,
        0,
        reason:
            'main() treats handFound == 0 as a usage error (exit 2), '
            'so the NaN comparison is unreachable',
      );
    });
  });
}
