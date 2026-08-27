# Tasks: MCP Client

**Branch**: `feat/specs-015-022-023-024` | **Plan**: [plan.md](./plan.md)

## T1 — Pure value objects & enums (no IO, no dart:io)

- [ ] T1.1 `lib/src/mcp/mcp_tool_descriptor.dart` — `McpToolDescriptor` value object with `name`, `description`, `paramsSchema?`, value equality.
- [ ] T1.2 `lib/src/mcp/mcp_call_result.dart` — sealed `McpCallResult` with `McpCallOk(result)` / `McpCallError(code, message)` subtypes.
- [ ] T1.3 `lib/src/mcp/mcp_client.dart` — `McpClient` interface + `McpClientState` enum.

## T2 — Transport seam (pure — no dart:io)

- [ ] T2.1 `lib/src/mcp/mcp_wire.dart` — `McpWire` interface + `McpWireRequest` / `McpWireResponse` / `McpWireNotification` sealed families.
- [ ] T2.2 `lib/src/mcp/mcp_reconnect_policy.dart` — exponential-backoff-with-jitter, injected `DateTime Function() now` and `Future<void> Function(Duration) delay`.

## T3 — In-proc transport (fully functional, no dart:io)

- [ ] T3.1 `lib/src/mcp/in_proc_mcp_client.dart` — `InProcMcpClient` registers local callbacks; `listTools()` returns the descriptors; `callTool(name, args)` invokes the callback and wraps the result.
- [ ] T3.2 Tests: `test/mcp/in_proc_mcp_client_test.dart` — round-trip a tool, verify zero-serialization overhead (asserts same object identity of the callback's return).

## T4 — ToolListingCache (pure)

- [ ] T4.1 `lib/src/mcp/tool_listing_cache.dart` — `ToolListingCache` with `getOrRefresh()`, `invalidate()`, max-age TTL.
- [ ] T4.2 Tests: `test/mcp/tool_listing_cache_test.dart` — refresh on first call, hit on second, miss after TTL, miss after explicit invalidate.

## T5 — Reconnect policy (pure, injected clock)

- [ ] T5.1 Tests first (red): `test/mcp/mcp_reconnect_policy_test.dart` — backoff grows exponentially, caps, jitters deterministically under a fixed seed; exhausted retries throw.
- [ ] T5.2 Implementation green: `lib/src/mcp/mcp_reconnect_policy.dart`.

## T6 — SSE + stdio clients (delegate to McpWire seam — no dart:io)

- [ ] T6.1 `lib/src/mcp/sse_mcp_client.dart` — `SseMcpClient` accepts an `McpWire` (real SSE adapter is `IoSseMcpTransport` in `io_sse_mcp_transport.dart`); on transport close, runs `McpReconnectPolicy`.
- [ ] T6.2 `lib/src/mcp/stdio_mcp_client.dart` — same shape, bounded retries for subprocess crashes.
- [ ] T6.3 Tests: `test/mcp/sse_mcp_client_test.dart` + `test/mcp/stdio_mcp_client_test.dart` — fake `McpWire` simulates drop + reconnect; verifies reconnect happens within 5s (SSE) / 10s (stdio) under injected clock.

## T7 — ToolRegistry adapter (surface MCP tools)

- [ ] T7.1 `lib/src/mcp/mcp_tool_adapter.dart` — `McpToolAdapter` wraps an `McpClient` and a `ToolRegistry`; on `onToolsChanged`, diffs the listed tools and calls `registerMcpTool(AgentTool, serverId)` / `unregister(qualifiedName)`.
- [ ] T7.2 Tests: `test/mcp/mcp_tool_adapter_test.dart` — fake `McpClient` + fake `ToolRegistry`; verify tools land in the registry, removed when gone, re-listed on cache invalidation.

## T8 — IO-segregated adapters (real network/subprocess)

- [ ] T8.1 `lib/src/mcp/io_sse_mcp_transport.dart` — concrete `McpWire` impl using `dart:io` HttpClient + SSE parsing. Stays in the purity allowlist (pipeline.yml update).
- [ ] T8.2 `lib/src/mcp/io_stdio_mcp_transport.dart` — concrete `McpWire` impl using `dart:io` Process.start. Allowlisted.
- [ ] T8.3 Update `.github/workflows/pipeline.yml::verify / Runtime purity gate` ALLOWED list to include the two new adapter files, with justification comments.

## T9 — Public export

- [ ] T9.1 Add `export 'src/mcp/mcp_client.dart';` to `lib/zuraffa_agent.dart` (plus the descriptor/result types).

## T10 — Repo-wide gate

- [ ] T10.1 `dart pub get` clean.
- [ ] T10.2 `dart analyze --fatal-infos` — 0 NEW issues (5 pre-existing baseline issues preserved).
- [ ] T10.3 `dart test` — baseline 529 + new tests pass.

## T11 — Spec-Kit artifacts + commit

- [ ] T11.1 `specs/015-mcp-client/{spec.md, plan.md, tasks.md, tdd/test-list.md, tdd/verification.md}` — all five artifacts authored.
- [ ] T11.2 Commit with `feat(mcp): implement MCP client runtime — in-proc/SSE/stdio transports, tool-registry surfacing, reconnect (closes #15)`.
- [ ] T11.3 Open PR; verify CI green.
