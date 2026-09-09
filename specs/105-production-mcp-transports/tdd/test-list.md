# Test List: 105-production-mcp-transports

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md` (SC-001..SC-005). Hosted in the
default `dart test` lane (the profile's `acceptance: null` note applies: no
separate acceptance runner; the highest level this repository can test these
is hermetic integration against composed modules — real subprocess / real
loopback HTTP, mocked MCP peer).

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | Against the mock stdio child (`test/mcp/_mock_stdio_mcp_server.dart echo`), an opened `IoStdioMcpTransport` completes `tools/list` with the advertised descriptor and `tools/call` with the echoed result, and a follow-up call on the same transport succeeds (`test/mcp/io_stdio_mcp_transport_test.dart`). | SC-001 | PENDING |
| A2 | Against the loopback SSE mock (`HttpServer`), an opened `IoSseMcpTransport` completes `tools/list` and `tools/call`; the mock observed the bearer header when configured; a non-200 open fails typed with the status named (`test/mcp/io_sse_mcp_transport_test.dart`). | SC-002 | PENDING |
| A3 | A tools-changed notification pushed by each mock server is observed on that transport's `notifications` stream; garbage lines/events produce no notification and no crash (`test/mcp/io_stdio_mcp_transport_test.dart` + `test/mcp/io_sse_mcp_transport_test.dart`). | SC-003 | PENDING |
| A4 | A stdio child exit flips the open signal off and fails pending+subsequent sends typed; send-before-open fails typed on both transports; double open/double close are safe on both (`test/mcp/io_stdio_mcp_transport_test.dart` + `test/mcp/io_sse_mcp_transport_test.dart`). | SC-004 | PENDING |
| A5 | `rg "TODO\|FIXME\|HACK" lib/` returns zero hits; `dart analyze` reports zero findings repo-wide; `dart test` green (baseline 1202 + new); the purity allowlist is unchanged (no dart:io import outside the allowlisted adapters). | SC-005 | PENDING |

## Inner loop: unit behaviors

One line per rule the two adapter components implement; grouped by component.
Boundaries are pinned on both sides (CRLF/LF, empty/partial data, unknown vs
known ids, open/closed/exit lifecycle orderings).

### Component: `lib/src/mcp/io_stdio_mcp_transport.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `open()` spawns the mock child (`echo` mode) and `isOpen` is true once open completes; opening an already-open transport does not spawn a second process. | FR-001 | DONE |
| U2 | A `McpWireRequestListTools` send writes the contract's `tools/list` JSON-RPC line to the child's stdin and completes `McpWireResponseOk` carrying the mock's advertised descriptor (`name: echo`, `paramsSchema` preserved). | FR-002 | DONE |
| U3 | A `McpWireRequestCallTool` send round-trips arguments and completes with the result payload `{echo: <arguments>}`; a second call on the SAME transport also succeeds (session persistence, id counter advances). | FR-002 | PENDING |
| U4 | Construction with an empty `executable` throws `ArgumentError` naming the field — before any process exists. | FR-007 | PENDING |
| U5 | A JSON-RPC **error** response from the child completes the send as `McpWireResponseError` with the error's stringified code and message (not an exception, not a crash). | FR-002 | PENDING |
| U6 | The `notify`-mode child's `notifications/tools/list_changed` line is observed as `McpWireNotificationToolsChanged` on `notifications` before the normal answer resolves. | FR-003 | PENDING |
| U7 | `garbage`-mode junk lines (non-JSON, valid-JSON-but-unknown) produce no notification, no crash; a subsequent RPC on the same transport still succeeds. | FR-003 | PENDING |
| U8 | A response line whose `id` matches no in-flight request is dropped silently; the in-flight request still resolves from its own (later) response. | FR-002 | PENDING |
| U9 | `crash`-mode child exit: `isOpen` → false, an in-flight send's future completes with the typed `McpWireClosedException`, the next send throws the same typed failure (throw, not error-response — the client reconnect contract), and the `notifications` stream is done. | FR-003 | PENDING |
| U10 | `send` before `open` (and after `close`) throws `McpWireClosedException` — never `UnimplementedError`, never an `Error`. | FR-007 | PENDING |
| U11 | Double `open` and double `close` are no-ops: no second process spawn, no throw, `isOpen` consistent. | FR-007 | PENDING |
| U12 | `close()`: the child process is terminated, `isOpen` → false, subsequent send throws typed, `notifications` is closed; pending sends at close time fail typed. | FR-007 | PENDING |

### Component: `lib/src/mcp/io_sse_mcp_transport.dart`

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U13 | `open()` GETs the endpoint with `Accept: text/event-stream` and (token configured) `Authorization: Bearer <token>` — asserted server-side — and `isOpen` is true; a second `open()` issues no second GET. | FR-004 | PENDING |
| U14 | Open against a 404-serving endpoint fails with the typed open exception naming status 404; construction with a non-http(s) endpoint throws `ArgumentError`. | FR-004 | PENDING |
| U15 | `tools/list` POSTs the contract envelope and completes `McpWireResponseOk` with the mock payload. | FR-005 | PENDING |
| U16 | `tools/call` POST round-trips arguments/result; the mock asserts the `tools/call` envelope (`method`, `params.name`, `params.arguments`) and the auth header on the POST. | FR-005 | PENDING |
| U17 | POST-level failures: a 2xx body carrying a JSON-RPC error object completes `McpWireResponseError`; a non-2xx POST fails the send typed naming the status. | FR-005 | PENDING |
| U18 | The SSE parser: a tools-changed event emitted after keep-alive comment lines and CRLF terminators is observed on `notifications`; an event with empty data and an unrecognized method are ignored; a multi-line `data:` field joins into one payload. | FR-006 | PENDING |
| U19 | Lifecycle: `send` before `open` throws typed; double open (no second GET) and double close are no-ops; `close()` aborts the stream GET, `isOpen` → false, subsequent send throws typed. | FR-007 | PENDING |

## Invariants and edge cases still to place

- None — every edge from spec.md's Edge cases list found a home (U7 junk,
  U8 id mismatch, U18 keep-alive/multi-line/CRLF/empty, U5/U17 error
  mapping, U9/U19 exit/close orderings, U4/U14 constructor validation).
  In-flight-hang protection is deliberately NOT a transport behavior
  (timeouts belong to issue #120, spec Assumptions).

## Out of scope (do not add tests)

- MCP call timeout / retry / circuit breaker (issue #120) — resilience layer.
- Wire-boundary schema validation (issue #131).
- The upstream `initialize` handshake and the endpoint-event SSE dialect
  (spec Out-of-scope; recorded upstream follow-up).
- Sandboxing / server identity verification (issue #137).
- Auth-token rotation changes (spec 015/082 surface, untouched).

## Verification commands (from .specify/memory/tdd-profile.md @ 09e63f6)

```bash
dart test                                                                # full suite (baseline: 1202 passed / 0 failed)
dart test test/mcp/io_stdio_mcp_transport_test.dart                      # stdio adapter behaviors
dart test test/mcp/io_sse_mcp_transport_test.dart                        # SSE adapter behaviors
dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "<name>" # single behavior
rg "TODO|FIXME|HACK" lib/                                                # A5 hygiene gate (expect: no matches)
dart analyze                                                             # A5 analyze gate (expect: No issues found!)
```
