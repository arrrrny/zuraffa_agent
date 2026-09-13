# Traceability: 105-production-mcp-transports

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:ed1673218acbe3bd20f1e19ea0a799abe2adac03dc42f1285f925f4a13aa9bf5
statements: 13
automated: 13
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 93 | 1. **Given** a running mock subprocess server speaking JSON-RPC over stdio, **When** a `tools/list` request is sent and then a `tools/call` request with arguments, **Then** the advertised descriptors return, the call round-trips arguments and result payload, and the second request succeeds — proving the connection is a session, not a one-shot. | A1 | automated |
| AC-2 | 109 | 2. **Given** a local mock HTTP server speaking the SSE dialect, **When** a transport opens against it, **Then** it reports open, a `tools/list` POST returns the advertised payload, a `tools/call` POST round-trips arguments and result, and the Authorization header carries the configured bearer token. | A2 | automated |
| AC-3 | 124 | 3. **Given** a mock stdio server writing a tools-changed notification line (and a mock SSE server emitting a tools-changed event), **When** the notifications arrive, **Then** a `toolsChanged` observation appears on the transport's notification stream, while unrecognized methods and malformed lines are ignored without breaking the session. | A3 | automated |
| AC-4 | 141 | 4. **Given** a stdio child that exits and an HTTP endpoint that answers non-200 or refuses the connection, **When** the transport is used, **Then** the exit flips the open signal off and fails the next send with a typed error, the HTTP failure fails with a typed error naming the status, send-before-open fails typed, and double open/double close are no-ops. | A4 | automated |
| AC-5 | 154 | 5. **Given** the implementation tree, **When** `rg "TODO\|FIXME\|HACK" lib/` runs, **Then** it returns zero hits, the two adapter files are the only dart:io consumers (both allowlisted), `dart analyze` is clean, and the full suite is green. | A5 | automated |
| FR-001 | 174 | - **FR-001**: `IoStdioMcpTransport.open` spawns `{executable}` with | U1 | automated |
| FR-002 | 178 | - **FR-002**: `send` serializes the typed request as a single-line | U8 | automated |
| FR-003 | 184 | - **FR-003**: stdout lines that are valid JSON-RPC notifications | U9 | automated |
| FR-004 | 191 | - **FR-004**: `IoSseMcpTransport.open` issues a GET on `{endpoint}` | U14 | automated |
| FR-005 | 197 | - **FR-005**: `send` POSTs the JSON-RPC 2.0 request (generated id, no | U17 | automated |
| FR-006 | 203 | - **FR-006**: SSE `data:` events whose JSON is a notification with | U18 | automated |
| FR-007 | 208 | - **FR-007**: both transports: `close` is idempotent, terminates the | U19 | automated |
| FR-008 | 214 | - **FR-008**: the implementation introduces dart:io usage only inside | U8 | automated |

