# Phase 1 Data Model: Zuraffa runtime wrapper around pi

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

All model-layer types (entities, enums, value objects) are Zorphy-generated
(constitution IX). This document records the logical fields and relationships;
the generated code lives wherever `zfa entity create` writes it — the standard
`lib/src/domain/entities/` path. Nothing here duplicates a pi type (FR-003):
pi messages/tasks/submissions/sessions are consumed, never re-modeled, and no
wrapper-owned stand-in exists for a pi#12 type.

## Entities

### AgentRuntimeConfig (value object)
Configuration the host injects to open a runtime.
- `modelProvider`: String — pi model/provider selector (e.g. `"openai"`).
- `modelId`: String — model identifier passed to pi `Model`.
- `systemPrompt`: String? — optional system prompt.
- `thinkingLevel`: String? — optional pi `ThinkingLevel` name.
- `toolNames`: List<String> — host-contributed tool names to register.
- Validation: `modelProvider` and `modelId` non-empty. Tool names are NOT
  validated against a known set: pi is the registry of tools, the wrapper has
  no tool catalog, and a name that resolves to no tool is pi's diagnostic to
  raise.

### AgentPortRegistry (value object)
The bundle of host-injected ports (FR-006).
- `credentials`: AgentCredentialPort
- `storage`: AgentStoragePort
- `egress`: AgentEgressPort
- `telemetry`: AgentTelemetryPort
- `artifacts`: AgentArtifactPort
- `approvals`: AgentApprovalPort
- `lifecycle`: AgentLifecyclePort

All seven are **required, non-nullable** constructor arguments. A missing port
is therefore a compile error at the composition root, not a runtime outcome —
which is what FR-006's "no global `GetIt.instance` fallback" means in practice.
There is no `AgentConfigurationOutcome.missingPort`: the type system already
proves it unreachable, so the contract does not advertise a check it cannot
perform.

### ZuraffaExtension (value object)
The composition unit the extension seam installs (FR-009). It carries hook
bodies, never policy:
- `id`: String — stable extension identifier for diagnostics.
- `beforeToolCall`: `Future<BeforeToolCallResult?> Function(BeforeToolCallContext, {bool Function()? isAborted})?`
- `afterToolCall`: `Future<AfterToolCallResult?> Function(AfterToolCallContext, {bool Function()? isAborted})?`
- `transformContext`: `Future<List<AgentMessage>> Function(List<AgentMessage>, {bool Function()? isAborted})?`
- `convertToLlm`: `Future<List<Map<String, dynamic>>> Function(List<AgentMessage>)?`

Every field is nullable: an extension contributes the hooks it needs, and the
bootstrap composes the non-null ones into the opened runtime's `AgentOptions`.
These are pi's own typedefs — the wrapper aliases nothing.

### Governance entities — NOT in this feature
`GovernancePolicy`, `RiskTier`, `RedactionRule` and the audit records they
imply are issue #205's data model. They arrive as one `ZuraffaExtension`
installed through the seam above; this package defines none of them, and
`data-model.md` no longer lists them (spec §Out of scope, FR-009).

## Relationships

- `AgentRuntimeConfig` + `AgentPortRegistry` → consumed by
  `AgentRuntimeFactory` to open a pi runtime.
- `ZuraffaExtension`s → composed by `ExtensionBootstrap` into the pi
  `AgentOptions` handed to `PiRuntimeAdapter.open(...)`.
- `AgentArtifactDescriptor` → returned by `AgentArtifactPort.store`, so the
  host persists it; the wrapper stores nothing. Audit records are #205's
  model, not this feature's.

## State transitions

- Runtime lifecycle (via `AgentLifecyclePort`): `unopened → opening → open →
  closing → closed`; a failed open yields `closed` with the pi error surfaced
  (no wrapper-authored outcome type).
- Durable work (submissions, watches, tasks, approvals) has no wrapper-side
  transition table: those states belong to pi#12 and this document does not
  restate them (FR-010).
