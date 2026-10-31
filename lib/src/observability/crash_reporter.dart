// Observability seam (issue #133, O-4) — crash reporting.
//
// [CrashReporter] is the boundary [MissionRunner.runGuarded] routes
// uncaught zone errors to, after logging them SEVERE on the
// `zuraffa.agent.engine` subsystem. It rethrows to the caller afterwards —
// observation, not suppression.
//
// Integration points (documented contract):
//   - Sentry: implement `record` with `Sentry.captureException(error,
//     stackTrace, hint/contexts: context)` and wire the instance into
//     `MissionRunner(crashReporter: ...)`.
//   - OTLP / OpenTelemetry: implement `record` by exporting the error as
//     an exception event on the current span (`Spans.current`) and/or a
//     dedicated crash span.
//   - Anything else (file sink, webhook): same one-method contract.

/// Receives uncaught errors captured at the engine's crash boundary.
abstract interface class CrashReporter {
  /// Reports [error] with its [stackTrace]. [context] carries structured
  /// identifiers (e.g. `mission.id`) — must not contain secrets or
  /// message payloads.
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  });
}

/// The default reporter — drops every record.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  static const NoopCrashReporter instance = NoopCrashReporter();

  @override
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  }) {}
}

/// One crash captured by [RecordingCrashReporter].
final class CapturedCrash {
  const CapturedCrash({
    required this.error,
    required this.stackTrace,
    this.context,
  });

  final Object error;
  final StackTrace stackTrace;
  final Map<String, Object?>? context;

  @override
  String toString() =>
      'CapturedCrash(${error.runtimeType}: $error, context: $context)';
}

/// In-memory [CrashReporter] for tests and local diagnostics.
class RecordingCrashReporter implements CrashReporter {
  /// Every recorded crash, in record order.
  final List<CapturedCrash> reports = [];

  @override
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?>? context,
  }) {
    reports.add(
      CapturedCrash(error: error, stackTrace: stackTrace, context: context),
    );
  }
}
