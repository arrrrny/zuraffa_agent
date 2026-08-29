# Feature Specification: R3: MCP Transport Resilience — wire seam, reconnect, adapter, cache

**Branch**: `082-mcp-transport-resilience` (off master `29b7fef`) | **Date**: 2026-08-29

**Status**: Draft → implemented on this branch

**Input**: User description: "R3: MCP Transport Resilience — wire seam, reconnect,
adapter, cache. Stateless McpWire seam, exponential-backoff reconnect policy, a tool
descriptor, a registry adapter using the `mcp:<server>:<tool>` namespace, a sealed
call-result, and a TTL listing cache. Parent epic: R3 tools & MCP client (issue #4).
Scope: make the MCP transport resilient to transient failures… Cover backoff caps,
reconnect storms, and cache invalidation."

## Summary

The R3 transport components already exist from specs 015 (mcp-client) and 049
(mcp_transport): the stateless `McpWire` seam, `McpReconnectPolicy`
(exponential backoff + cap + maxAttempts), `McpToolDescriptor`, `McpToolAdapter`
(registering tools under `mcp:<serverId>:<toolName>`), the sealed `McpCallResult`
union, and the TTL `ToolListingCache`. What R3 issue #93 asks for that the tree
does not yet guarantee:

1. **A recovered transport can serve a stale tool listing.** The cache
   invalidates on TTL expiry, on `onToolsChanged`, and on explicit
   `invalidate()` — but NOT when the client recovers from a drop. While the
   transport was severed the server may have added/removed tools; the missed
   `tools_changed` notification is gone with the old connection, so the cache
   would keep serving the pre-drop listing for up to the full TTL
   (default 60s). There is also no client surface on which a consumer could
   react to a recovery at all.
2. **The resilience semantics are unguarded at the edges.** Three behaviors
   hold in the code but have no test pinning them, so a refactor could break
   them silently: (a) jitter never pushes a backoff delay past the cap — the
   existing jitter test only asserts the looser `cap * (1 + jitter)` bound;
   (b) a reconnect storm is terminal — after `maxAttempts` the client is
   `failed` and never schedules another delay (no zombie reconnect loop), and
   a post-failure `callTool` adds no further delays; (c) the TTL boundary is
   exact — an entry aged exactly `maxAge` is already stale (freshness is
   `age < maxAge`).

This spec closes both: it adds `McpClient.onReconnected` (fired once per
successful recovery; empty for the in-proc client which cannot drop), wires
`ToolListingCache` to invalidate on it, and pins the three edge semantics with
tests guarded by deliberate mutants.

**Out of scope**: changing the backoff formula or configs themselves
(`McpReconnectPolicyConfig.sse/.stdio` stay as 015 shipped them); auth-token
rotation semantics (015 FR-003, already tested); the `io_*` transport adapters
(purity-allowlisted, unchanged).

## Files

- `lib/src/mcp/mcp_client.dart` — EDIT: interface gains `onReconnected`
  (additive; the three in-tree implementors follow).
- `lib/src/mcp/sse_mcp_client.dart` — EDIT: broadcast controller; emit after
  each recovery-`connected` transition in `_callWithReconnect`; close on
  `disconnect`.
- `lib/src/mcp/stdio_mcp_client.dart` — EDIT: same wiring.
- `lib/src/mcp/in_proc_mcp_client.dart` — EDIT: `onReconnected` is a never-
  emitting stream (no transport to drop).
- `lib/src/mcp/tool_listing_cache.dart` — EDIT: subscribe
  `client.onReconnected` → `invalidate()`; cancel in `dispose()`.
- `test/mcp/mcp_082_resilience_test.dart` — NEW: the RED behaviors (reconnect
  emission + cache invalidation, unit and end-to-end) and the pins (jitter
  clamp, storm terminality, TTL boundary).
- `test/mcp/tool_listing_cache_test.dart`, `test/mcp/mcp_tool_adapter_test.dart`
  — EDIT: their `McpClient` fakes grow `onReconnected` (compile fix, no
  semantic change).
- `specs/082-mcp-transport-resilience/` — this artifact set.

## User scenarios

### US1 — Survive a transient drop and learn about it (P1)

As the engine loop, I issue an MCP tool call; the wire drops mid-call; the
client recovers behind capped exponential backoff and — new — tells me it
recovered by firing `onReconnected` once, so my caches and diagnostics can
react instead of assuming continuity.

**Why this priority**: the recovery itself already exists (015 SC-002/003);
the missing half is the observability of the recovery, which US2 builds on.

**Independent test**: `FakeMcpWire` programmed to drop once then answer → the
call returns its real result AND `onReconnected` fired exactly once, with the
backoff delay sequence observed.

### US2 — Never serve a pre-drop tool listing after a reconnect (P1)

As a registry consumer (`McpToolAdapter` + `ToolListingCache`), when the
client recovers from a drop I want the cached listing invalidated, because the
server may have changed its tool set while I was disconnected; the next
`getOrRefresh()` re-lists even though the TTL had not expired.

**Why this priority**: stale registrations are silent wrongness — the engine
would dispatch to tools that no longer exist (or miss new ones) for up to a
full TTL window after every drop.

**Independent test**: cache primed and served within TTL → recovery fires
`onReconnected` → next `getOrRefresh()` hits the client again
(`listToolsCallCount` increments) despite a fresh TTL entry.

### US3 — Reason about storms and boundaries (P2)

As an operator, I rely on three pinned invariants: jitter never pushes a
backoff delay past the configured cap; a persistent storm stops after
`maxAttempts` delays leaving the client `failed` with no further delays
scheduled (a post-failure call adds none); a cache entry aged exactly
`maxAge` is stale.

**Why this priority**: these are the guard-rails that keep transient-failure
handling predictable; they hold today but are one refactor away from silent
breakage.

**Independent test**: each invariant pinned by a dedicated test guarded by a
killer mutant.

## Requirements

### Functional requirements

- **FR-001**: `McpWire` remains a stateless transport seam — `open` / `close`
  / `send` / `notifications` / `isOpen` only; reconnection state lives in the
  client, never on the wire (015 architecture, pinned by the existing wire /
  A6 tests; no new wire members).
- **FR-002**: Reconnect backoff is exponential with a hard cap, and with
  jitter enabled no applied delay exceeds `config.cap` (the jitter scale is
  clamped to the cap).
- **FR-003**: A reconnect storm is bounded: one failure episode schedules at
  most `config.maxAttempts` backoff delays; on exhaustion the client
  transitions to `McpClientState.failed`; after that transition no further
  delays are scheduled (a subsequent `callTool` returns
  `McpCallError('client-not-connected')` and the recorded delay count is
  unchanged).
- **FR-004** (new): `McpClient` exposes `Stream<void> onReconnected`. SSE and
  stdio clients fire it exactly once per successful recovery (the
  reconnecting → connected transition inside `_callWithReconnect`), never on
  the initial `connect()`, and close it on `disconnect()`. `InProcMcpClient`
  exposes a never-emitting stream.
- **FR-005** (new): `ToolListingCache` subscribes to
  `client.onReconnected` and invalidates its entry when that fires; the
  subscription is cancelled by `dispose()`.
- **FR-006**: Cache freshness is `age < maxAge` — an entry aged exactly
  `maxAge` is stale and the next `getOrRefresh()` re-lists.
- **FR-007**: Tool calls resolve through `McpToolAdapter` under the
  `mcp:<serverId>:<toolName>` namespace and surface as the sealed
  `McpCallResult` union (`McpCallOk` / `McpCallError`) — never as a thrown
  exception from the client surface (015 FR; pinned by existing adapter /
  client tests cited in the test list).
- **FR-008**: Gates — `dart analyze` reports no new issues relative to the
  master baseline (3 pre-existing, all out of scope); the full `dart test`
  suite is green.

### Key entities

- `McpClient` — gains `onReconnected` (the recovery signal).
- `SseMcpClient` / `StdioMcpClient` — emit `onReconnected` per recovery.
- `InProcMcpClient` — `onReconnected` never emits.
- `ToolListingCache` — invalidation set = { TTL expiry, `onToolsChanged`,
  `onReconnected`, explicit `invalidate()` }.
- `McpReconnectPolicy` — unchanged formula; pinned clamp + exhaustion
  semantics.

## Success criteria

- **SC-001**: Mid-call drop → recovery → the call returns its real result and
  `onReconnected` fired exactly once (US1).
- **SC-002**: Recovery invalidates the cache: the next `getOrRefresh()`
  re-lists despite a fresh TTL entry, end-to-end through a real
  `SseMcpClient` + `ToolListingCache` pair (US2).
- **SC-003**: Storm terminality, jitter-cap clamp, and the exact TTL boundary
  each pinned by a test that a deliberate mutant kills (US3).
- **SC-004**: Gates green (FR-008).

## Dependencies

- Builds on: spec 015 (mcp-client: wire, clients, cache, adapter), spec 049
  (mcp_transport entity), spec 003 A6 (drop-resume acceptance) — all on
  master `29b7fef`.
- Independent of: the 075–078 event/memory arc and every other subsystem
  (different files, no shared edits beyond the `mcp/` directory).
