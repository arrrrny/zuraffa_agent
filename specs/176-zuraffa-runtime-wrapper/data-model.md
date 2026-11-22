# Phase 1 Data Model: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

All model-layer types (entities, enums, value objects) are Zorphy-generated
(constitution IX). This document records the logical fields and relationships;
the generated code lives under `lib/src/domain/entities/`. Nothing here
duplicates a pi type (FR-003): pi messages/tasks/submissions/sessions are
consumed, never re-modeled.

## Entities

### AgentRuntimeConfig (value object)
Configuration the host injects to open a runtime.
- `modelProvider`: String — pi model/provider selector (e.g. `"openai"`).
- `modelId`: String — model identifier passed to pi `Model`.
- `systemPrompt`: String? — optional system prompt.
- `thinkingLevel`: String? — optional pi `ThinkingLevel` name.
- `toolNames`: List<String> — host-contributed pi tool names to register.
- Validation: `modelProvider` and `modelId` non-empty; unknown tool names are
  a typed configuration outcome (FR-003).

### AgentPortRegistry (value object)
The bundle of host-injected ports (FR-006).
- `credentials`: AgentCredentialPort
- `storage`: AgentStoragePort
- `egress`: AgentEgressPort
- `telemetry`: AgentTelemetryPort
- `artifacts`: AgentArtifactPort
- `approvals`: AgentApprovalPort
- `lifecycle`: AgentLifecyclePort
- Validation: all ports non-null; a missing port is a typed
  `AgentConfigurationOutcome.missingPort(portName)` (SC-001 scenario 2).

### GovernancePolicy (entity, zfa-generated)
Product-neutral governance consumed by pi hooks (FR-009).
- `id`: String (uuid)
- `toolAllowList`: List<String> — tool names permitted to execute.
- `toolDenyList`: List<String> — tool names rejected before execution.
- `riskTiers`: Map<String, RiskTier> — tool name → tier.
- `redactionRules`: List<RedactionRule> — PII scrubbing rules.
- `requireApprovalForTiers`: List<RiskTier> — tiers gated by approval.
- Validation: allow ∩ deny = ∅; every risk tier is a known `RiskTier`.

### RiskTier (enum, zfa-generated)
- `low`, `medium`, `high`, `critical`
- Consumed by `beforeTool` hooks for allow/deny/approval decisions.

### RedactionRule (value object)
- `pattern`: String — regex or named PII pattern (e.g. `email`, `phone`).
- `replacement`: String — redaction token.
- Validation: `pattern` compiles; a failed sanitizer fails closed (FR-009).

### AgentAuditRecord (entity, zfa-generated)
- `id`: String (uuid)
- `at`: DateTime (UTC)
- `phase`: String — commit/submission/tool-call/provider event (plan §7.4).
- `outcome`: String — typed outcome name.
- `redacted`: bool — whether content was redacted before recording.
- Validation: no secrets by default (plan §7.4 audit row).

### AgentArtifactDescriptor (entity, zfa-generated)
- `id`: String (uuid)
- `kind`: String — e.g. `screenshot`, `pdf`, `oversized-result`.
- `reference`: String — opaque artifact reference (never inline bytes).
- `createdAt`: DateTime (UTC).

## Relationships

- `AgentRuntimeConfig` + `AgentPortRegistry` → consumed by
  `AgentRuntimeFactory` to open a pi runtime.
- `GovernancePolicy` → installed by `PiExtensionBootstrap` as pi
  `beforeTool`/`afterTool` hooks.
- `AgentAuditRecord` / `AgentArtifactDescriptor` → produced by governance and
  telemetry adapters; persisted via injected ports, not by the wrapper.
- No entity references a pi type; the mapping to pi types lives only in
  `src/pi/` adapters (FR-005).

## State transitions

- Runtime lifecycle (via `AgentLifecyclePort`): `unopened → opening → open →
  closing → closed`; a failed open yields `closed` with a typed outcome.
- Approval gate (durable, pi#12): `requested → granted | denied | expired`.
  Before pi#12 lands this is represented by the wrapper-owned
  `AgentApprovalPort` interface only; no durable gate is claimed.