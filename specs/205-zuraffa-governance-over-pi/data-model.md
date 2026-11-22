# Phase 1 Data Model: Zuraffa governance extensions over pi

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

All model-layer types (entities, enums, value objects) are Zorphy-generated
(constitution IX). This document records the logical fields and relationships;
the generated code lives under
`lib/src/governance/entities/`. Nothing here duplicates a pi type
(FR-008): pi messages/tasks/submissions/sessions are consumed, never
re-modeled.

## Entities

### GovernancePolicy (entity, zfa-generated)
Product-neutral governance consumed by pi hooks (FR-001).
- `id`: String (uuid)
- `toolAllowList`: List<String> — tool names permitted to execute.
- `toolDenyList`: List<String> — tool names rejected before execution.
- `riskTiers`: Map<String, RiskTier> — tool name → tier.
- `redactionRules`: List<RedactionRule> — PII scrubbing rules.
- `requireApprovalForTiers`: List<RiskTier> — tiers gated by approval.
- `oversizedResultThreshold`: int? — bytes above which a result is
  artifact-routed (FR-007).
- Validation: allow ∩ deny = ∅; every risk tier is a known `RiskTier`.
- Default-deny: a tool in neither allow nor deny is denied (FR-002).

### RiskTier (enum, zfa-generated)
- `low`, `medium`, `high`, `critical`
- Consumed by `beforeTool` hooks for allow/deny/approval decisions.

### RedactionRule (value object, zfa-generated)
- `name`: String — e.g. `email`, `phone`, `awsKey`, `bearerToken`,
  `privateKeyHeader`, `jwt`.
- `pattern`: String — regex source.
- `replacement`: String — redaction token (default `[REDACTED:<name>]`).
- Validation: `pattern` compiles; a failed sanitizer fails closed (FR-003).

### AgentAuditRecord (entity, zfa-generated)
- `id`: String (uuid)
- `at`: DateTime (UTC)
- `phase`: String — commit/submission/tool-call/provider event/approval.
- `outcome`: String — typed outcome name (allow, deny, redact, failClosed,
  approvalGranted, approvalDenied, approvalExpired, mcpUnavailable, …).
- `redacted`: bool — whether content was redacted before recording.
- `unredactedOptIn`: bool — host explicitly opted into raw payloads.
- `error`: String? — typed failure name when outcome is a failure.
- Validation: no secrets by default (FR-005, SC-006).

### AgentArtifactDescriptor (entity, zfa-generated)
- `id`: String (uuid)
- `kind`: String — e.g. `screenshot`, `pdf`, `oversized-result`.
- `reference`: String — opaque artifact reference (never inline bytes).
- `byteSize`: int — original byte count.
- `createdAt`: DateTime (UTC).

### AgentEvaluationReport (entity, zfa-generated)
- `id`: String (uuid)
- `at`: DateTime (UTC)
- `suite`: String — eval/cassette suite name.
- `case`: String — case name.
- `outcome`: String — pass/fail + typed failure name.
- `redactedTranscript`: String? — redacted replay transcript reference.
- Validation: no raw payloads; references only (FR-007, FR-005).

## Value objects (not entities)

### AgentRuntimeConfig (from 204; consumed here)
Already defined in 204 data-model.md; this spec adds no fields. The
governance slice reads `modelProvider` / `modelId` only to route
provider-request hooks.

### AgentPortRegistry (from 204; consumed here)
Already defined in 204 data-model.md (`credentials`, `storage`, `egress`,
`telemetry`, `artifacts`, `approvals`, `lifecycle`). This spec consumes
`telemetry`, `artifacts`, `approvals`; it does not re-declare the ports.

## Relationships

- `GovernancePolicy` → installed by `PiExtensionBootstrap` as pi
  `beforeTool` / `afterTool` / provider-request hooks (FR-001).
- `RedactionRule` → applied by `ResultMinimizationHooks` and
  `SecretScrubber` (FR-003, FR-005).
- `AgentAuditRecord` → produced by `AuditRecorder` for every hook outcome
  (FR-005); persisted via `AgentTelemetryPort`.
- `AgentArtifactDescriptor` → produced by `ArtifactRouter` for oversized
  results (FR-007); persisted via `AgentArtifactPort`.
- `AgentEvaluationReport` → produced by `EvalAdapter` on top of pi-evals
  replay (FR-007); recorded via `AgentTelemetryPort`.
- No entity references a pi type; the mapping to pi types lives only in
  `src/pi/` adapters (FR-011).

## State transitions

- Approval gate (durable, pi#12-gated): `requested → granted | denied |
  expired`. Before pi#12 lands this is represented by the wrapper-owned
  `ApprovalGate` interface only; no durable gate is claimed (FR-011,
  SC-011).
- Hook outcome: `allow → execute`, `deny → typed denial`, `redact →
  scrubbed content`, `failClosed → typed failure` (FR-002, FR-003).
- Oversized result: `inline → artifactRef` (FR-007).
- Eval replay: `recorded → replayed → reported` (FR-007).