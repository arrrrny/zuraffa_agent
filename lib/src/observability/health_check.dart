// Observability seam (issue #133, O-3) — health checks.
//
// [HealthCheckService] aggregates [HealthProbe]s into one [HealthReport].
// The issue asks for the aggregation to be a documented contract consumers
// can mount as `/health` or `/readyz` — [HealthReport.toJson] is that
// contract:
//
//   {
//     "status": "ok" | "degraded" | "unhealthy",
//     "checkedAt": "<UTC ISO-8601>",
//     "checks": [ {"name": ..., "status": ..., "details": {...}}, ... ]
//   }
//
// HTTP mapping (documented, not enforced — the engine never binds a port):
//   - `/health` (liveness): 200 whenever the process answers.
//   - `/readyz` (readiness): 200 for `ok`, 503 for `degraded` and
//     `unhealthy`.
//
// Shipped probes cover the issue's list: circuit-breaker states, MCP
// client states, the last LLM error, and session-storage free space. The
// free-space probe takes an injected getter — the pure core must not
// import dart:io (constitution VII); the consumer supplies the byte count
// from its platform layer.

import '../llm/circuit_breaker.dart';
import '../llm/llm_client.dart';
import '../mcp/mcp_client.dart';

/// Overall readiness of the aggregate.
enum HealthStatus {
  /// Serving fully.
  ok,

  /// Serving with reduced capability (e.g. one breaker open, MCP client
  /// reconnecting, disk nearing capacity). Maps to 503 on `/readyz`.
  degraded,

  /// Not able to serve (e.g. MCP client in terminal `failed` state).
  /// Maps to 503 on `/readyz`.
  unhealthy,
}

/// One probe's verdict.
class HealthCheckResult {
  const HealthCheckResult({
    required this.name,
    required this.status,
    this.details = const {},
    this.error,
  });

  /// Probe name — stable identifier in the report (`circuit_breakers`,
  /// `mcp_clients`, `last_llm_error`, `session_storage_space`).
  final String name;
  final HealthStatus status;

  /// Free-form machine-readable detail (state per provider, byte counts…).
  final Map<String, Object?> details;

  /// Optional human-readable error text when the probe itself failed.
  final String? error;

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status.name,
    'details': details,
    if (error != null) 'error': error,
  };
}

/// The aggregate verdict, serializable as the `/health` body.
class HealthReport {
  const HealthReport({
    required this.status,
    required this.results,
    required this.checkedAt,
  });

  /// The worst status across all probe results (unhealthy > degraded > ok).
  final HealthStatus status;
  final List<HealthCheckResult> results;
  final DateTime checkedAt;

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
    'checks': [for (final r in results) r.toJson()],
  };
}

/// A single named health check. Implement and inject for anything
/// deployment-specific; the shipped probes cover the issue's baseline.
abstract interface class HealthProbe {
  String get name;

  Future<HealthCheckResult> probe();
}

/// Aggregates probes into a [HealthReport]. Stateless — call [check] per
/// scrape; each call re-runs every probe.
class HealthCheckService {
  HealthCheckService({
    List<HealthProbe> probes = const [],
    DateTime Function()? clock,
  }) : _probes = List.unmodifiable(probes),
       _clock = clock ?? DateTime.now;

  final List<HealthProbe> _probes;
  final DateTime Function() _clock;

  /// Runs every probe and aggregates to the worst status.
  Future<HealthReport> check() async {
    final results = <HealthCheckResult>[];
    var status = HealthStatus.ok;
    for (final probe in _probes) {
      try {
        final result = await probe.probe();
        results.add(result);
        status = _worst(status, result.status);
      } catch (e) {
        // A throwing probe must not sink the whole report.
        results.add(
          HealthCheckResult(
            name: probe.name,
            status: HealthStatus.unhealthy,
            error: e.toString(),
          ),
        );
        status = HealthStatus.unhealthy;
      }
    }
    return HealthReport(status: status, results: results, checkedAt: _clock());
  }

  static HealthStatus _worst(HealthStatus a, HealthStatus b) =>
      switch ((a, b)) {
        (_, HealthStatus.unhealthy) => HealthStatus.unhealthy,
        (HealthStatus.unhealthy, _) => HealthStatus.unhealthy,
        (_, HealthStatus.degraded) => HealthStatus.degraded,
        (HealthStatus.degraded, _) => HealthStatus.degraded,
        _ => HealthStatus.ok,
      };
}

/// Aggregates [CircuitBreaker] states. `closed` is ok; `half-open` and
/// `open` are degraded — the fallback chain still serves through other
/// providers, so this is reduced capability, not an outage.
class BreakerHealthProbe implements HealthProbe {
  BreakerHealthProbe(List<CircuitBreaker> breakers)
    : _breakers = List.unmodifiable(breakers);

  final List<CircuitBreaker> _breakers;

  @override
  String get name => 'circuit_breakers';

  @override
  Future<HealthCheckResult> probe() async {
    if (_breakers.isEmpty) {
      return const HealthCheckResult(
        name: 'circuit_breakers',
        status: HealthStatus.ok,
        details: {'breakers': 'none'},
      );
    }
    var status = HealthStatus.ok;
    final states = <String, String>{};
    for (final breaker in _breakers) {
      final stateName = breaker.state.name;
      states[breaker.providerId] = stateName;
      if (stateName != 'closed') status = HealthStatus.degraded;
    }
    return HealthCheckResult(
      name: name,
      status: status,
      details: {'providers': states},
    );
  }
}

