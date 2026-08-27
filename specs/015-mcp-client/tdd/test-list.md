# Test List: MCP Client

---
feature: 015-mcp-client
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 5 # success criteria SC-001..SC-003 + the two User-Stories acceptance scenarios US1..US4 in spec.md
planned_at: feat/specs-015-022-023-024
updated_at: HEAD
suite_baseline: 529 passed # parent commit baseline; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Outer loop: acceptance behaviors

One per acceptance scenario / success criterion in `spec.md`, through the feature's public API (`McpClient`, `McpToolAdapter`, `ToolListingCache`).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | In-proc round-trip works with zero serialization — a tool registered via `InProcMcpClient.registerTool` is invoked with identical arguments and returns the callback's map | SC-001, US1 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::spec-015 — InProcMcpClient::in-proc round-trip works with zero serialization (SC-001)` |
| A2  | A connection drop mid-call triggers automatic reconnect with exponential backoff — SSE policy first-retry delay lands within 5s | SC-002, US2-AC1, FR-002 | example | DONE | `test/mcp/sse_mcp_client_test.dart::spec-015 — SseMcpClient::a drop mid-call triggers reconnect within SSE backoff (SC-002)` + `test/mcp/mcp_reconnect_policy_test.dart::…::SSE first-retry delay (100ms) lands within 5s (SC-002)` |
| A3  | A token rotation callback is invoked on each reconnect — calls continue without rebuild | SC-002, US2-AC2, FR-003 | example | DONE | `test/mcp/sse_mcp_client_test.dart::spec-015 — SseMcpClient::auth callback is invoked on reconnect (FR-003 token rotation)` |
| A4  | stdio restart after crash — first-retry delay lands within 10s | SC-003, US3-AC1, FR-004 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::spec-015 — StdioMcpClient::a drop mid-call triggers reconnect within stdio backoff (SC-003)` + `test/mcp/mcp_reconnect_policy_test.dart::…::stdio first-retry delay lands within 10s (SC-003)` |
| A5  | Tool listing is cached and invalidated on server-reported changes — cache hits within TTL, misses after `onToolsChanged` | FR-005, US4-AC1, US4-AC2 | example | DONE | `test/mcp/tool_listing_cache_test.dart::spec-015 — ToolListingCache::onToolsChanged from the client invalidates the cache` + `…::first call hits the underlying client` + `…::second call within TTL returns the cached value (no second listTools)` + `…::after TTL expiry, the next call re-lists` |

## Inner loop: unit behaviors

### `lib/src/mcp/mcp_tool_descriptor.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `McpToolDescriptor` is an immutable value object with `name`, `description`, `paramsSchema?` and value equality | FR (descriptor shape) | example | DONE | implicit — covered by A5's tool fixtures (the equality / immutability is exercised when the cache compares lists) |

### `lib/src/mcp/mcp_call_result.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U2  | `McpCallResult` sealed family: `McpCallOk(result)` / `McpCallError(code, message)` — never throws; failures surface as values | FR (call-result shape) | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::callTool on unknown name returns McpCallError` + `…::callTool when client is disconnected returns McpCallError` + `…::a throwing tool callback surfaces as McpCallError` |

### `lib/src/mcp/mcp_wire.dart` (transport seam)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `McpWire` is a pure interface — request/response RPC + notifications stream — no dart:io dependency | FR-001 (seam), constitution VII | example | DONE | indirectly — `FakeMcpWire` in `test/mcp/_fake_wire.dart` implements the interface without dart:io |

### `lib/src/mcp/mcp_reconnect_policy.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | Backoff grows exponentially: 100ms, 200ms, 400ms, 800ms, then capped at 1s for SSE config | FR-002 | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::backoff grows exponentially under SSE config` |
| U5  | Backoff is capped at the configured cap (1s SSE / 2s stdio) | FR-002 | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::backoff is capped at 2s for stdio` |
| U6  | `exhausted` becomes true after `maxAttempts` retries | FR-002 | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::exhausted after maxAttempts retries` |
| U7  | `nextBackoff` after exhaustion throws `StateError` (programmer error) | FR-002 | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::nextBackoff after exhaustion throws StateError` |
| U8  | `reset()` restores the attempt counter | FR-002 | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::reset() restores the attempt counter` |
| U9  | Jitter stays within bounds `[delay*(1-jitter), delay*(1+jitter)]` under a fixed seed | FR-002 (jitter) | example | DONE | `test/mcp/mcp_reconnect_policy_test.dart::…::deterministic jitter stays within bounds` |

### `lib/src/mcp/in_proc_mcp_client.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U10 | `connect()` transitions `disconnected` -> `connected`; idempotent | FR-001 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::connect transitions disconnected -> connected` + `…::connect is idempotent` |
| U11 | `listTools()` returns the registered descriptors | FR-005 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::listTools returns the registered descriptors` |
| U12 | `registerTool` before connect does NOT emit `onToolsChanged` (no spam during setup) | FR-005 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::registerTool before connect does NOT emit onToolsChanged` |
| U13 | `registerTool` / `unregisterTool` after connect emits `onToolsChanged` | FR-005 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::registerTool after connect emits onToolsChanged` + `…::unregisterTool after connect emits onToolsChanged` |
| U14 | Registering a duplicate tool name throws `ArgumentError` | FR-001 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::registering a duplicate name throws ArgumentError` |
| U15 | `listTools()` / `callTool()` before connect surfaces typed errors (no throw) | FR-001 | example | DONE | `test/mcp/in_proc_mcp_client_test.dart::…::callTool when client is disconnected returns McpCallError` + `…::listTools when client is disconnected throws StateError` |

