# Contract: Observability and audit

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Zuraffa observability (audit, metrics, health, crash reporting, usage)
observes pi commits, phases, submissions, tool calls, and provider events
through Zuraffa telemetry adapters (`AgentTelemetryPort`) without secret
payloads by default (FR-005, issue #205 "secret-safe observability").

## TelemetryAdapter

```dart
/// Bridges pi commit/phase/submission/tool-call/provider-event signals to
/// the host's AgentTelemetryPort, with secret-scrubbed payloads by default.
class TelemetryAdapter {
  TelemetryAdapter({
    required AgentTelemetryPort port,
    SecretScrubber? scrubber,          // default: SecretScrubber.defaults()
    bool includeUnredactedPayloads = false,
  });

  void onCommit(AgentCommit commit);
  void onPhase(AgentPhaseEvent event);
  void onSubmit(AgentSubmissionEvent event);
  void onToolCall(AgentToolCallEvent event);
  void onProviderEvent(AgentProviderEvent event);
}
```

Behavior:
1. Each pi event is converted to a typed telemetry record (span, event, or
   error) and written through `AgentTelemetryPort` (FR-005).
2. Payloads are scrubbed by `SecretScrubber` before persistence; the
   original is never stored (SC-006).
3. An opt-in `includeUnredactedPayloads: true` is honored and explicitly
   labeled in the audit row (`unredactedOptIn: true`) (SC-006).
4. A telemetry adapter failure is isolated: the wrapper records a
   `telemetryError` audit row and continues — observability must not break
   the agent loop (edge case).

## AuditRecorder

```dart
/// Writes AgentAuditRecord rows for every hook outcome. Never records
/// secrets by default.
class AuditRecorder {
  void record(AgentAuditRecord record);
}
```

Every hook outcome — allow, deny, redact, failClosed, approvalGranted,
approvalDenied, approvalExpired, durableUnavailable, mcpUnavailable —
yields an `AgentAuditRecord` (phase, outcome, redacted, error) written
through `AgentTelemetryPort` (FR-005, SC-006).

## MetricsReporter

```dart
/// Reports usage, health, and crash metrics derived from pi events.
class MetricsReporter {
  void reportUsage(AgentUsage usage);
  void reportHealth(AgentHealth health);
  void reportCrash(Object error, StackTrace? trace);
}
```

Metrics are derived from pi usage/health/crash events and written through
`AgentTelemetryPort`; no payload is recorded without scrubbing (FR-005).

## SecretScrubber

```dart
/// Default secret patterns + opt-in labeling. Pure-Dart; no pi dependency.
class SecretScrubber {
  static SecretScrubber defaults();   // email, phone, awsKey, bearerToken,
                                      // privateKeyHeader, jwt
  String scrub(String payload);
  bool matches(String payload);
}
```

Default patterns reuse the regex set from spec 109's `ToolResultSanitizer`
(awsKey, githubPat, jwt, privateKeyHeader, slackToken, stripeLiveKey) plus
email/phone for general PII. A scrubber failure fails closed (FR-003,
SC-002).

## Contract rule

Each adapter (`TelemetryAdapter`, `MetricsReporter`, `AuditRecorder`) has
a pure-Dart in-memory `AgentTelemetryPort` adapter and a production adapter;
the contract suite in `test/observability/` runs against both with no
branching (FR-009, SC-009).