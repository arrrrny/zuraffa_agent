**Template Version**: `zuraffa-1.0`

# Feature Specification: Production MCP transports — SSE + stdio

**Branch**: `105-production-mcp-transports` (off master `09e63f6`) | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #107 — "Implement production MCP transports (SSE + stdio)
— replace `UnimplementedError` stubs". Epic: R3 tools & MCP client (issue #4).
Issue severity: critical — "the package cannot talk to a real MCP server today."

## Summary

`SseMcpClient` and `StdioMcpClient` are fully implemented clients — reconnect
policy, auth-token rotation, tool adapter, listing cache — but their only two
concrete transport adapters, `IoSseMcpTransport` and `IoStdioMcpTransport`, are
stubs: `open()` and `send()` throw `UnimplementedError`. They are the only
outstanding TODOs in `lib/` and the reason the engine cannot hold a real
conversation with any MCP server: SSE (networked servers) and stdio (local
subprocess servers) are the two transport modes a real MCP server speaks.

This spec implements both adapters over the existing stateless `McpWire` seam
and proves them with integration tests against local mock MCP servers — a
small Dart subprocess script for stdio, an in-test `HttpServer` for SSE — so
the tests stay hermetic (no external network, no pre-installed binaries).

Scope:

1. **`IoStdioMcpTransport`** — spawn the server process, speak
   newline-delimited JSON-RPC over its stdin/stdout, surface process exit,
   map server-pushed notifications.
2. **`IoSseMcpTransport`** — open the server-sent-events stream with bearer
   auth, POST JSON-RPC requests to the endpoint, parse the SSE event stream
   for responses and notifications.
3. **Lifecycle safety** — idempotent `open`/`close`, typed failures (never
   `UnimplementedError`) for send-before-open and use-after-close/exit.
4. **Repo hygiene the issue pins** — `rg "TODO|FIXME|HACK" lib/` returns zero
   hits; `dart analyze` clean; the runtime-purity allowlist is unchanged
   (dart:io stays confined to the two `io_*` adapter files, constitution VII).

