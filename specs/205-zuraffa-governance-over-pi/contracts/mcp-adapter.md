# Contract: MCP adapter (pi-mcp delegation)

**Feature**: specs/205-zuraffa-governance-over-pi | **Date**: 2026-11-22

MCP adaptation delegates to pi-mcp when available; only generic
DI/governance behavior (tool name prefixing, risk-tier wiring, telemetry
taps) remains in `zuraffa_agent` (FR-006, issue #205 "MCP adaptation uses
pi-mcp when available"). The wrapper ships no second MCP client.

## Shape (logical)

```dart
/// Thin delegation layer. pi-mcp owns transport, listing, and calls; the
/// wrapper contributes only governance/telemetry metadata.
class McpAdapter {
  McpAdapter({
    required McpDelegate delegate,   // pi-mcp when present
    required AgentTelemetryPort telemetry,
  });

  Future<List<McpTool>> listTools();
  Future<McpCallResult> callTool(String name, Map<String, Object?> args);
}
```

## Behavior

1. `listTools` / `callTool` delegate to `delegate` (pi-mcp) when present.
2. The wrapper contributes only:
   - tool name prefixing (`mcp__<server>__<tool>`) for governance lookup;
   - risk-tier wiring from `GovernancePolicy.riskTiers`;
   - telemetry taps via `AgentTelemetryPort` (SC-006).
3. When pi-mcp is unavailable → the adapter fails with a typed
   `mcpUnavailable` outcome (SC-008); the wrapper does not fall back to a
   second client.
4. A host that registers an MCP server overlapping a pi built-in tool is
   governed by `GovernancePolicy` (default-deny resolves the overlap); the
   wrapper does not silently drop either (edge case).

## What stays in zuraffa_agent

- Tool name prefixing and risk-tier lookup.
- Telemetry tap (audit + metrics) for MCP listing/calls.
- Default-deny governance decision for unregistered MCP tools.

## What delegates to pi-mcp

- Transport (SSE / stdio / in-proc).
- Listing and call execution.
- Reconnect, auth, and transport resilience (pi-mcp owns those).

## Contract rule

`McpAdapter` has a pure-Dart in-memory `McpDelegate` (scripted pi-mcp) and
a production pi-mcp adapter; the contract suite in `test/mcp/` runs
against both with no branching (FR-009, SC-009).