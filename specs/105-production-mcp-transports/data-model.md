# Data Model: Production MCP transports — SSE + stdio (spec 105)

No new entities. This feature implements two existing interfaces. The model
below is the *state and failure* model the implementations must satisfy.

## Reused seam types (unchanged, `lib/src/mcp/mcp_wire.dart`)

| Type | Shape | Notes |
|---|---|---|
| `McpWire` | `open() / close() / send(req) / notifications / isOpen` | both open and close are idempotent |
| `McpWireRequestListTools` | — | maps to JSON-RPC `tools/list`, `params: {}` |
| `McpWireRequestCallTool` | `{name, arguments}` | maps to `tools/call`, `params: {name, arguments}` |
| `McpWireResponseOk` | `{payload: Map<String,dynamic>}` | from JSON-RPC `result` |
| `McpWireResponseError` | `{code: String, message: String}` | from JSON-RPC `error` object |
| `McpWireNotificationToolsChanged` | — | from `notifications/tools/list_changed` |

## Adapter lifecycle state machine (both adapters)

```text
            open() ok            send/close/exit
  ┌────────┐ ─────────► ┌────────┐ ───────────► ┌────────┐
  │ closed │            │  open  │              │ closed │
  └────────┘ ◄───────── └────────┘ ◄─────────── └────────┘
       ▲        close()        ▲    process exit (stdio)
       │ open() fail (typed)   │    or abort (sse)
       └───────────────────────┘
```

- `open()` on `open` → no-op (idempotent). `close()` on `closed` → no-op.
- `send()` requires `isOpen`; otherwise throws `McpWireClosedException`.
- stdio: process exit at any point → transition to closed: `isOpen` false,
  pending sends completed with `McpWireClosedException` (thrown through
  their futures), notification stream done.
- SSE: server closing the event stream, or socket error, does NOT flip
  `isOpen` synchronously (the client-level reconnect policy reacts to the
  next send failure / stream done); `close()` is the only local transition.

## New typed failures (adapters own them; defined in `io_stdio_mcp_transport.dart`, re-exported use in the SSE file)

| Type | When | Carries |
|---|---|---|
| `McpWireClosedException` | send before open / after close / after child exit / non-2xx POST | message |
| `McpWireOpenException` | SSE open with non-200, or connect error | `int? statusCode`, cause |

Both `implements Exception`. Clients catch any exception → reconnect policy;
the typed surface exists for diagnostics and tests, and to guarantee no
`UnimplementedError`/`Error` escapes the adapters (FR-007).

## Wire dialect contract

See [contracts/mcp-wire-dialect.md](contracts/mcp-wire-dialect.md) — the
framing is normative for implementations and mock fixtures.

## Validation rules

- `IoStdioMcpTransport(executable: ...)`: executable non-empty (ArgumentError).
- `IoSseMcpTransport(endpoint: ...)`: endpoint must be http/https URI
  (ArgumentError); `bearerToken` nullable.
- Constructors validate eagerly — misconfiguration fails at construction,
  not at first `open()` (house pattern: entity constructor validation).
