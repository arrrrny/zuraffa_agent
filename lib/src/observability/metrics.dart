// Observability seam (issue #133, O-2) — metrics.
//
// `Metrics` is the exporter seam the issue calls for: `counter(name)`,
// `histogram(name, value)`, `gauge(name, value)`. The default is a no-op;
// consumers inject a Prometheus or OTLP-backed implementation, or the
// in-memory one for tests and local dashboards.
//
// Engine wiring (all optional — nothing is recorded unless injected):
//   - `agent_llm_tokens_total{type=input|output}` — per-turn token usage
//     (MissionRunner, from each completion's TokenUsage)
//   - `agent_mission_duration_ms{status=<terminal>}` — mission latency
//     histogram (MissionRunner, on every terminal status)
//   - `agent_tool_calls_failed_total` — failed tool dispatches, including
//     thrown dispatches and failed results inside dispatchBatch
//     (TracedToolDispatcher)
//   - `agent_circuit_breaker_state{provider=<id>}` — breaker gauges
//     (CircuitBreaker: closed=0, half-open=1, open=2)

/// A monotonically increasing counter handle created by
/// [Metrics.counter]. Labels are fixed at creation; [inc] only adds.
abstract interface class Counter {
  String get name;

  /// Adds [amount] (default 1) to the counter.
  void inc([num amount, Map<String, String>? labels]);
}

/// The metrics seam. Shapes match issue #133: `counter(name)`,
/// `histogram(name, value)`, `gauge(name, value)`. Label sets are optional
/// and always rendered as a sorted `{k=v,...}` suffix.
abstract interface class Metrics {
  /// Returns (or creates) a counter handle for [name].
  Counter counter(String name, {Map<String, String>? labels});

  /// Records one observation of [value] on the histogram [name].
  void histogram(String name, num value, {Map<String, String>? labels});

  /// Sets the current value of gauge [name].
  void gauge(String name, num value, {Map<String, String>? labels});
}

/// Renders `name` plus an optional label map into the canonical series key
/// (`name` or `name{k1=v1,k2=v2}` with keys sorted).
String metricsKey(String name, Map<String, String>? labels) {
  if (labels == null || labels.isEmpty) return name;
  final sorted = labels.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return '$name{${sorted.map((e) => '${e.key}=${e.value}').join(',')}}';
}

/// The default implementation — accepts every record and drops it.
class NoopMetrics implements Metrics {
  const NoopMetrics();

  static const NoopMetrics instance = NoopMetrics();

  @override
  Counter counter(String name, {Map<String, String>? labels}) =>
      const _NoopCounter();

  @override
  void histogram(String name, num value, {Map<String, String>? labels}) {}

  @override
  void gauge(String name, num value, {Map<String, String>? labels}) {}
}

final class _NoopCounter implements Counter {
  const _NoopCounter();

  @override
  String get name => '';

  @override
  void inc([num amount = 1, Map<String, String>? labels]) {}
}

/// In-memory [Metrics] for tests, local dashboards, and as the reference
/// shape a Prometheus/OTLP exporter must fill.
///
/// - `counters` — cumulative value per series key.
/// - `histograms` — every observation per series key, in order.
/// - `gauges` — the latest value per series key.
class InMemoryMetrics implements Metrics {
  /// Cumulative counter values keyed by series key.
  final Map<String, double> counters = {};

  /// Recorded histogram observations keyed by series key.
  final Map<String, List<double>> histograms = {};

  /// Latest gauge values keyed by series key.
  final Map<String, double> gauges = {};

  @override
  Counter counter(String name, {Map<String, String>? labels}) =>
      _InMemoryCounter(this, metricsKey(name, labels));

  @override
  void histogram(String name, num value, {Map<String, String>? labels}) {
    histograms
        .putIfAbsent(metricsKey(name, labels), () => [])
        .add(value.toDouble());
  }

  @override
  void gauge(String name, num value, {Map<String, String>? labels}) {
    gauges[metricsKey(name, labels)] = value.toDouble();
  }
}

final class _InMemoryCounter implements Counter {
  _InMemoryCounter(this._metrics, this.name);

  final InMemoryMetrics _metrics;

  @override
  final String name;

  @override
  void inc([num amount = 1, Map<String, String>? labels]) {
    // Labels are fixed at creation; per-inc labels would fork the series.
    _metrics.counters[name] =
        (_metrics.counters[name] ?? 0) + amount.toDouble();
  }
}
