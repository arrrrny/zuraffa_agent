# Research: Production MCP transports — SSE + stdio (spec 105)

## R1 — What wire dialect do the clients already assume?

**Decision**: JSON-RPC 2.0 with methods `tools/list` / `tools/call` and
notification `notifications/tools/list_changed`; stdio framing = one JSON
document per newline-terminated line; SSE request flow = GET event stream +
POST RPC to the same endpoint.

**Rationale**: `McpWire`'s doc comment fixes the *semantic* contract (typed
requests/responses/notifications; the clients in `sse_mcp_client.dart` /
`stdio_mcp_client.dart` read `payload['tools']`, descriptor fields
`name`/`description`/`paramsSchema`, and treat `McpWireResponseError` as an
application error). The *framing* was never pinned because the adapters were
stubs. The upstream MCP standard speaks JSON-RPC 2.0 with these method names;
newline-delimited stdio is the upstream convention, and single-endpoint
GET/POST matches the adapter's existing single-`endpoint` constructor field.

**Alternatives considered**: (a) full upstream Streamable-HTTP dialect
(endpoint event tells the client where to POST) — rejected: requires a seam
or constructor change, out of scope per spec; recorded as the follow-up
integration concern. (b) Binary length-prefixed framing for stdio — rejected:
not the MCP stdio convention.

## R2 — Throw or return on transport failure?

**Decision**: transport-level failures **throw** typed `Exception`s
(`McpWireClosedException`, `McpWireOpenException`); only JSON-RPC *error
responses* become `McpWireResponseError`.

**Rationale**: both clients wrap `wire.send` in `_callWithReconnect`, which
`catch`es exceptions to drive the reconnect policy (spec 082); a transport
failure returned as a response would skip reconnection entirely and break
SC-004's semantics. Evidence: `stdio_mcp_client.dart` `_callWithReconnect` —
`try { send } catch (e) { reconnect }`.

**Alternatives considered**: returning `McpWireResponseError(code:
'transport-error')` — rejected for the reason above (it is how the *client*
surfaces a final failure to the engine, not how the *wire* signals a drop).

## R3 — How do hermetic integration tests drive real I/O?

**Decision**: stdio tests spawn `Platform.resolvedExecutable` with the mock
script path (`test/mcp/_mock_stdio_mcp_server.dart`) plus a mode argument;
SSE tests `HttpServer.bind` on `InternetAddress.loopbackIPv4` port 0.

**Rationale**: no compilation step, no prebuilt binaries, no external
network; `dart run`-capable on any dev machine and in CI (Dart SDK already
present). Port 0 removes flakiness from fixed ports. Per-test process/server
lifecycle keeps tests order-independent under `concurrency: 4`.

**Alternatives considered**: a precompiled fixture binary — rejected
(requires a build step in CI); binding fixed ports — rejected (flaky).
Timeouts: every await that can hang is bounded by dart_test.yaml's 30s
per-test timeout; no ad-hoc timers needed.

## R4 — What does the SSE parser need to handle?

**Decision**: incremental line-based parser: events separated by blank
lines; `data:` lines (one leading space stripped) joined with `\n`; comment
(`:` prefix), `event:`, `id:`, `retry:` fields accepted and ignored; CRLF
and LF both terminate lines; events with empty concatenated data dropped.

**Rationale**: this is the WHATWG `text/event-stream` grammar subset needed
by the dialect; keep-alive comments are common in real servers; CRLF
terminators appear when servers write `\r\n`. Multi-line `data:` is legal
per the grammar and cheap to support. The parser is a pure function of fed
chunks → testable without sockets.

**Alternatives considered**: `package:http`'s SSE client or `stream_channel`
— rejected: no such direct dependency exists and adding one for ~60 lines
of parser violates the no-new-deps constraint; raw split-on-`\n\n` —
rejected (breaks on chunk boundaries crossing event edges).

## R5 — Do in-flight stdio sends need timeouts?

**Decision**: no timer in the transport. Pending sends fail typed when the
process exits; call-level timeouts belong to the resilience layer (issue
#120, out of scope per spec).

**Rationale**: matches spec assumptions; a hung child with a live process is
indistinguishable from a slow tool at this layer, and the test suite's 30s
per-test timeout bounds test exposure.

## R6 — Where does id generation live?

**Decision**: each transport owns a monotonic `_nextId` counter; the typed
`McpWireRequest` carries no id (seam unchanged).

**Rationale**: `McpWireRequest` is a sealed family fixed by spec 015 and
consumed by both clients + the test fake; changing it would ripple. Ids are
wire-implementation detail — the SSE adapter could even use one id per POST
(a fresh HTTP exchange), but a shared counter keeps both adapters uniform.
