# Contract: Host-injection ports (consumed from 204)

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

The wrapper's host-injection ports are defined in spec 204
(`specs/176-zuraffa-runtime-wrapper/contracts/host-ports.md`). This spec
consumes `AgentTelemetryPort`, `AgentArtifactPort`, and
`AgentApprovalPort` and adds no new ports. Business logic depends on these
interfaces, never on `GetIt.instance`, a concrete WebView, an MCP socket,
or a provider SDK.

## AgentTelemetryPort (consumed; 204)

```dart
abstract class AgentTelemetryPort {
  void recordSpan(AgentSpan span);
  void recordEvent(AgentTelemetryEvent event);
  void recordError(Object error, StackTrace? trace);
}
```

This spec's `TelemetryAdapter` and `AuditRecorder` write pi commit / phase
/ submission / tool-call / provider-event records through this port.
Secret-like payloads are redacted by `SecretScrubber` before persistence
(FR-005, SC-006). An opt-in `includeUnredactedPayloads: true` is explicitly
labeled in the audit row.

## AgentArtifactPort (consumed; 204)

```dart
abstract class AgentArtifactPort {
  Future<AgentArtifactDescriptor> store(String kind, List<int> bytes);
  Future<AgentArtifactRef?> resolve(String id);
}
```

This spec's `ArtifactRouter` persists oversized results via this port and
returns an `AgentArtifactRef` (FR-007, SC-007). A missing port yields a
typed `missingArtifactPort` outcome — the result is not silently
truncated into the model.

## AgentApprovalPort (consumed; 204)

```dart
abstract class AgentApprovalPort {
  Future<ApprovalDecision> request(AgentApprovalRequest request);
}
```

This spec's `ApprovalPortAdapter` wires the host's approval presentation
through this port; the wrapper never presents UI and never reads a global
service locator (FR-004, SC-005). A missing port yields a typed
`missingApprovalPort` outcome when a tool requires approval.

## Contract rule

Each port MUST have a pure-Dart in-memory adapter under
`lib/src/data/` that passes the same contract suite as the production
adapter (FR-009, SC-009). The suite lives in `test/` and runs against both
adapters with no branching.

## What this spec adds (no new ports)

- `ApprovalGate` (wrapper-owned interface, pi#12-gated): pi signal +
  memoized deadline + parked tool; represented by the interface only
  before pi#12 (FR-011, SC-011).
- `SecretScrubber` (pure-Dart utility): default secret patterns + opt-in
  labeling; not a port.
- `ArtifactRouter` (service composing `AgentArtifactPort`): not a port.
- `McpAdapter` (delegation to pi-mcp): not a port; pi-mcp owns transport.
- `EvalAdapter` (delegation to pi-evals + Zuraffa reporting): not a port;
  pi-evals owns replay.