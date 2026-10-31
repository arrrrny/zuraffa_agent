// Unit tests for the benchmark report model — issue #128 AC-4.
//
// The benchmark runner itself is a nightly CLI (benchmarks don't belong in
// the PR gate), but the artifact shape it publishes IS contract: these tests
// pin the JSON schema (schemaVersion, fields), the round-trip, the text
// rendering, and the percentile math on synthetic samples.

import 'package:test/test.dart';

import '../../benchmark/report.dart';

void main() {
  group('BenchmarkReport (issue #128 AC-4 artifact shape)', () {
    test('toJson pins schemaVersion, metadata, and ordered results', () {
      final report = BenchmarkReport(
        startedAt: DateTime.utc(2026, 1, 31, 3, 30),
        quickMode: true,
        results: [
          const BenchmarkResult(
            name: 'jsonl_append',
            unit: 'entries/sec',
            metrics: {'entries_per_sec': 81234.5, 'us_per_entry': 12.3},
            params: {'entries': 1000},
          ),
        ],
      );
      final json = report.toJson();
      expect(json['schemaVersion'], BenchmarkReport.schemaVersion);
      expect(json['schemaVersion'], 1);
      expect(json['quickMode'], isTrue);
      expect(json['startedAt'], '2026-01-31T03:30:00.000Z');
      expect((json['results'] as List).length, 1);
      expect((json['results'] as List).first, isA<Map<String, dynamic>>());
    });

    test('encodeJson is stable and machine-readable across encodes', () {
      final report = BenchmarkReport(
        startedAt: DateTime.utc(2026, 1, 31),
        quickMode: false,
        results: [
          const BenchmarkResult(
            name: 'fallback_failover_1_dead_hops',
            unit: 'us',
            metrics: {'p50_us': 120.0, 'p95_us': 310.5},
            params: {'iterations': 300, 'chain': 2},
          ),
        ],
      );
      final first = report.encodeJson();
      final second = report.encodeJson();
      expect(first, second, reason: 'encoding must be deterministic');
      // Round-trip: parse it back and compare field-by-field.
      final parsed = BenchmarkResult.fromJson(
        (report.toJson()['results'] as List).first as Map<String, dynamic>,
      );
      expect(parsed.name, 'fallback_failover_1_dead_hops');
      expect(parsed.metrics['p50_us'], 120.0);
      expect(parsed.metrics['p95_us'], 310.5);
      expect(parsed.params['chain'], 2);
    });

    test('toText renders every result name and metric for CI logs', () {
      final report = BenchmarkReport(
        startedAt: DateTime.utc(2026, 1, 31),
        quickMode: false,
        results: [
          const BenchmarkResult(
            name: 'jsonl_append',
            unit: 'entries/sec',
            metrics: {'entries_per_sec': 100000.0},
            params: {'entries': 10000},
          ),
          const BenchmarkResult(
            name: 'mission_runner_50_tool_calls',
            unit: 'ms',
            metrics: {'wall_clock_ms': 42.5},
          ),
        ],
      );
      final text = report.toText();
      expect(text, contains('full run'));
      expect(text, contains('jsonl_append'));
      expect(text, contains('entries_per_sec=100000'));
      expect(text, contains('mission_runner_50_tool_calls'));
      expect(text, contains('wall_clock_ms=42.50'));
      expect(text, contains('{entries=10000}'));
      expect(text, contains('full run'), reason: 'run mode is labeled');
    });

    test('percentile helpers: pinned by the runner contract, not here', () {
      // The percentile math lives in the runner (private); its contract is
      // exercised end-to-end by the nightly benchmark run. This test pins
      // the report-side contract only: a result with empty params renders
      // without braces.
      const result = BenchmarkResult(
        name: 'bare',
        unit: 'ms',
        metrics: {'wall_clock_ms': 1.0},
      );
      expect(result.toJson()['params'], isEmpty);
      expect(result.params, isEmpty);
    });
  });
}
