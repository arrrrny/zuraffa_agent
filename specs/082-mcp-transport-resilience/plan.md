# Implementation Plan: MCP Transport Resilience (spec 082)

**Branch**: `082-mcp-transport-resilience` | **Date**: 2026-08-29 | **Spec**:
`specs/082-mcp-transport-resilience/spec.md`

## Summary

Additive hardening of the R3 MCP transport: one new client surface
(`McpClient.onReconnected` — the recovery signal), one new cache invalidation
trigger (`ToolListingCache` listens to it), and three pins over existing
behavior (jitter-cap clamp, storm terminality, exact TTL boundary). The
backoff formula, the configs, and the wire seam are NOT changed — the wire
stays stateless by design and recovery stays a client concern.

## Technical Context

**Language/Version**: Dart 3.13.2 (SDK constraint `^3.8.0`), pure Dart — no
Flutter, no `dart:io` on the runtime paths touched (constitution VII/VIII;
the `io_*` transports are untouched).

**Primary Dependencies**: `test` ^1.25; no new packages. Everything is
in-tree under `lib/src/mcp/`.

**Storage**: N/A (in-memory streams and caches only).

**Key subsystems**: `lib/src/mcp/` — `mcp_client.dart` (interface),
`sse_mcp_client.dart` / `stdio_mcp_client.dart` (wire-backed clients with
`_callWithReconnect` recovery loops), `in_proc_mcp_client.dart`,
`mcp_reconnect_policy.dart` (backoff + injected `McpClock`/`McpDelay`),
`tool_listing_cache.dart` (TTL cache), `mcp_tool_adapter.dart`
(`mcp:<serverId>:<toolName>` namespacing), `mcp_call_result.dart` (sealed
union). Tests: `test/mcp/` with `_fake_wire.dart` (programmable wire fake)
and two `McpClient` fakes that must grow the new member.

## Components

### 1. Recovery signal — `McpClient.onReconnected` (FR-004)

```dart
// mcp_client.dart (interface, additive):
/// Fires once after each successful recovery from a transport drop
/// (reconnecting → connected inside the send-retry loop). Never fires on
/// the initial connect(). Lets caches invalidate entries that predate the
/// disconnect.
Stream<void> get onReconnected;
```

- `SseMcpClient` / `StdioMcpClient`: a `StreamController<void>.broadcast()`
  `_reconnectedController`; in `_callWithReconnect`'s recovery branch, after
  `_setState(McpClientState.connected)`, fire `_reconnectedController.add(null)`.
  `disconnect()` closes it alongside the tools-changed controller.
- `InProcMcpClient`: `onReconnected => const Stream.empty()` — there is no
  transport to drop, so the signal can never fire.

### 2. Cache invalidation on recovery (FR-005)

`ToolListingCache` constructor gains a second subscription:

```dart
_reconnectSub = client.onReconnected.listen((_) => invalidate());
```

canceled in `dispose()` next to the tools-changed subscription. Rationale: a
severed transport may have missed a server-side `tools_changed` notification;
the safe default after any recovery is to re-list on next demand. Cost is one
extra `listTools` per drop episode — negligible against wrong dispatches.

### 3. Pins over existing behavior (FR-002 / FR-003 / FR-006 / FR-007)

Test-only; no production change:

- **Jitter clamp**: with `jitter: 0.5`, `cap: 1s`, seed fixed — every applied
  delay ≤ cap. The production clamp lives at
  `mcp_reconnect_policy.dart:120` (`(capped * jitterScale).clamp(0, cap)`).
- **Storm terminality**: always-throwing wire → `delays.length ==
  maxAttempts`, `state == failed`; a subsequent `callTool` returns
  `McpCallError('client-not-connected')` and `delays.length` is unchanged.
- **TTL boundary**: entry aged exactly `maxAge` → next `getOrRefresh()`
  re-lists (freshness is `age < maxAge`, exclusive).
- **Namespace + sealed result**: cited from the existing 015 tests
  (`mcp_tool_adapter_test.dart`, `sse_mcp_client_test.dart`) — no duplicates.

### 4. Tests (`test/mcp/mcp_082_resilience_test.dart` — NEW)

RED (new behavior, fails on missing member at compile time first, then on
missing emission/invalidation):

- T1: drop mid-call → recovery → call returns real result AND
  `onReconnected` fired exactly once (SSE).
- T2: stdio client fires `onReconnected` exactly once per recovery.
- T3: cache primed within TTL → recovery fires → next `getOrRefresh()`
  re-lists (`listToolsCallCount` 1 → 2) — fake client level.
- T4: end-to-end: real `SseMcpClient` + `ToolListingCache`, drop + recovery
  → cache re-lists (SC-002).
- T8: `InProcMcpClient.onReconnected` never emits (no transport to drop).

Pins (pass against current behavior by design — guarded by mutants):

- T5: jittered backoff never exceeds the cap (FR-002).
- T6: storm terminality — bounded delays, `failed` state, frozen counter
  after failure (FR-003).
- T7: TTL boundary at exactly `maxAge` re-lists (FR-006).

### 5. Fake updates (compile fixes)

`_CountingClient` (tool_listing_cache_test.dart) and the adapter-test fake
gain `onReconnected` (controllable controller in the cache fake so T3 can
drive it; trivial stream in the adapter fake).

### 6. Mutations (one at a time, cp-restored, each must KILL)

- M1: remove the jitter clamp (`delayMicros = capped * jitterScale`, no
  `.clamp`) → T5 kills.
- M2: drop `_setState(McpClientState.failed)` on exhaustion → T6 kills.
- M3: cache's reconnect subscription removed → T3/T4 kill.
- M4: recovery emission removed (no `_reconnectedController.add`) → T1/T2/T4
  kill.
- M5: TTL freshness `<=` instead of `<` → T7 kills.

## Sequencing

1. `/speckit.specify` → spec.md (this artifact set; done).
2. RED — `mcp_082_resilience_test.dart`: compile failure on missing
   `onReconnected` (T1–T4), then (after the member exists but before
   wiring) failing assertions; record red evidence in `tdd/cycle-log.md`.
3. GREEN — interface member + SSE/stdio/in-proc wiring + cache subscription
   + fake updates; target file 8/8 (T1–T8).
4. Pins T5–T7 verified green against unmodified behavior.
5. Mutations M1–M5, one at a time, cp-restored.
6. Gates (`dart analyze`, full `dart test`), `tdd/verification.md`, commit +
   PR (base master).

## Risks / decisions

- **Interface growth breaks external implementors**: `McpClient` is a
  package-internal interface (publish_to: none); the three in-tree
  implementors and two test fakes are updated in the same change. Acceptable;
  the alternative (optional stream parameter on the cache) hides the seam the
  engine actually needs.
- **Emission timing**: fire after the state transition, not before, so a
  listener that inspects `client.state` sees `connected`.
- **`disconnect()` closes the controller**: mirrors the existing
  tools-changed controller lifecycle; reuse after disconnect is already
  unsupported for tools-changed, so no contract change.
- **Pins are not RED**: T5–T7 pass against current master behavior by
  design; each is justified by a killer mutant (the 078 precedent).
