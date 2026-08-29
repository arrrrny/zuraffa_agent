# Feature Specification: MCP Transport Resilience

**Feature Branch**: `082-mcp-transport-resilience`

**Created**: 2026-08-29

**Status**: Draft

**Input**: User description: "Well-defined spec for MCP transport resilience — the wire seam, reconnect policy, tool descriptor, registry adapter, call-result union, and listing cache — that is not yet covered by an existing spec (R3)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A stateless wire seam for MCP clients (Priority: P1)

The SSE and stdio MCP clients share a minimal transport seam (`McpWire`) so they can be unit-tested against a fake wire with no network or subprocess. The seam exposes `open`/`close` (idempotent), `send` (request/response RPC), and a `notifications` stream that carries `ToolsChanged`.

**Why this priority**: The seam is the foundation that makes every other resilience piece testable and keeps IO adapters isolated (constitution purity allowlist).

**Independent Test**: Can be fully tested with a fake `McpWire` asserting `open`/`close` are idempotent, `send` returns a typed response, and `notifications` emits `McpWireNotificationToolsChanged`.

**Acceptance Scenarios**:

1. **Given** a wire, **When** `open` is called twice then `close` twice, **Then** no error is raised and `isOpen` transitions correctly.
2. **Given** a request, **When** `send` is called, **Then** a `McpWireResponseOk` (payload map) or `McpWireResponseError` (code/message) is returned.

---

### User Story 2 - Reconnect with exponential backoff (Priority: P1)

When the SSE/stdio transport drops, the client reconnects using an injected `McpReconnectPolicy` (exponential backoff, factor, cap, maxAttempts, optional deterministic jitter). The policy tracks attempts, applies each delay via an injected `McpDelay`, and reports exhaustion.

**Why this priority**: Reconnect reliability is the headline resilience property (spec 015 SC-002/003: SSE within 5s, stdio within 10s).

**Independent Test**: Can be fully tested with a recording `McpDelay` and fixed seed, asserting the delay sequence and that `nextBackoff` returns false (and no further delay) once `exhausted`.

**Acceptance Scenarios**:

1. **Given** a policy with `initial=100ms, factor=2, cap=1s, maxAttempts=8`, **When** `nextBackoff` is called repeatedly, **Then** delays follow 100→200→400→... capped at 1s, total wall-time under 5s for SSE.
2. **Given** an exhausted policy, **When** `nextBackoff` is called, **Then** a `StateError` is thrown (callers must check `exhausted` first).
3. **Given** a successful reconnect, **When** `reset` is called, **Then** the next drop restarts backoff from `initial`.

---

### User Story 3 - Surface MCP tools into the engine registry (Priority: P2)

`McpToolAdapter` lists tools via `ToolListingCache`, registers each into the engine `ToolRegistry` under the `mcp:<serverId>:<name>` namespace, and keeps the registry in sync on `onToolsChanged` notifications (register new, unregister gone). `McpToolDescriptor` carries the static metadata; `McpCallResult` is the sealed ok/error outcome so failures never throw across the boundary.

**Why this priority**: Tool surfacing is what makes a remote MCP server useful to the engine; drift between server and registry must self-heal.

**Independent Test**: Can be fully tested with a fake client + fake registry, asserting initial sync registers namespaced tools and a tools-changed notification re-lists and diffs correctly.

**Acceptance Scenarios**:

1. **Given** a client advertising tools `fs.read`, `fs.write`, **When** the adapter syncs with `serverId=raptorr`, **Then** the registry contains `mcp:raptorr:fs.read` and `mcp:raptorr:fs.write`.
2. **Given** a synced adapter, **When** the server drops `fs.write`, **Then** on the next notification `mcp:raptorr:fs.write` is unregistered while `fs.read` remains.

---

### Edge Cases

- `McpWire.send` of an unknown method maps to `McpWireResponseError`, never an untyped throw.
- `McpReconnectPolicy.nextBackoff` after exhaustion throws `StateError` (programmer error guard).
- `McpToolDescriptor` equality deep-compares `paramsSchema` (null-safe); two descriptors differ if schemas differ.
- `McpToolAdapter.sync` after `dispose` throws `StateError`; auto-sync failures are swallowed (next notification retries), manual `sync` re-throws.
- `ToolListingCache` returns an unmodifiable list; TTL expiry (default 60s) and explicit `invalidate()` both force a re-list; `dispose` cancels the subscription.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `McpWire` MUST provide `open`/`close` (idempotent), `send(McpWireRequest)→McpWireResponse`, a `notifications` stream (incl. `ToolsChanged`), and `isOpen`.
- **FR-002**: `McpReconnectPolicy` MUST compute exponential backoff (`initial * factor^(attempt-1)`, clamped to `cap`) with optional deterministic jitter; `nextBackoff` applies the delay (via injected `McpDelay`) and returns `true` until `exhausted`; MUST throw `StateError` if called after exhaustion; `reset()` restarts the counter.
- **FR-003**: `McpToolDescriptor` MUST hold `name`, `description`, optional `paramsSchema`, with equality deep-comparing `paramsSchema`.
- **FR-004**: `McpToolAdapter` MUST surface tools into `ToolRegistry` under `mcp:<serverId>:<name>`, initial-sync list+cache, and on `onToolsChanged` re-list and diff (register new, unregister gone); `startAutoSync` MUST be idempotent; `dispose` MUST tear down.
- **FR-005**: `McpCallResult` MUST be a sealed union of `McpCallOk(result map)` / `McpCallError(code, message)`; `McpClient.callTool` MUST NOT throw — failures surface as `McpCallError`.
- **FR-006**: `ToolListingCache` MUST cache `listTools` with TTL `maxAge` (default 60s), invalidate on `onToolsChanged` and explicit `invalidate()`, return an unmodifiable cached list when fresh, and `dispose` MUST cancel the subscription.

### Key Entities

- **McpWire / McpWireRequest / McpWireResponse / McpWireNotification**: the transport seam and its sealed message families.
- **McpReconnectPolicy / McpReconnectPolicyConfig**: backoff policy with injected clock/delay/seed.
- **McpToolDescriptor**: static per-tool metadata advertised by a server.
- **McpToolAdapter**: bridges an `McpClient` to the engine `ToolRegistry`.
- **McpCallResult**: sealed ok/error outcome of a tool invocation.
- **ToolListingCache**: TTL cache over `listTools`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (spec 015 SC-002/003): SSE reconnects after a drop within 5s; stdio restarts after a crash within 10s.
- **SC-002**: A `tools-changed` notification updates the registry set without dropping unrelated tools.
- **SC-003**: `ToolListingCache` honors both TTL expiry and explicit/invalidation-triggered re-list; no redundant `listTools` within the TTL.
- **SC-004**: `McpClient.callTool` never throws across the boundary — every failure is a typed `McpCallError`.

## Assumptions

- The IO adapters (`IoSseMcpTransport`, `IoStdioMcpTransport`) live in sibling `io_*.dart` files on the pipeline purity allowlist; this spec owns the pure seam + logic only.
- Reconnect/auth-callback rotation lives on the MCP client, not on `McpWire` (the wire is stateless).
- This feature maps to **R3 (tools & MCP client, issue #4)** as the resilience layer over spec 015's client.
