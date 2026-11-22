# Phase 0 Research: Zuraffa governance extensions over pi

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

All Technical Context entries were resolved from the normative architecture
plan, issue #205, and read-only inspection of spec 204's planning artifacts
(commit `03379348c9d8c647e0321ec2fa9b271d1265d13e` on
`176-zuraffa-runtime-wrapper`), the `zuraffa_permissions` and
`zuraffa_notifications` reference packages, and the local `pi` checkout.
No entry required a NEEDS CLARIFICATION guess.

## D1 — Hook surface (pi primitives, no second engine)

- **Decision**: Implement allow/deny/argument-guard/risk/approval via pi
  `beforeTool` hooks; minimization / PII scrub / artifact refs / redaction
  via `afterTool` hooks; egress sanitization via provider-request hooks.
- **Rationale**: FR-001; architecture plan §7.4 ("Governance implemented
  through pi primitives"). Verified against 204's `contracts/governance-hooks.md`
  (the wrapper already supplies hook bodies; pi supplies execution semantics).
- **Alternatives considered**: A second policy engine — rejected (FR-001,
  SC-010); per-tool policy classes — rejected (would fragment the deny
  default and the audit story).

## D2 — Default-deny and policy resolution

- **Decision**: A tool not explicitly allow-listed is denied by default
  (FR-002, SC-003). When multiple policies are installed, merge
  deterministically: deny wins over allow; the stricter risk tier wins;
  redaction rules union. The merge is recorded in the audit row.
- **Rationale**: issue #205 "default-deny tool governance"; safety floor —
  an unconfigured host must not accidentally permit a tool.
- **Alternatives considered**: Default-allow — rejected (unsafe);
  last-writer-wins merge — rejected (nondeterministic, would silently
  weaken policy).

## D3 — Fail-closed redaction

- **Decision**: A sanitizer error, a missing redaction dependency, or an
  unresolved artifact port yields a typed failure outcome; no unredacted
  content reaches the model or any egress port (FR-003, SC-002).
- **Rationale**: issue #205 "fail-closed redaction"; 109's
  `ToolResultSanitizer` precedent (regex-based default rules) is the
  pattern to extend, but the new hooks live in the wrapper's governance
  slice, not in `MissionRunner` (which 204 removes).
- **Alternatives considered**: Best-effort redaction (log and continue) —
  rejected (would leak); fail-open — rejected (defeats the purpose).

## D4 — Durable approvals behind wrapper-owned interfaces

- **Decision**: Declares `ApprovalGate` (pi signal + memoized deadline +
  parked tool) and `ApprovalPortAdapter` (wires host `AgentApprovalPort`).
  Before pi#12 lands, the gate is represented by the wrapper-owned
  interface only; the factory returns a typed `durableUnavailable` outcome
  when durable behavior is requested (FR-011, SC-011).
- **Rationale**: issue #205 "durable approvals"; FR-011 ("unstable pi APIs
  stay behind declared interfaces and are not represented as already
  implemented"); 204 research D3 (no `Submission`/`Watch`/`Task`/`Outcome`
  classes exist in pi today — those are pi#12).
- **Alternatives considered**: Implementing durable approvals in the
  wrapper — rejected (FR-004 of 204 forbids a second durable scheduler);
  claiming pi#12 APIs exist — rejected (FR-011).

## D5 — Secret-safe observability

- **Decision**: `TelemetryAdapter` bridges pi commits / phases / submissions
  / tool calls / provider events to `AgentTelemetryPort`. `SecretScrubber`
  applies default secret patterns (API key, bearer token, AWS key, JWT,
  private-key headers) before any payload is persisted. An opt-in
  `includeUnredactedPayloads: true` flag is explicitly labeled in the
  audit row (FR-005, SC-006).
- **Rationale**: issue #205 "secret-safe observability"; 112's structured
  logging + 113's error observability are the in-repo precedents for the
  telemetry seam; the scrubber reuses 109's regex patterns as the default
  set.
- **Alternatives considered**: Payload-by-default — rejected (would leak
  secrets); no opt-in — rejected (some hosts need raw payloads for
  debugging, with explicit labeling).

## D6 — Oversized results and artifact routing

- **Decision**: `ArtifactRouter` intercepts oversized results in the
  `afterTool` hook, persists bytes via `AgentArtifactPort`, and replaces
  inline content with a summary + `AgentArtifactDescriptor` reference
  (FR-007, SC-007). Threshold is configurable per `GovernancePolicy`.
- **Rationale**: issue #205 "oversized results use pi tool-result hooks
  plus Zuraffa artifact stores"; 050's `oversized_result_policy` is the
  in-repo precedent for the threshold semantics; 204's
  `AgentArtifactPort` is the persistence seam.
- **Alternatives considered**: Truncating into the model — rejected (loses
  fidelity, defeats the purpose); a second artifact store — rejected
  (FR-007).

## D7 — Eval/cassette adaptation

- **Decision**: `EvalAdapter` delegates replay to pi-evals (when present)
  and records `AgentEvaluationReport` rows via `AgentTelemetryPort`
  (FR-007, SC-007). The wrapper ships no transcript, cassette, or eval
  engine.
- **Rationale**: issue #205 "eval/cassette support uses pi-evals plus
  Zuraffa reporting"; 006's eval harness is the in-repo precedent for the
  report shape; 204's telemetry port is the recording seam.
- **Alternatives considered**: Porting the eval harness into the wrapper —
  rejected (FR-007); dropping eval support — rejected (issue requirement).

## D8 — MCP adaptation via pi-mcp

- **Decision**: `McpAdapter` delegates transport / listing / calls to
  pi-mcp when present; the wrapper contributes only governance/telemetry
  metadata (tool name prefixing, risk-tier wiring, telemetry taps). With
  pi-mcp absent, the wrapper fails with a typed `mcpUnavailable` outcome
  (FR-006, SC-008).
- **Rationale**: issue #205 "MCP adaptation uses pi-mcp when available;
  only generic DI/governance behavior remains in `zuraffa_agent`"; 003 /
  049 / 105's MCP client stack is the in-repo precedent for the behavior,
  but the new slice delegates to pi-mcp rather than reimplementing.
- **Alternatives considered**: Carrying the existing MCP client forward —
  rejected (FR-006; would recreate the drift the migration removes);
  dropping MCP — rejected (issue requirement).

## D9 — zfa-generated entity boundary

- **Decision**: Generate only `GovernancePolicy`, `RiskTier`,
  `RedactionRule`, `AgentAuditRecord`, `AgentArtifactDescriptor`,
  `AgentEvaluationReport` (and value objects) with `zfa entity create`
  (FR-008, SC-012). No pi message/task/submission/session duplicates.
- **Rationale**: issue #205 "zfa-generated entities are limited to
  Zuraffa-owned configuration, governance, audit/eval, and artifact data";
  constitution IX; 204 data-model.md (the same entity boundary).
- **Alternatives considered**: Hand-writing entities — rejected
  (constitution IX, fleet AGENTS.md ZFA GENERATION rule); generating pi
  mirrors — rejected (FR-008).

## D10 — In-memory / production contract parity

- **Decision**: Each new port consumer (`TelemetryAdapter`,
  `ApprovalPortAdapter`, `ArtifactRouter`, `McpAdapter`, `EvalAdapter`)
  has a pure-Dart in-memory adapter under `lib/src/data/` and a production
  adapter supplied by the host; the contract suite in `test/` runs
  against both with no per-adapter branching (FR-009, SC-009).
- **Rationale**: issue #205 "in-memory/production contract parity"; 204
  research D5 / D7; `zuraffa_permissions` DI pattern.
- **Alternatives considered**: In-memory-only — rejected (would not prove
  production parity); per-adapter test branching — rejected (SC-009).

## D11 — Dependency and locking

- **Decision**: Preserve `Depends on: arrrrny/zuraffa_agent#204` (issue
  body line). This spec is the governance slice that extends 204's wrapper
  runtime, DI, host ports, and `PiRuntimeAdapter`; it does not open a pi
  runtime outside the wrapper's factory (FR-010). Durable behavior is
  stated as available only once pi#12 lands (FR-011, SC-011).
- **Rationale**: issue #205 dependency declaration; fleet dependency rule.
- **Alternatives considered**: Self-contained governance slice — rejected
  (would duplicate 204's ports/DI); claiming pi#12 — rejected (FR-011).

## D12 — Out-of-scope confirmations

- **Decision**: No second policy engine / approval dispatcher / MCP client
  / transcript / cassette / eval engine (FR-001, FR-004, FR-006, FR-007;
  SC-010). No browser package or host app imports (FR-012; SC-010). No
  Flutter (constitution VII). No global `GetIt.instance` reads in business
  logic (FR-004).
- **Rationale**: issue #205 "do not create a parallel runtime, provider
  loop, policy engine, MCP tool model, session/task model, or approval
  dispatcher"; 204 FR-004 / FR-008.
- **Alternatives considered**: Carrying `LlmToolLoop` / `MissionRunner` /
  the existing MCP client forward — rejected (204 FR-004 explicitly
  forbids; this spec extends the new wrapper, not the old loop).