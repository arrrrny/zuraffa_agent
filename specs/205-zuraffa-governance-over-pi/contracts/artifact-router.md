# Contract: Artifact router

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

Oversized results are handled by pi tool-result hooks plus Zuraffa
`AgentArtifactPort` stores (FR-007, issue #205 "oversized results use pi
tool-result hooks plus Zuraffa artifact stores"). The router never
truncates into the model.

## Shape (logical)

```dart
/// Intercepts oversized results in the afterTool hook, persists bytes via
/// AgentArtifactPort, and replaces inline content with a reference.
class ArtifactRouter {
  ArtifactRouter({
    required AgentArtifactPort port,
    required int threshold,          // from GovernancePolicy
  });

  /// Returns either the original content (under threshold) or a summary +
  /// AgentArtifactRef (over threshold).
  Future<ArtifactRoutingOutcome> route(String toolName, List<int> bytes);
}

sealed class ArtifactRoutingOutcome {
  String get inline;                 // under threshold
  AgentArtifactRef get artifactRef;  // over threshold
  MissingArtifactPort get missingArtifactPort;
}
```

## Behavior

1. If `bytes.length <= threshold` → return inline content unchanged.
2. If `bytes.length > threshold` → persist via
   `AgentArtifactPort.store(kind: 'oversized-result', bytes)` and return a
   summary + `AgentArtifactRef` (FR-007, SC-007).
3. If `AgentArtifactPort` is missing → return a typed `missingArtifactPort`
   outcome; the result is NOT silently truncated into the model (edge case).
4. Record an `AgentAuditRecord` (phase `artifact-route`, outcome, redacted)
   via `AgentTelemetryPort`.

## Threshold source

`GovernancePolicy.oversizedResultThreshold` (default 256 KiB). A host may
override per policy; the router uses the merged policy value.

## Contract rule

The router has a pure-Dart in-memory `AgentArtifactPort` adapter and a
production adapter; the contract suite in `test/artifacts/` runs against
both with no branching (FR-009, SC-009).