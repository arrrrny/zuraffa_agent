# Contract: Tool governance hooks

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Governance is implemented through pi primitives (FR-001, architecture
plan §7.4): pi `beforeTool` hooks enforce allowlists, deny-lists,
argument guards, risk tiers, and approval gates; pi `afterTool` hooks
enforce minimization, PII scrubbing, artifact references, and redaction;
provider-request hooks enforce egress sanitization. The wrapper supplies
the hook bodies; pi supplies the execution semantics.

## beforeTool hook

```dart
Future<BeforeToolCallResult?> Function(BeforeToolCallContext ctx, {bool Function()? isAborted})
```

Behavior (in order):
1. Resolve the tool's risk tier from `GovernancePolicy.riskTiers` (default
   `RiskTier.critical` for unregistered tools).
2. Apply deterministic policy merge when multiple policies are installed:
   deny wins over allow; stricter risk tier wins; redaction rules union.
   Record the merge in the audit row.
3. If the tool is in `toolDenyList` OR is not in `toolAllowList` (default-deny,
   FR-002) → return a typed rejection. Denial happens BEFORE execution
   (SC-001, SC-003).
4. If the tool's tier is in `requireApprovalForTiers` → gate through
   `ApprovalGate` (pi signal + memoized deadline + host `AgentApprovalPort`,
   FR-004). A deny or timeout yields a typed denial/expiry outcome
   (SC-004). Before pi#12 lands this returns `durableUnavailable` (SC-011).
5. Otherwise allow (return null / continue).

## afterTool hook

```dart
Future<AfterToolCallResult?> Function(AfterToolCallContext ctx, {bool Function()? isAborted})
```

Behavior:
1. Apply `RedactionRule` scrubbing to the tool result content (FR-003).
2. If any sanitizer throws → fail closed: return a typed failure outcome;
   the unredacted content never reaches the model (SC-002).
3. If the result is over `GovernancePolicy.oversizedResultThreshold` →
   store via `AgentArtifactPort` and replace inline bytes with an
   `AgentArtifactDescriptor` reference (FR-007, SC-007).
4. Record an `AgentAuditRecord` (phase, outcome, redacted) via
   `AgentTelemetryPort` — never with secrets by default (FR-005, SC-006).

## Provider-request hook

```dart
Future<ProviderRequestResult?> Function(ProviderRequestContext ctx)
```

Behavior:
1. Apply egress sanitization to the provider request payload using the same
   `RedactionRule` set as `afterTool` (FR-001, FR-003).
2. A sanitizer failure fails closed: no egress request is sent (SC-002).
3. Record an `AgentAuditRecord` (phase `provider-request`, redacted) via
   `AgentTelemetryPort`.

## Audit

Every hook outcome — allow, deny, redact, failClosed, approvalGranted,
approvalDenied, approvalExpired, durableUnavailable, mcpUnavailable — is
recorded through `AgentTelemetryPort` as an `AgentAuditRecord` (phase,
outcome, redacted, error) — never with secrets by default (FR-005,
SC-006).

## Extension installation

`PiExtensionBootstrap` (from 204) installs the generic Zuraffa extensions
(audit, telemetry, artifacts, MCP adaptation, evaluation) and host-provided
extensions into pi's registry. It never re-implements pi's extension
system (FR-011, plan §7.3 of 204).