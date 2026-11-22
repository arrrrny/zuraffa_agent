**Template Version**: `zuraffa-1.0`

# Feature Specification: Zuraffa governance extensions over pi

**Branch**: `205-zuraffa-governance-over-pi` | **Date**: 2026-11-22

**Status**: Draft

**Input**: GitHub issue #205 — "Add Zuraffa governance extensions over pi"
(https://github.com/arrrrny/zuraffa_agent/issues/205). Normative architecture:
https://github.com/arrrrny/zuraffa_browser/blob/master/handoffs/2026-11-22-pi-zuraffa-browser-agent-agent-architecture-plan.md
(§7 Workstream B — rebuild `zuraffa_agent` as a Zuraffa wrapper around pi;
this spec is the governance slice of §7.4). Depends on:
arrrrny/zuraffa_agent#204 (the wrapper runtime + DI + host ports this spec
extends).

## Summary

Once the thin Zuraffa wrapper (spec 204) opens a pi runtime, Zuraffa's
existing ecosystem capabilities must ride on top of pi's primitives —
not on a second agent loop, policy engine, MCP model, session/task model,
or approval dispatcher. This spec defines the governance/observability/
artifacts/MCP/eval/host-integration slice: pi `beforeTool` / `afterTool` /
provider-request hooks carry tool allowlists, argument guards, risk tiers,
result minimization, PII scrubbing, artifact references, and redaction;
pi signals + memoized deadlines + host ports carry durable approvals;
Zuraffa telemetry/audit/metrics/health adapters observe pi commits,
phases, submissions, tool calls, and provider events without secret
payloads by default; MCP adaptation delegates to pi-mcp when present;
oversized results and eval/cassettes ride pi tool-result hooks + pi-evals
with Zuraffa reporting on top; zfa-generated entities cover only
Zuraffa-owned configuration, governance, audit/eval, and artifact data —
never pi message/task/submission/session duplicates.

**Out of scope**: implementing the wrapper runtime, DI, host ports, or
extension registry (that is spec 204); implementing pi's `beforeTool` /
`afterTool` / provider-request hook semantics, signals, or durable
scheduler (pi owns those; pi#12 owns durable behavior); browser-specific
governance (that belongs to `zuraffa_browser_agent`); a host
application's final composition (the host wires credentials, lifecycle,
and presentation). This spec does not claim durable approvals or
pi#12 behavior before pi#12 lands — interfaces are declared; durable
implementation waits.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tool governance through pi hooks (Priority: P1)

A host wants Zuraffa's tool allowlists, argument guards, risk tiers, and
default-deny behavior applied to a pi runtime. The wrapper installs
`beforeTool` hooks (deny before execution), `afterTool` hooks (minimize,
scrub PII, attach artifact refs), and provider-request hooks (sanitize
egress payloads); a failed sanitizer fails closed without model egress.

**Why this priority**: this is the safety floor — every other capability
assumes governance runs first and that redaction failures never leak.

**Independent Test**: a scripted pi conversation attempts a denied tool
and a tool returning PII; assert the denial happens before execution, the
model never sees unredacted content, and a forced sanitizer failure
yields a typed failure with no unredacted content emitted.

**Acceptance Scenarios**:

1. **Given** a `GovernancePolicy` with a deny-list and risk tiers, **When**
   the agent attempts a denied tool, **Then** the pi `beforeTool` hook
   rejects it with a typed outcome before execution, and the audit record
   captures the denial (SC-001).
2. **Given** a `RedactionRule` set and a tool result containing PII, **When**
   the result passes through the `afterTool` hook, **Then** the model
   receives only the redacted content, and the audit record marks the
   event redacted (SC-001).
3. **Given** a sanitizer that throws, **When** the `afterTool` hook runs,
   **Then** the wrapper fails closed — typed failure, no unredacted
   content reaches the model or any egress port (SC-002).
4. **Given** no governance policy is installed, **When** the runtime opens,
   **Then** the wrapper defaults to default-deny for unregistered tools
   (SC-003).

---

### User Story 2 - Durable approvals via pi signals + host ports (Priority: P1)