### `lib/src/mcp/tool_listing_cache.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U16 | First `getOrRefresh()` hits the underlying client | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::first call hits the underlying client` |
| U17 | Second `getOrRefresh()` within TTL returns the cached value (no second `listTools`) | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::second call within TTL returns the cached value (no second listTools)` |
| U18 | After TTL expiry, the next `getOrRefresh()` re-lists | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::after TTL expiry, the next call re-lists` |
| U19 | Explicit `invalidate()` forces the next call to re-list | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::explicit invalidate() forces the next call to re-list` |
| U20 | `onToolsChanged` from the client invalidates the cache | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::onToolsChanged from the client invalidates the cache` |
| U21 | `dispose()` cancels the `onToolsChanged` subscription | FR-005 | example | DONE | `test/mcp/tool_listing_cache_test.dart::…::dispose() cancels the onToolsChanged subscription` |

### `lib/src/mcp/sse_mcp_client.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U22 | `connect()` opens the wire and transitions to `connected` | FR-001, FR-002 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::connect opens the wire and transitions to connected` |
| U23 | `connect()` invokes the auth callback to fetch the bearer token | FR-003 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::connect invokes the auth callback to fetch the bearer token` |
| U24 | `listTools()` maps the wire's payload to descriptors | FR-005 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::listTools maps the wire payload to descriptors` |
| U25 | `callTool()` returns `McpCallOk` on wire success | FR-001 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::callTool returns McpCallOk on wire success` |
| U26 | `callTool()` returns `McpCallError` on wire error | FR-001 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::callTool returns McpCallError on wire error` |
| U27 | Exhausted retries transition the client to `failed` state | FR-002 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::exhausted retries transition the client to failed state` |
| U28 | `callTool()` when disconnected returns `McpCallError` | FR-001 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::callTool when disconnected returns McpCallError` |
| U29 | `onToolsChanged` relays wire tools-changed notifications | FR-005 | example | DONE | `test/mcp/sse_mcp_client_test.dart::…::onToolsChanged relays wire tools-changed notifications` |

### `lib/src/mcp/stdio_mcp_client.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U30 | `connect()` opens the wire and transitions to `connected` | FR-001, FR-004 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::…::connect opens the wire and transitions to connected` |
| U31 | `listTools()` maps the wire's payload to descriptors | FR-005 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::…::listTools maps the wire payload to descriptors` |
| U32 | `callTool()` returns `McpCallOk` on wire success | FR-001 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::…::callTool returns McpCallOk on wire success` |
| U33 | Exhausted retries transition the client to `failed` state | FR-004 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::…::exhausted retries transition the client to failed state` |
| U34 | `onToolsChanged` relays wire tools-changed notifications | FR-005 | example | DONE | `test/mcp/stdio_mcp_client_test.dart::…::onToolsChanged relays wire tools-changed notifications` |

### `lib/src/mcp/mcp_tool_adapter.dart` (surface into engine ToolRegistry)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U35 | `sync()` lists tools via the cache and registers each into the registry | FR (registry surfacing) | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::sync() lists tools via the cache and registers each into the registry` |
| U36 | Names use the `mcp:<serverId>:<toolName>` convention (per `ToolRegistry.registerMcpTool` contract) | FR (namespacing) | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::names use the mcp:<serverId>:<toolName> convention` |
| U37 | A subsequent `sync()` with new tools registers new and unregisters gone | FR-005 | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::a subsequent sync() with new tools registers new and unregisters gone` |
| U38 | `startAutoSync()` reacts to `onToolsChanged`: invalidates cache and re-syncs | FR-005 | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::startAutoSync() reacts to onToolsChanged: invalidates cache and re-syncs` |
| U39 | `dispose()` stops the auto-sync | FR-005 | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::dispose() stops the auto-sync` |
| U40 | `sync()` after dispose throws `StateError` | FR-005 | example | DONE | `test/mcp/mcp_tool_adapter_test.dart::…::sync() after dispose throws StateError` |

## Invariants and edge cases still to place

- SSE transport **real network** behavior (TLS, HTTP/2, proxy): out of scope — `IoSseMcpTransport` is a stub whose `open()`/`send()` throw `UnimplementedError`; integration tests with real network are a follow-up PR.
- stdio transport **real subprocess** behavior: out of scope — `IoStdioMcpTransport` is a stub; integration tests with a real MCP server subprocess are a follow-up PR.
- JSON serialization of `McpToolDescriptor` / `McpCallResult` for the SSE/stdio wire format: out of scope — the wire payload is the JSON map; serialization is the `Io*Transport`'s concern.

## Out of scope

- The engine loop's consumption of `McpClient` (spec-002).
- The concrete dispatcher that emits `ToolCallStarted` (spec-002).
- json_serializable for the MCP entities (issue #15).
- Real networked SSE / subprocess integration tests (follow-up PR).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test test/mcp/in_proc_mcp_client_test.dart --name "in-proc round-trip" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; profile forbids mid-loop dep additions)
- Mutation: none installed — deliberate mutants per rubric (see `verification.md`)
