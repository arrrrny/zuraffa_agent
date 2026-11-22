# Quickstart: Zuraffa governance extensions over pi

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Validation guide proving the governance slice works end-to-end. Run from the
package root after implementation. Prerequisites: Dart ^3.11 SDK; spec 204's
wrapper (`ZuraffaAgent` facade, `AgentRuntimeFactory`, `AgentPortRegistry`,
`PiRuntimeAdapter`) landed; `pi` dependency resolvable (gated on
`arrrrny/pi#12` for durable behavior).

## Setup

```sh
# from repo root (package is the repo itself)
dart pub get
dart analyze            # constitution X: 0 errors, 0 warnings
dart test -j 2
```

## Scenario 1 — Default-deny + deny-before-execution (SC-003, SC-001)

1. Open a runtime with no governance policy:

```dart
final runtime = await factory.open();   // no policy = default-deny
```

2. Attempt an unregistered tool:

```dart
final outcome = await runtime.submit('call unregistered_tool');
expect(outcome.phase, AgentPhase.toolDenied);      // denied before execution
expect(outcome.outcome, AgentOutcomeKind.denied);
```

**Expected**: the unregistered tool is denied before execution with a typed
outcome; the audit row records the denial.

## Scenario 2 — PII redaction before the model (SC-001)

1. Register a scrubbing policy:

```dart
final policy = GovernancePolicy(
  toolAllowList: ['read_file'],
  redactionRules: [RedactionRule.email(), RedactionRule.awsKey()],
  requireApprovalForTiers: [RiskTier.high],
);
final runtime = await factory.open(governance: policy);
```

2. Return PII:

```dart
final scrubbed = await runtime.submit('return my email a@b.com');
expect(scrubbed.outcome.exposedContent.contains('a@b.com'), isFalse);
```

**Expected**: the model receives only the redacted content; the audit row
marks the event `redacted: true`.

## Scenario 3 — Fail-closed sanitizer (SC-002)

```dart
final failed = await runtime.submit('trigger sanitizer error');
expect(failed.outcome.kind, AgentOutcomeKind.failure);
expect(failed.outcome.exposedContent, isNull);     // no unredacted content
```

**Expected**: a sanitizer failure yields a typed failure outcome; no
unredacted content reaches the model or any egress port.

## Scenario 4 — Durable approval gate (SC-004, SC-011)

1. With pi#12 landed (durable): a `high`-tier tool gates through the host
   `AgentApprovalPort`; grant, deny, and timeout paths each produce the
   typed approval outcome; no model egress occurs while the gate is open.

2. Before pi#12 (interface only):

```dart
final outcome = await runtime.submit('call high_tier_tool');
expect(outcome.kind, AgentOutcomeKind.durableUnavailable);
```

**Expected**: durable approval behavior is stated as available only once
pi#12 lands; before then the wrapper-owned interface compiles and returns
a typed `durableUnavailable` outcome.

## Scenario 5 — Secret-safe observability (SC-006)

1. Run with a recording telemetry adapter:

```dart
final telemetry = RecordingAgentTelemetryPort();
final runtime = await factory.open(ports: portsWith(telemetry));
await runtime.submit('call read_file on /etc/passwd');
```

2. Inspect the recorded rows:

```dart
expect(telemetry.records.every((r) => r.redacted), isTrue);
expect(telemetry.records.any((r) => r.phase == 'tool-call'), isTrue);
```

**Expected**: each pi phase yields a redacted telemetry record; secret-like
payloads are redacted by default; an opt-in `includeUnredactedPayloads: true`
is explicitly labeled in the audit row.

## Scenario 6 — Oversized result + artifact routing (SC-007)

```dart
final outcome = await runtime.submit('call returning_2mb');
expect(outcome.outcome.exposedContent, isA<AgentArtifactRef>());
expect(outcome.outcome.exposedContent.contains('2mb'), isFalse);
```

**Expected**: the model sees a summary + `AgentArtifactRef` (not bytes);
the bytes are persisted via `AgentArtifactPort`.

## Scenario 7 — MCP adaptation (SC-008)

```dart
// with pi-mcp present:
final outcome = await runtime.submit('call mcp__filesystem__read_file');
expect(outcome.outcome.mcpRouted, isTrue);          // routed through pi-mcp

// with pi-mcp absent:
final outcome = await runtime.submit('call mcp__filesystem__read_file');
expect(outcome.kind, AgentOutcomeKind.mcpUnavailable);
```

**Expected**: with pi-mcp present, MCP listing/calls route through pi-mcp
and the wrapper contributes only governance/telemetry metadata; with
pi-mcp absent, the wrapper fails with a typed `mcpUnavailable` outcome and
ships no second client.

## Scenario 8 — No forbidden imports or parallel engines (SC-010, SC-012)

```sh
# these must produce no matches
grep -rn "package:zuraffa_browser" lib/ || echo "OK: no browser import"
grep -rn "LlmToolLoop\|MissionRunner" lib/ || echo "OK: no parallel runtime"
grep -rn "class.*PolicyEngine\|class.*ApprovalDispatcher\|class.*McpClient" lib/ \
  || echo "OK: no parallel policy/MCP/approval engine"
dart analyze
```

**Expected**: no browser imports, no parallel runtime/policy/MCP/approval
engine, analyzer pristine.

## Scenario 9 — In-memory / production contract parity (SC-009)

```sh
dart test -j 2 test/governance/ test/approvals/ test/observability/ \
  test/artifacts/ test/mcp/ test/eval/
```

**Expected**: the same suite passes against in-memory and production
adapters with no per-adapter branching.