A host wants Zuraffa's durable approvals — request, memoized deadline,
parked tool, signal grant/deny — layered on pi signals and the host's
`AgentApprovalPort`. Approval presentation and notification are
host-provided; the wrapper never presents UI, never reads a global
service locator, and never claims durable behavior pi#12 does not yet
provide.

**Why this priority**: approvals gate high-risk tools; without a durable,
host-mediated approval path, governance cannot safely escalate.

**Independent Test**: with in-memory `AgentApprovalPort` + a pi signal
gate (or the wrapper-owned interface before pi#12), drive a `high`-tier
tool through the approval gate — grant, deny, and timeout paths each
produce the typed approval outcome; assert no model egress during the
gate.

**Acceptance Scenarios**:

5. **Given** a `high`-tier tool and a host `AgentApprovalPort`, **When**
   the `beforeTool` hook requests approval, **Then** the host adapter
   presents it and returns grant/deny; a deny yields a typed denial
   outcome and the tool never executes (SC-004).
6. **Given** an approval gate that times out, **When** the deadline
   elapses, **Then** the gate denies by default and the audit record
   captures the expiry (SC-004).
7. **Given** a host that has not injected `AgentApprovalPort`, **When** a
   tool requires approval, **Then** the wrapper fails closed with a typed
   `missingApprovalPort` outcome — it never falls back to a global
   locator (SC-005).

---

### User Story 3 - Observability without secret payloads (Priority: P2)

A host wants Zuraffa's audit, metrics, health, crash reporting, and usage
to observe pi commits, phases, submissions, tool calls, and provider
events through `AgentTelemetryPort` adapters — without secret payloads by
default.

**Why this priority**: observability is what makes the wrapper operable,
but a payload leak here defeats every governance guarantee elsewhere.

**Independent Test**: run a scripted conversation with a recording
telemetry adapter; assert spans/events/errors are recorded for each pi
phase with redacted payloads and that secret-like fields are scrubbed by
default.

**Acceptance Scenarios**:

8. **Given** a recording `AgentTelemetryPort`, **When** a scripted
   conversation runs, **Then** each pi phase (commit, submission, tool
   call, provider event) yields a typed telemetry record with a redacted
   payload (SC-006).
9. **Given** a payload that matches a default secret pattern (API key,
   bearer token), **When** the telemetry adapter records it, **Then** the
   payload is redacted before persistence and the original is never
   stored (SC-006).
10. **Given** an opt-in to include payloads, **When** the host explicitly
    enables it, **Then** the wrapper honors the opt-in and labels the
    payload as unredacted (SC-006).

---

### User Story 4 - Oversized results, artifacts, and eval/cassette adaptation (Priority: P2)

A host wants oversized tool results to be stored as artifacts (not inline
bytes) and eval/cassette flows to ride pi-evals + pi tool-result hooks
with Zuraffa reporting on top — no second transcript, cassette, or eval
engine in this package.

**Why this priority**: result discipline and eval parity are what keep
the wrapper small and what let existing Zuraffa eval/cassette assets
survive the migration.

**Independent Test**: a tool returns a 2 MB result; assert the model
sees a summary + `AgentArtifactRef` (not bytes), the bytes land in the
injected `AgentArtifactPort`, and the eval/cassette adapter replays the
recorded tool result through pi-evals with a Zuraffa report row.

**Acceptance Scenarios**:

11. **Given** a result over the configured threshold, **When** the
    `afterTool` hook runs, **Then** the model receives a summary +
    `AgentArtifactRef` and the bytes are persisted via
    `AgentArtifactPort` (SC-007).
12. **Given** an eval/cassette flow, **When** the wrapper runs it,
    **Then** replay uses pi-evals + pi tool-result hooks and Zuraffa
    reporting records the outcome without a parallel transcript or
    cassette store (SC-007).

---

### User Story 5 - MCP adaptation via pi-mcp (Priority: P3)

A host wants Zuraffa's MCP client surface, but the wrapper delegates
transport/tool-list/call to pi-mcp when available. Only generic
DI/governance behavior (tool name prefixing, risk-tier wiring,
telemetry taps) remains in `zuraffa_agent`.

**Why this priority**: duplicating the MCP client would recreate the
drift the migration removes; delegating is what keeps the wrapper thin.

**Independent Test**: with pi-mcp present, register an MCP server through
the wrapper; assert tool listing and calls route through pi-mcp and that
the wrapper only contributes governance/telemetry metadata.

**Acceptance Scenarios**:

13. **Given** pi-mcp is available, **When** the host registers an MCP
    server, **Then** listing and calls route through pi-mcp and the
    wrapper contributes only governance/telemetry metadata (SC-008).
14. **Given** pi-mcp is unavailable, **When** the host registers an MCP
    server, **Then** the wrapper fails with a typed `mcpUnavailable`
    outcome — it never ships a second MCP client (SC-008).

---

### Edge Cases

- **pi#12 not yet landed**: durable approvals, signals, and memoized
  deadlines are declared as wrapper-owned interfaces; the factory fails
  with a typed `durableUnavailable` outcome when a durable surface is
  requested. The package's public contracts still compile against the pi
  interfaces they name (FR-007).
- **Default-deny when no policy**: an unregistered tool is denied by
  default; a host must explicitly allow-list it (SC-003).
- **Sanitizer throws**: fail closed — no model egress, typed failure
  outcome, audit row with `redacted: false` and the error.
- **Telemetry adapter throws**: the wrapper isolates the failure (records
  a `telemetryError` audit row) and continues — observability must not
  break the agent loop.
- **Approval port missing**: typed `missingApprovalPort`; no global
  fallback (SC-005).
- **Oversized result with no artifact port**: typed `missingArtifactPort`;
  the result is not silently truncated into the model.
- **pi-mcp absent**: typed `mcpUnavailable`; no second client.
- **Two governance policies installed**: the wrapper merges deterministically
  (deny wins, stricter risk tier wins) and records the merge in the audit
  row — it does not silently pick one.
- **Host-provided extension overlapping a generic one**: the host extension
  wins; the generic one is recorded as shadowed in the audit row.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Governance MUST be implemented exclusively through pi hook
  primitives (`beforeTool` for allow/deny/argument-guard/risk/approval
  gate; `afterTool` for minimization, PII scrubbing, artifact refs,
  redaction; provider-request hooks for egress sanitization). The
  package MUST NOT ship a second policy engine, a second approval
  dispatcher, or a second provider transport (issue #205 acceptance;
  architecture plan §7.4).
- **FR-002**: Tool governance MUST default to default-deny: a tool not
  explicitly allow-listed is rejected before execution with a typed
  outcome (issue #205 "default-deny tool governance").
- **FR-003**: Redaction and result minimization MUST fail closed: a
  sanitizer error, a missing redaction dependency, or an unresolved
  artifact port yields a typed failure outcome and MUST NOT release
  unredacted content to the model or to any egress port (issue #205
  "fail-closed redaction").
- **FR-004**: Durable approvals MUST use pi signals, memoized deadlines,
  and host-provided `AgentApprovalPort` presentation/notification ports;
  the wrapper MUST NOT present UI, MUST NOT read `GetIt.instance` in
  business logic, and MUST NOT claim durable behavior pi#12 does not
  provide (issue #205 "durable approvals"; FR-006 of spec 204).
- **FR-005**: Observability (audit, metrics, health, crash reporting,
  usage) MUST observe pi commits, phases, submissions, tool calls, and
  provider events through Zuraffa telemetry adapters
  (`AgentTelemetryPort`) and MUST redact secret-like payloads by default;
  an opt-in may include unredacted payloads and MUST be explicitly
  labeled (issue #205 "secret-safe observability").
- **FR-006**: MCP adaptation MUST delegate to pi-mcp when available; only
  generic DI/governance behavior (tool name prefixing, risk-tier wiring,
  telemetry taps) remains in `zuraffa_agent`. The package MUST NOT ship
  a second MCP client (issue #205 "MCP adaptation uses pi-mcp").
- **FR-007**: Oversized results MUST be handled by pi tool-result hooks
  plus Zuraffa `AgentArtifactPort` stores; eval/cassette support MUST
  use pi-evals plus Zuraffa reporting. The package MUST NOT ship a
  parallel transcript, cassette store, or eval engine (issue #205
  "oversized results use pi tool-result hooks plus Zuraffa artifact
  stores; eval/cassette support uses pi-evals plus Zuraffa reporting").
- **FR-008**: zfa-generated entities MUST be limited to Zuraffa-owned
  configuration, governance, audit/eval, and artifact data
  (`GovernancePolicy`, `RiskTier`, `RedactionRule`, `AgentAuditRecord`,
  `AgentArtifactDescriptor`, `AgentEvaluationReport`, and their value
  objects). The package MUST NOT generate pi message/task/submission/
  session duplicates (issue #205 "zfa-generated entities are limited to
  Zuraffa-owned configuration, governance, audit/eval, and artifact
  data").
- **FR-009**: Contract tests MUST prove identical behavior through
  pure-Dart in-memory adapters and production adapters — same suite, no
  per-adapter branching (issue #205 "in-memory/production contract
  parity"; FR-008 of spec 204).
- **FR-010**: The dependency `Depends on: arrrrny/zuraffa_agent#204`
  MUST be preserved; this spec is the governance slice that extends the
  wrapper runtime, DI, host ports, and `PiRuntimeAdapter` introduced by
  204. The package MUST NOT open a pi runtime outside the wrapper's
  factory (issue #205 dependency declaration).
- **FR-011**: Unstable or not-yet-landed pi APIs (pi#12 durable
  surface, pi-mcp surface when absent) MUST be isolated behind
  wrapper-owned interfaces in `src/pi/`; the package MUST NOT represent
  them as already implemented (issue #205 "unstable pi APIs stay behind
  declared interfaces and are not represented as already implemented";
  FR-005 of spec 204).
- **FR-012**: The package MUST NOT import any browser package
  (`zuraffa_browser_core`, `zuraffa_browser_agent`) or host application,
  and MUST NOT depend on Flutter (FR-008 of spec 204; constitution VII).

### Key Entities *(include if feature involves data)*

- **GovernancePolicy** (zfa-generated entity): tool allow/deny lists,
  per-tool risk tiers, redaction rules, approval-required tiers — consumed
  by pi hooks, never executed by a separate engine.
- **RiskTier** (zfa-generated enum): `low | medium | high | critical` —
  the gate key for allow/deny/approval decisions.
- **RedactionRule** (zfa-generated value object): named PII patterns
  (email, phone, AWS key, bearer token, etc.) and replacement tokens.
- **AgentAuditRecord** (zfa-generated entity): phase, outcome, redacted
  flag, error (if any) — the secret-safe audit row.
- **AgentArtifactDescriptor** (zfa-generated entity): opaque artifact
  reference + kind + createdAt — replaces inline oversized bytes.
- **AgentEvaluationReport** (zfa-generated entity): eval/cassette
  outcome rows recorded on top of pi-evals.
- **AgentTelemetryPort / AgentApprovalPort / AgentArtifactPort**
  (ports from spec 204, extended here): the host-injection surface this
  spec's adapters write to.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A denied tool is rejected before execution and a PII-bearing
  result is redacted before the model sees it — both with typed outcomes
  and audit rows (issue #205 acceptance #1, #2).
- **SC-002**: A forced sanitizer failure yields a typed failure outcome
  and MUST NOT release unredacted content to the model or to any egress
  port (issue #205 acceptance #2; fail-closed redaction).
- **SC-003**: With no policy installed, an unregistered tool is denied by
  default with a typed outcome (default-deny).
- **SC-004**: `high`-tier tools gate through `AgentApprovalPort`; grant,
  deny, and timeout paths each produce the typed approval outcome; no
  model egress occurs while the gate is open (issue #205 "durable
  approvals").
- **SC-005**: A missing `AgentApprovalPort` yields a typed
  `missingApprovalPort` outcome; no global locator fallback exists
  anywhere in the package.
- **SC-006**: Each pi phase (commit, submission, tool call, provider
  event) yields a redacted telemetry record; secret-like payloads are
  redacted by default and the opt-in path is explicitly labeled
  (issue #205 "secret-safe observability").
- **SC-007**: An oversized result is replaced by a summary +
  `AgentArtifactRef` in the model-facing result and stored via
  `AgentArtifactPort`; eval/cassette replay uses pi-evals + Zuraffa
  reporting with no parallel transcript or cassette store (issue #205
  "oversized results" + "eval/cassette support").
- **SC-008**: With pi-mcp present, MCP listing/calls route through
  pi-mcp; with pi-mcp absent, the wrapper fails with a typed
  `mcpUnavailable` outcome and ships no second client (issue #205
  "MCP adaptation uses pi-mcp").
- **SC-009**: The same contract suite passes against in-memory and
  production adapters with no per-adapter branching (issue #205
  "in-memory/production contract parity").
- **SC-010**: `grep` for browser imports, `LlmToolLoop`,
  `MissionRunner`, a second policy engine, a second approval dispatcher,
  or a second MCP client in the new governance slice returns no matches;
  `dart analyze` is pristine (constitution X; issue #205 "do not create
  a parallel runtime, provider loop, policy engine, MCP tool model,
  session/task model, or approval dispatcher").
- **SC-011**: Durable approval behavior is stated as available only once
  pi#12 lands; before then the wrapper-owned interface compiles and
  returns a typed `durableUnavailable` outcome (issue #205 "unstable pi
  APIs stay behind declared interfaces").
- **SC-012**: The package's zfa-generated entities cover only
  Zuraffa-owned configuration, governance, audit/eval, and artifact
  data — `grep` for generated pi message/task/submission/session
  duplicates returns no matches (issue #205 "zfa-generated entities are
  limited to Zuraffa-owned...").

## Assumptions

- **Wrapper baseline (204)**: the wrapper runtime, DI seam, host ports
  (`AgentCredentialPort`, `AgentStoragePort`, `AgentEgressPort`,
  `AgentTelemetryPort`, `AgentArtifactPort`, `AgentApprovalPort`,
  `AgentLifecyclePort`), `PiRuntimeAdapter`, and extension bootstrap
  exist as specified in 204; this spec only adds the governance,
  observability, artifacts, MCP/eval, and host-integration slices on top.
- **pi contract surface**: pi's public `beforeTool` / `afterTool` /
  provider-request hooks, `AgentTool`, `Conversation`, `AgentEvent`,
  `Model`/`Usage`/`AgentMessage`, and telemetry contracts exist today
  (verified in 204 research D3). The pi#12 durable surface (submissions,
  watches, tasks, outcomes, signals, memoized values, durable approvals)
  does not yet exist; this spec declares wrapper-owned interfaces and
  never claims durable behavior.
- **pi-mcp**: when present, pi-mcp owns MCP transport, listing, and
  calls; the wrapper contributes only governance/telemetry metadata. The
  wrapper ships no MCP client of its own.
- **pi-evals**: when present, pi-evals owns eval/cassette replay; the
  wrapper records Zuraffa evaluation reports on top. The wrapper ships no
  second transcript, cassette, or eval engine.
- **Reference packages**: `zuraffa_permissions` (ports + Zorphy
  entities + generated use cases + pure-Dart in-memory adapters +
  explicit DI) and `zuraffa_notifications` (composed capability service)
  are read-only structural references (spec 204 D2); this spec follows
  them structurally and imports neither browser nor product code.
- **zfa generation**: all Zuraffa-owned entities, enums, value objects,
  and use cases are generated with `zfa entity create` / `zfa make` /
  `zfa build`; generated output is never hand-edited (constitution I, IX;
  fleet AGENTS.md ZFA GENERATION rule).
- **Fleet test concurrency**: tests run with `dart test -j 2` (fleet
  test-concurrency guard).
- **Branch and version**: this spec targets the next-major version
  (architecture plan §7.2); the public API may break cleanly. The spec
  lives on `205-zuraffa-governance-over-pi` off master; planning
  artifacts commit to master per the issue's workflow.

## Dependencies

Depends on: arrrrny/zuraffa_agent#204

The wrapper runtime, DI seam, host ports, and `PiRuntimeAdapter` from 204
are the substrate this spec extends. This spec does not open a pi runtime
outside the wrapper's factory, does not re-declare the host ports (it
consumes them), and does not claim durable behavior before pi#12 lands.