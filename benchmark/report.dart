// benchmark/report.dart — pure report model for the benchmark runner.
//
// Issue #128 AC-4: the load benchmarks publish their numbers as artifacts.
// This model is the artifact's shape — a BenchmarkReport serializes to
// stable, machine-readable JSON (schemaVersion pinned so consumers can rely
// on it) and renders a human-readable text table. Kept dependency-free and
// synchronous so it is trivially unit-testable (test/benchmark/report_test.dart);
// the runner (benchmark_runner.dart) only measures and feeds it.

import 'dart:convert';

/// One measured benchmark: a name, the metric unit, the metrics map
/// (e.g. `{entries_per_sec: 81234, p50_append_us: 12.3}`), and the
/// parameters the measurement ran under (e.g. `{"entries": 10000}`).
class BenchmarkResult {
  final String name;
  final String unit;
  final Map<String, double> metrics;
  final Map<String, Object> params;

  const BenchmarkResult({
    required this.name,
    required this.unit,
    required this.metrics,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'metrics': metrics,
    'params': params,
  };

  static BenchmarkResult fromJson(Map<String, dynamic> json) => BenchmarkResult(
    name: json['name'] as String,
    unit: json['unit'] as String,
    metrics: {
      for (final entry in (json['metrics'] as Map).entries)
        entry.key as String: (entry.value as num).toDouble(),
    },
    params: {
      for (final entry in (json['params'] as Map).entries)
        entry.key as String: entry.value as Object,
    },
  );
}

/// The full benchmark run: results in execution order plus run metadata.
class BenchmarkReport {
  /// Bump when the JSON shape changes in a breaking way.
  static const int schemaVersion = 1;

  final DateTime startedAt;
  final bool quickMode;
  final List<BenchmarkResult> results;

  const BenchmarkReport({
    required this.startedAt,
    required this.quickMode,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'quickMode': quickMode,
    'results': [for (final r in results) r.toJson()],
  };

  /// Machine-readable artifact body (dart:convert — insertion-ordered maps
  /// keep the output stable across runs with identical inputs).
  String encodeJson() => jsonEncode(toJson());

  /// Human-readable table for CI logs.
  String toText() {
    final buffer = StringBuffer()
      ..writeln(
        'zuraffa_agent benchmarks — ${quickMode ? "QUICK" : "full"} run '
        'at ${startedAt.toUtc().toIso8601String()}',
      );
    for (final r in results) {
      buffer.writeln(
        '  ${r.name.padRight(46)} ${_formatMetrics(r.metrics)} '
        '${r.unit}${_formatParams(r.params)}',
      );
    }
    return buffer.toString();
  }

  static String _formatMetrics(Map<String, double> metrics) =>
      metrics.entries.map((e) => '${e.key}=${_num(e.value)}').join(', ');

  static String _formatParams(Map<String, Object> params) => params.isEmpty
      ? ''
      : ' {${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}}';

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
