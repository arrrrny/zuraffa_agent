# Contract: Eval adapter (pi-evals delegation)

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Eval/cassette support uses pi-evals plus Zuraffa reporting (FR-007, issue
#205 "eval/cassette support uses pi-evals plus Zuraffa reporting"). The
wrapper ships no parallel transcript, cassette store, or eval engine.

## Shape (logical)

```dart
/// Thin delegation layer. pi-evals owns replay; the wrapper records
/// AgentEvaluationReport rows on top.
class EvalAdapter {
  EvalAdapter({
    required EvalDelegate delegate,   // pi-evals when present
    required AgentTelemetryPort telemetry,
  });

  Future<EvalRunResult> run(EvalSuite suite, {String? cassette});
}
```

## Behavior

1. `run` delegates replay to `delegate` (pi-evals) when present.
2. The wrapper records an `AgentEvaluationReport` row per case via
   `AgentTelemetryPort` (suite, case, outcome, redactedTranscript) — never
   raw payloads (FR-007, SC-007, FR-005).
3. When pi-evals is unavailable → the adapter fails with a typed
   `evalUnavailable` outcome; the wrapper does not ship a second eval
   engine.
4. A cassette that pi-evals cannot replay surfaces as a typed
   `cassetteError` outcome recorded in the report; the wrapper does not
   silently drop the case.

## What stays in zuraffa_agent

- `AgentEvaluationReport` row recording (suite, case, outcome, ref).
- Redaction of the replay transcript reference (FR-005).
- Default-deny governance applied to any tool calls during replay.

## What delegates to pi-evals

- Cassette storage and replay.
- Case execution and pass/fail evaluation.
- Transcript recording.

## Contract rule

`EvalAdapter` has a pure-Dart in-memory `EvalDelegate` (scripted pi-evals)
and a production pi-evals adapter; the contract suite in `test/eval/` runs
against both with no branching (FR-009, SC-009).