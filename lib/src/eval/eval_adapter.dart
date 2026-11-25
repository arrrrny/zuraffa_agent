/// Thin eval/cassette delegation layer (FR-007, SC-007,
/// contracts/eval-adapter.md).
///
/// pi-evals owns cassette storage, replay, and pass/fail evaluation; the
/// wrapper records one [AgentEvaluationReport] row per case on top, through
/// the host's [AgentTelemetryPort], with references only (never raw payloads).
/// With no [EvalDelegate] (pi-evals absent) the adapter throws a typed
/// [EvalUnavailableException]; a replay failure surfaces as a typed
/// [CassetteException] recorded in the report. No second eval engine ships.
library;

import '../governance/entities/agent_evaluation_report.dart';
import '../ports/agent_telemetry_port.dart';

/// A named eval/cassette suite.
class EvalSuite {
  final String name;
  const EvalSuite(this.name);
}

/// One case outcome from pi-evals replay.
class EvalCaseResult {
  final String caseName;
  final bool passed;

  /// A redacted replay-transcript reference (never a raw payload).
  final String? transcriptRef;
  const EvalCaseResult({
    required this.caseName,
    required this.passed,
    this.transcriptRef,
  });
}

/// The aggregated result of an eval run (Zuraffa report rows).
class EvalRunResult {
  final List<AgentEvaluationReport> reports;
  const EvalRunResult(this.reports);
}

/// The pi-evals surface the wrapper delegates to.
abstract class EvalDelegate {
  Future<List<EvalCaseResult>> run(EvalSuite suite, {String? cassette});
}

/// Thrown when pi-evals is unavailable.
class EvalUnavailableException implements Exception {
  final String message;
  const EvalUnavailableException(this.message);
  @override
  String toString() => 'EvalUnavailableException: $message';
}

/// Thrown when pi-evals cannot replay a cassette.
class CassetteException implements Exception {
  final String message;
  const CassetteException(this.message);
  @override
  String toString() => 'CassetteException: $message';
}

/// Pure-Dart in-memory [EvalDelegate] (scripted pi-evals).
class InMemoryEvalDelegate implements EvalDelegate {
  final List<EvalCaseResult> results;
  InMemoryEvalDelegate({this.results = const []});

  @override
  Future<List<EvalCaseResult>> run(EvalSuite suite, {String? cassette}) async =>
      results;
}

/// Delegates eval replay to pi-evals and records Zuraffa report rows.
class EvalAdapter {
  final EvalDelegate? _delegate;
  final AgentTelemetryPort _telemetry;

  EvalAdapter({
    required EvalDelegate? delegate,
    required AgentTelemetryPort telemetry,
  }) : _delegate = delegate,
       _telemetry = telemetry;

  /// The telemetry event name every eval report row is written under.
  static const String eventName = 'agent.eval';

  Future<EvalRunResult> run(EvalSuite suite, {String? cassette}) async {
    final delegate = _delegate;
    if (delegate == null) {
      _telemetry.recordEvent(
        const AgentTelemetryEvent(
          eventName,
          attributes: {'outcome': 'evalUnavailable'},
        ),
      );
      throw EvalUnavailableException('pi-evals is unavailable');
    }

    final List<EvalCaseResult> cases;
    try {
      cases = await delegate.run(suite, cassette: cassette);
    } on CassetteException {
      _record(suite.name, '<cassette>', 'cassetteError', null);
      rethrow;
    }

    final reports = <AgentEvaluationReport>[];
    var seq = 0;
    for (final c in cases) {
      final report = AgentEvaluationReport(
        id: 'eval-${suite.name}-${seq++}',
        at: DateTime.now().toUtc(),
        suite: suite.name,
        caseName: c.caseName,
        outcome: c.passed ? 'pass' : 'fail',
        redactedTranscript: c.transcriptRef,
      );
      reports.add(report);
      _record(
        report.suite,
        report.caseName,
        report.outcome,
        report.redactedTranscript,
      );
    }
    return EvalRunResult(reports);
  }

  void _record(String suite, String caseName, String outcome, String? ref) {
    _telemetry.recordEvent(
      AgentTelemetryEvent(
        eventName,
        attributes: {
          'suite': suite,
          'case': caseName,
          'outcome': outcome,
          'redactedTranscript': ?ref,
        },
      ),
    );
  }
}