**Out of scope** (carried from issue #107's Dependencies list — they build ON
this spec): MCP call timeout, per-server circuit breaker, retry on transient
errors (issue #120); wire-boundary schema validation (issue #131); sandboxing
and server identity verification (issue #137); the full MCP `initialize`
handshake and the upstream Streamable-HTTP transport dialect — the wire
contract here is the one specs 015/049/082 already established for the
clients (typed requests, id-matched JSON-RPC responses, tools-changed
notifications).

## Files

- `lib/src/mcp/io_stdio_mcp_transport.dart` — EDIT: replace the stub bodies
  (headers stay hand-curated). `open` spawns the process; `send` writes one
  JSON-RPC request line and awaits the id-matched response; process exit
  flips `isOpen` off, fails in-flight sends with a typed error, and closes
  the notification stream.
- `lib/src/mcp/io_sse_mcp_transport.dart` — EDIT: replace the stub bodies.
  `open` GETs the endpoint as an SSE stream (Accept: text/event-stream,
  optional Bearer); `send` POSTs the JSON-RPC request and resolves on the
  matching SSE response event; SSE events carrying the tools-changed
  notification are emitted on `notifications`.
- `test/mcp/io_stdio_mcp_transport_test.dart` — NEW: hermetic integration
  tests driving the transport against a mock MCP subprocess.
- `test/mcp/_mock_stdio_mcp_server.dart` — NEW: the mock stdio server script
  (a `dart run`-able script speaking the same newline-delimited JSON-RPC
  dialect; scriptable behaviors: echo tool, tools list, notification push,
  crash-on-command).
- `test/mcp/io_sse_mcp_transport_test.dart` — NEW: hermetic integration
  tests binding the transport to a local `HttpServer` mock that serves the
  SSE stream and answers POSTed JSON-RPC requests.
- `specs/105-production-mcp-transports/` — this artifact set.

No other `lib/` file changes: the seam (`McpWire`), the clients, the
reconnect policy, and the purity allowlist are untouched.

## User scenarios

### US1 — Talk to a real stdio MCP server (P1)

As the engine, I am pointed at a local MCP server executable; the transport
spawns it, and my `tools/list` and `tools/call` requests travel to the
process over its stdin and the answers come back from its stdout, so the
engine can use local-tool servers exactly as it already uses in-proc tools.

**Acceptance**: given a running mock subprocess server, a `tools/list`
request returns the advertised descriptors and a `tools/call` request
round-trips arguments and returns the tool's result payload; a second
request after the first proves the connection is a session, not a one-shot.

### US2 — Talk to a real SSE MCP server (P1)

As the engine, I am pointed at a networked MCP server's SSE endpoint; the
transport opens the event stream with the configured bearer credential and
sends each RPC as an HTTP request to the endpoint, so remote servers work
through the same `SseMcpClient` the unit tests already exercise.

**Acceptance**: given a local mock HTTP server speaking the SSE dialect, a
transport opened against it reports open; a `tools/list` POST returns the
mock's advertised payload; a `tools/call` POST round-trips arguments and
result; the Authorization header carries the bearer token when one is
configured.

### US3 — Server-pushed notifications surface (P2)

As the engine, I learn when a server's tool list changes: servers push a
notification; the transport maps it onto the existing typed notification
the clients already consume, so listing caches invalidate without polling.

**Acceptance**: a mock stdio server writing a tools-changed notification
line, and a mock SSE server emitting a tools-changed event, each produce a
`toolsChanged` observation on the transport's notification stream;
unrecognized notification methods and malformed lines/events are ignored
without breaking the session.

### US4 — Drops and lifecycle are observable and safe (P1)

As the engine's reconnect machinery, I must be able to trust the wire's
state signals: a crashed child process or a failed HTTP open is visible, a
send on a dead wire fails with a typed error instead of hanging or throwing
`UnimplementedError`, and open/close are idempotent so reconnect policies
can call them liberally.

**Acceptance**: a stdio child that exits flips the transport's open signal
off and fails the next send with a typed error; opening against an
HTTP endpoint that answers non-200 (or refuses the connection) fails with
a typed error naming the status; send-before-open fails typed; double
open and double close are no-ops that do not throw.

### US5 — The last stubs are gone (P2 — the issue #107 hygiene acceptance)

As a maintainer, I can grep the library and find zero outstanding TODOs, so
"cannot talk to a real MCP server" stops being true and the issue's
definition of done is mechanically checkable.

**Acceptance**: `rg "TODO|FIXME|HACK" lib/` returns zero hits; the two
adapter files are the only dart:io consumers added and both remain on the
purity allowlist; `dart analyze` is clean; the full suite is green.

## Edge cases

- A stdout line that is not valid JSON (log noise from a chatty child) is
  skipped, not fatal.
- A JSON-RPC response whose id matches no in-flight request, or a response
  arriving after the caller timed out at the client layer, is dropped.
- SSE comment/keep-alive lines (leading `:`), multi-line `data:` fields,
  and CRLF terminators parse without producing spurious messages.
- A JSON-RPC error object in a response maps to the typed error response
  (machine code + message), not an exception.
- An in-flight stdio send when the child exits resolves with a typed error
  rather than hanging forever.
- `open` on an already-open transport and `close` on an already-closed
  transport complete without side effects.

## Requirements

### Functional requirements

- **FR-001** (US1): `IoStdioMcpTransport.open` spawns `{executable}` with
  `{args}` and completes only once the process is running; the transport
  reports open afterwards. Opening is idempotent.
- **FR-002** (US1): `send` serializes the typed request as a single-line
  JSON-RPC 2.0 request (generated monotonically increasing id), writes it
  to the child's stdin, and completes with `McpWireResponseOk` carrying the
  response `result` map, or `McpWireResponseError` carrying the response's
  error code and message. Concurrent sends are matched by id.
- **FR-003** (US3, US4): stdout lines that are valid JSON-RPC notifications
  with method `notifications/tools/list_changed` are emitted as
  `McpWireNotificationToolsChanged` on `notifications`; all other valid
  notifications and any unparseable line are ignored; process exit turns
  `isOpen` off, completes pending sends with a typed failure, and closes
  the notification stream.
- **FR-004** (US2): `IoSseMcpTransport.open` issues a GET on `{endpoint}`
  with `Accept: text/event-stream` (and `Authorization: Bearer <token>`
  when a token is configured); a 200 response leaves the transport open;
  any other status fails the open with a typed error naming the status.
  Opening is idempotent.
- **FR-005** (US2): `send` POSTs the JSON-RPC 2.0 request (generated id, no
  wire-level id exposed) to `{endpoint}` with the same auth header; the
  response body's `result` map completes the send as
  `McpWireResponseOk`, and its error object completes it as
  `McpWireResponseError`; non-2xx POST statuses fail the send typed.
- **FR-006** (US3): SSE `data:` events whose JSON is a notification with
  method `notifications/tools/list_changed` are emitted as
  `McpWireNotificationToolsChanged`; comment/keep-alive lines and
  unrecognized events are ignored.
- **FR-007** (US4): both transports: `close` is idempotent, terminates the
  subprocess / closes the HTTP connection, and closes the notification
  stream; `send` before `open` (or after `close`/exit) fails with a typed
  error; no method throws `UnimplementedError` or an `Error` (as opposed to
  a typed failure) under any lifecycle ordering.
- **FR-008** (US5): the implementation introduces dart:io usage only inside
  the two `io_*` adapter files (already on the allowlist) and test files;
  after this spec `rg "TODO|FIXME|HACK" lib/` returns zero hits and
  `dart analyze` is clean.

### Key entities

- **`McpWire`** (existing seam, specs 015/049) — unchanged: `open`, `close`,
  `send`, `notifications`, `isOpen`. This spec fills in its only two
  concrete production implementors.
- **`McpWireRequest` / `McpWireResponse` / `McpWireNotification`** (existing
  sealed families) — unchanged; the transports map them to and from the
  JSON-RPC 2.0 wire dialect (requests: `tools/list`, `tools/call`;
  notifications: `notifications/tools/list_changed`).
- **Mock MCP servers (test-only)** — a stdio subprocess script and an
  in-test HTTP server, each scriptable per test, speaking the same dialect
  so the transports are proven against real I/O without external services.

## Success criteria

- **SC-001** (US1 / FR-001–002): against the mock subprocess server, a
  opened stdio transport completes `tools/list` with the advertised
  descriptors and `tools/call` with the echoed result; a follow-up call on
  the same transport succeeds (session, not one-shot).
- **SC-002** (US2 / FR-004–005): against the local mock HTTP server, an
  opened SSE transport completes `tools/list` and `tools/call`; the mock
  observed the bearer header when configured; a non-200 open fails typed
  with the status named.
- **SC-003** (US3 / FR-003, FR-006): a tools-changed notification pushed by
  each mock server is observed on the transport's notification stream;
  garbage lines/events produce no notification and no crash.
- **SC-004** (US4 / FR-003, FR-007): child exit closes the stdio transport
  observably and fails subsequent sends typed; send-before-open fails
  typed on both transports; double open/double close are safe.
- **SC-005** (US5 / FR-008 — the issue #107 acceptance): zero
  TODO/FIXME/HACK in `lib/`; `dart analyze --fatal-infos` clean; full
  `dart test` green; purity gate unchanged and passing.

## Assumptions

- The wire dialect is the one this repo's clients already speak (specs 015,
  049, 082): JSON-RPC 2.0 payloads, request methods `tools/list` and
  `tools/call`, notification method `notifications/tools/list_changed`.
  The transports own id generation because the typed `McpWireRequest`
  carries none. The upstream MCP `initialize` handshake is not part of the
  seam contract and stays out of scope.
- stdio framing is one JSON document per newline-terminated line (the
  common MCP stdio convention); SSE framing is the text/event-stream
  format with `data:` carrying whole JSON documents.
- SSE request flow is single-endpoint: GET for the event stream, POST to
  the same URL for RPC (the transport's constructor has exactly one
  `endpoint` field). Adapting to the upstream "endpoint event" dialect of
  real MCP servers, if it differs, is an integration concern tracked
  upstream, not a seam change.
- Timeouts on individual calls belong to the resilience layer (issue #120),
  not to the transport; transports fail typed on process exit / connection
  loss, which is the signal the timeout work will build on.

## Dependencies

- Builds on: master `09e63f6` (0.1.1) — `McpWire` seam + clients (spec 015,
  issue #15), transport entities (spec 049), reconnect + `onReconnected`
  (spec 082). The clients are already wired to rebuild/reattach wires via
  `McpWireFactory`; nothing above the seam changes.
- Independent of: all other specs in flight; the change is two `lib/` files
  plus new test files.
- Foundational for (per issue #107): MCP call timeout / retry / circuit
  breaker (issue #120), wire validation (issue #131), sandboxing + identity
  verification (issue #137) — all need real transports to test against.
