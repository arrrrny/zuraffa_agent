# Contract: Governance hooks

**Feature**: specs/176-zuraffa-runtime-wrapper | **Date**: 2026-11-22

Governance is implemented through pi primitives (FR-009, plan §7.4): pi
`beforeTool` hooks enforce allowlists, deny-lists, risk tiers, and approval
gates; pi `afterTool`/provider-request hooks enforce minimization, PII
scrubbing, artifact references, and redaction. The wrapper supplies the
hook bodies; pi supplies the execution semantics.

## beforeTool hook

```dart
Future<BeforeToolCallResult?> Function(BeforeToolCallContext ctx, {bool Function()? isAborted})
```

Behavior:
1. Look up the tool's risk tier from `GovernancePolicy.riskTiers`.
2. If tool is in `toolDenyList` OR tier requires approval and approval is
   denied → return a typed rejection (denial happens BEFORE execution, SC-005).
3. Otherwise allow (return null / continue).

## afterTool hook

```dart
Future<AfterToolCallResult?> Function(AfterToolCallContext ctx, {bool Function()? isAborted})
```

Behavior:
1. Apply `RedactionRule` scrubbing to the tool result content.
2. If any sanitizer throws → fail closed: return a typed failure outcome; the
   unredacted content never reaches the model (FR-009).
3. Oversized results → store via `AgentArtifactPort` and replace inline bytes
   with an `AgentArtifactDescriptor` reference.

## Audit

Every commit/submission/tool-call/provider event is recorded through
`AgentTelemetryPort` as an `AgentAuditRecord` (phase, outcome, redacted) —
never with secrets by default (plan §7.4).

## Extension installation

`PiExtensionBootstrap` installs generic Zuraffa extensions (audit,
telemetry, artifacts, MCP adaptation, evaluation) and host-provided
extensions into pi's registry. It never re-implements pi's extension system
(FR-005, plan §7.3).