/// Aggregates [McpClient] states. `connected` is ok; `connecting`,
/// `reconnecting` and `disconnected` are degraded; `failed` (reconnect
/// policy exhausted) is unhealthy.
class McpHealthProbe implements HealthProbe {
  McpHealthProbe(List<McpClient> clients)
    : _clients = List.unmodifiable(clients);

  final List<McpClient> _clients;

  @override
  String get name => 'mcp_clients';

  @override
  Future<HealthCheckResult> probe() async {
    if (_clients.isEmpty) {
      return const HealthCheckResult(
        name: 'mcp_clients',
        status: HealthStatus.ok,
        details: {'clients': 'none'},
      );
    }
    var status = HealthStatus.ok;
    final states = <String, String>{};
    for (final client in _clients) {
      final state = client.state;
      states[client.transport.id] = state.name;
      status = switch (state) {
        McpClientState.connected => status,
        McpClientState.failed => HealthStatus.unhealthy,
        _ => _worseNotUnhealthy(status),
      };
    }
    return HealthCheckResult(
      name: name,
      status: status,
      details: {'clients': states},
    );
  }

  static HealthStatus _worseNotUnhealthy(HealthStatus current) =>
      current == HealthStatus.ok ? HealthStatus.degraded : current;
}

/// Tracks the most recent LLM failure/success so the health surface can
/// expose "last-LLM-error" without scraping logs. The engine records into
/// it where completions fail; probe verdict: no error (or last event was a
/// success) is ok, a recorded error is degraded — the chain may have
/// recovered since, and the report carries the error text either way.
class LastLlmErrorTracker {
  LastLlmErrorTracker({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Injectable clock — the repo's injectable-time discipline
  /// ([CircuitBreaker] takes one too); defaults to the wall clock.
  final DateTime Function() _clock;

  Object? _lastError;
  String? _lastErrorProvider;
  DateTime? _lastErrorAt;
  DateTime? _lastSuccessAt;

  /// Records a failed completion attempt.
  void recordError(Object error, {StackTrace? stackTrace, String? provider}) {
    _lastError = error;
    _lastErrorProvider = provider;
    _lastErrorAt = _clock();
  }

  /// Records a successful completion; clears the active error state.
  void recordSuccess() {
    _lastError = null;
    _lastErrorProvider = null;
    _lastSuccessAt = _clock();
  }

  /// The most recent error, or null when none is active.
  Object? get lastError => _lastError;

  /// The provider the last error came from, or null.
  String? get lastErrorProvider => _lastErrorProvider;

  /// When the last error was recorded, or null.
  DateTime? get lastErrorAt => _lastErrorAt;

  /// When the last success was recorded, or null.
  DateTime? get lastSuccessAt => _lastSuccessAt;
}

/// Exposes the [LastLlmErrorTracker] state as a probe.
class LastLlmErrorProbe implements HealthProbe {
  LastLlmErrorProbe(this._tracker);

  final LastLlmErrorTracker _tracker;

  /// Upper bound for the rendered error text in the `/health` JSON. A
  /// recorded [LlmHttpException] embeds the provider response body in its
  /// `toString` — prompt content must not ride along in a health scrape.
  static const _maxErrorTextLength = 200;

  @override
  String get name => 'last_llm_error';

  @override
  Future<HealthCheckResult> probe() async {
    final error = _tracker.lastError;
    if (error == null) {
      return HealthCheckResult(
        name: name,
        status: HealthStatus.ok,
        details: {
          'lastSuccessAt': _tracker.lastSuccessAt?.toUtc().toIso8601String(),
        },
      );
    }
    return HealthCheckResult(
      name: name,
      status: HealthStatus.degraded,
      details: {
        'error': _describeError(error),
        'provider': _tracker.lastErrorProvider,
        'at': _tracker.lastErrorAt?.toUtc().toIso8601String(),
      },
    );
  }

  /// Bounded, body-free rendering of the recorded error for the health
  /// JSON: [LlmHttpException] renders as type + provider + status code —
  /// the response body is dropped; any other error is length-bounded.
  static String _describeError(Object error) {
    if (error is LlmHttpException) {
      return 'LlmHttpException: ${error.provider} returned HTTP '
          '${error.statusCode}';
    }
    final text = error.toString();
    return text.length <= _maxErrorTextLength
        ? text
        : '${text.substring(0, _maxErrorTextLength)}…';
  }
}

/// Reports session-storage free space from an injected getter. Null (no
/// getter, or unknown on this platform) reports ok with
/// `freeSpaceBytes: 'unknown'`; below [warningThresholdBytes] reports
/// degraded. Supply the getter from the platform layer — e.g. a statvfs /
/// `GetDiskFreeSpaceEx` binding over the session store's volume.
class SessionStorageSpaceProbe implements HealthProbe {
  const SessionStorageSpaceProbe({
    int? Function()? freeSpaceBytes,
    this.warningThresholdBytes = 64 * 1024 * 1024,
  }) : _freeSpaceBytes = freeSpaceBytes;

  final int? Function()? _freeSpaceBytes;
  final int warningThresholdBytes;

  @override
  String get name => 'session_storage_space';

  @override
  Future<HealthCheckResult> probe() async {
    final free = _freeSpaceBytes?.call();
    if (free == null) {
      return const HealthCheckResult(
        name: 'session_storage_space',
        status: HealthStatus.ok,
        details: {'freeSpaceBytes': 'unknown'},
      );
    }
    if (free < warningThresholdBytes) {
      return HealthCheckResult(
        name: name,
        status: HealthStatus.degraded,
        details: {
          'freeSpaceBytes': free,
          'warningThresholdBytes': warningThresholdBytes,
        },
      );
    }
    return HealthCheckResult(
      name: name,
      status: HealthStatus.ok,
      details: {'freeSpaceBytes': free},
    );
  }
}
