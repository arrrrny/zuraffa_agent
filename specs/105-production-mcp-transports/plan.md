# Implementation Plan: Production MCP transports — SSE + stdio

**Branch**: `105-production-mcp-transports` | **Date**: 2026-09-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/105-production-mcp-transports/spec.md` (seeded from issue #107)

## Summary

The two concrete `McpWire` adapters become real. `IoStdioMcpTransport` spawns
the server executable and speaks newline-delimited JSON-RPC 2.0 over its
stdin/stdout, with id-matched responses, typed transport failures on process
exit, and tools-changed notifications parsed from stdout. `IoSseMcpTransport`
opens a `text/event-stream` GET on the endpoint (bearer-authenticated), POSTs
each RPC as JSON to the same endpoint, resolves responses from the HTTP reply,
and emits tools-changed notifications from SSE events. Both keep the seam's
contract exactly: transport-level failure **throws** (the clients catch and
run the reconnect policy, spec 082), application-level JSON-RPC errors map to
`McpWireResponseError`. Hermetic integration tests drive both adapters
against local mocks — a Dart subprocess script and an in-test `HttpServer` —
no external network, no pre-installed binaries. Issue #107's hygiene
acceptance (zero TODO/FIXME/HACK in `lib/`, analyzer clean) is a gate.

## Technical Context

**Language/Version**: Dart 3.x (pubspec SDK `^3.8.0`). Pure Dart engine —
Flutter-free (constitution VII).

**Primary Dependencies**: `dart:io` (`Process`, `HttpClient`, `HttpServer`)
— **only inside the two `io_*` adapter files and tests**; both files are
already on the CI purity allowlist (pipeline.yml, constitution VII).
`dart:async` for stream plumbing. **No new package dependencies** (dev or
runtime).

**Storage**: N/A — transports hold live connections, not data.

**Testing**: `dart test` (package:test). New integration tests are ordinary
hermetic tests (localhost-only `HttpServer`; `dart run` a test-fixture script
as the stdio child via `Process.start` with the current VM executable —
no prebuilt artifacts). Suite baseline: 1202 passed / 0 failed / ~70s at
`09e63f6`; per-test timeout 30s (dart_test.yaml), concurrency 4.

**Target Platform**: Dart VM. The adapters are the purity-allowlisted I/O
boundary; nothing above `McpWire` changes.

**Project Type**: library.

**Constraints**: constitution VII (dart:io confined to the allowlist), VIII
(attribution headers retained — both files are hand-curated with pi_agent /
spec-015 lineage), X (post-build analyze pristine — baseline at `09e63f6` is
"No issues found", so zero findings repo-wide), issue #107 hygiene gate
(zero TODO/FIXME/HACK in `lib/`).

**Scale/Scope**: 2 edited lib files (stub → real bodies, headers updated),
2 new test files + 1 new test fixture script (~700 lines total). Zero changes
to the seam, clients, reconnect policy, or CI.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. CLI-Built Only** — PASS. Work runs through the spec-driven pipeline
  (specify → plan → tasks → tdd.plan → tdd.run → implement → tdd.verify).
- **II. Stop on First Misfire** — **OVERRIDDEN FOR THIS RUN by explicit user
  instruction**: on each zfa misfire, file the issue on `arrrrny/zuraffa`
  (command / expected / actual / repro) and continue with a documented
  workaround. **Misfire #1 logged**: `.specify/scripts/bash/setup-plan.sh`
  missing on fresh clone (`.specify/*` gitignored, not regenerable by the
  CLI) → filed as arrrrny/zuraffa#1417; workaround: plan workflow executed
  directly (this document set), artifact format mirrors committed specs.
- **III. Escalate Upstream and Wait** — OVERRIDDEN for this run per the same
  user instruction (report-and-continue instead of report-and-wait); every
  escalation is still filed, tracked, and referenced from the workaround.
- **IV. Postmortem Every Misfire** — PASS. Misfire #1's postmortem is the
  GitHub issue body (command/expected/actual/repro) plus this plan's record;
  further misfires get the same treatment in `tdd/cycle-log.md`.
- **V. Gates Are Non-Negotiable** — PASS. analyze + test + purity + hygiene
  gates run in order; the spec is the contract (SC-001..SC-005).
- **VI. Probes Must Retain Evidence** — PASS. Every red/green run is logged
  verbatim in `tdd/cycle-log.md`.
- **VII. Engine Purity** — PASS. dart:io appears only in the two already-
  allowlisted `io_*` adapters (+ test files, which are unconstrained). The
  purity gate grep passes unchanged.
- **VIII. Attributed Ports** — PASS. Both files keep their hand-curated
  headers and lineage notes; the SSE event-stream parser follows the pi_agent
  lineage already covered by NOTICE; nothing is copied verbatim from
  unattributed sources.
- **IX. Zorphy Is the Model Layer** — PASS (no new model classes; wire
  messages are Maps by seam design). The two adapters are hand-curated
  I/O adapters — the standing "HAND-CURATED — DO NOT REGENERATE VIA zfa"
  precedent (mcp_wire.dart, 015), not model-layer drift.
- **X. Post-Build Analysis Must Be Pristine** — PASS. Baseline at `09e63f6`
  is `No issues found!` (the 0.1.1 template cleanup fixed the previously
  recorded findings); the gate for this feature is zero findings repo-wide.

## Project Structure

### Documentation (this feature)

```text
specs/105-production-mcp-transports/
├── spec.md               # /speckit.specify output (seeded from issue #107)
├── plan.md               # This file
├── checklists/
│   └── requirements.md   # specify-stage quality checklist
├── research.md           # Phase 0 — wire dialect + test-strategy decisions
├── data-model.md         # Phase 1 — lifecycle state + failure taxonomy
├── contracts/
│   └── mcp-wire-dialect.md  # the exact JSON-RPC/SSE/stdio framing contract
├── quickstart.md         # how to run the new integration tests
├── tasks.md              # /speckit.tasks output
└── tdd/
    ├── test-list.md      # /speckit.tdd.plan output
    ├── cycle-log.md      # /speckit.tdd.run evidence (append-only)
    └── verification.md   # /speckit.tdd.verify audit report
```

### Source Code (repository root)

```text
lib/src/mcp/
├── io_stdio_mcp_transport.dart  # EDIT: stub → real (Process + stdin/stdout JSON-RPC)
└── io_sse_mcp_transport.dart    # EDIT: stub → real (HttpClient GET/POST + SSE parser)

test/mcp/
├── io_stdio_mcp_transport_test.dart  # NEW: hermetic integration behaviors
├── io_sse_mcp_transport_test.dart    # NEW: hermetic integration behaviors
└── _mock_stdio_mcp_server.dart       # NEW: mock MCP child script (dart run)
```

**Structure Decision**: no new lib files — the spec's Files section edits the
two existing stubs in place (their headers document them as the allowlisted
adapters). Tests mirror under `test/mcp/` per the house layout.

## Components

### 1. `IoStdioMcpTransport` — `lib/src/mcp/io_stdio_mcp_transport.dart` (US1, US3, US4 / FR-001..003, FR-007)

- State: `Process? _process`; `Map<int, Completer<McpWireResponse>>
  _pending`; `int _nextId = 0`; `StreamSubscription<String> _stdoutSub,
  _stderrSub`; `bool _closed = false`.
- `open()`: idempotent (open when already open → no-op). `Process.start(
  executable, args)`; wire `stdout` line-byline (`transform(LineSplitter)`);
  each line: JSON-decode → if it has `id` matching a pending completer,
  complete it (`result` → `McpWireResponseOk`,
  `error` → `McpWireResponseError(code: error['code'].toString(),
  message: error['message'] ?? '')`); else if it is a notification with
  `method == 'notifications/tools/list_changed'` → add
  `McpWireNotificationToolsChanged` to the notification controller; else
  ignore. stderr is drained (recorded for diagnostics, never parsed).
  Process exit: `isOpen` → false, every pending completer completes with a
  typed `McpWireClosedException`, notification stream closes.
- `send(request)`: throws `McpWireClosedException` when not open; assigns
  `id = _nextId++`, writes `{"jsonrpc":"2.0","id":N,"method":...}` +
  params as ONE newline-terminated line to stdin; awaits the completer
  (Future). Methods: `McpWireRequestListTools` → `tools/list` with
  `params: {}`; `McpWireRequestCallTool` → `tools/call` with
  `params: {name, arguments}`.
- `close()`: idempotent; kills the process, drains pending with
  `McpWireClosedException`, closes the notification controller.
- Typed failure type: `McpWireClosedException implements Exception` with a
  human-readable message (defined once in `io_stdio_mcp_transport.dart` and
  reused by the SSE adapter — adapters own their transport failure type;
  nothing above the seam changes because clients catch any `Exception`).

### 2. `IoSseMcpTransport` — `lib/src/mcp/io_sse_mcp_transport.dart` (US2, US3, US4 / FR-004..006, FR-007)

- State: `HttpClient? _client`; `HttpClientRequest? _sseGet` (kept open);
  `bool _open = false`.
- `open()`: idempotent. `HttpClient.getUrl(endpoint)` with headers
  `Accept: text/event-stream` and (when `bearerToken != null`)
  `Authorization: Bearer <token>`; response status 200 → subscribe to the
  response stream, mark open, and pump it through the SSE event parser;
  any other status → typed `McpWireOpenException(statusCode)`;
  connection error → the same exception with `statusCode: null`.
  Connection-refused propagates as `SocketException` wrapped — clients
  treat any throw as a drop and reconnect, but open() surfaces the cause
  via the typed exception's message/cause.
- SSE parser (pure, testable, inside this file): incremental decoder —
  split events on blank lines; per event, concatenate `data:` field lines
  (stripping one leading space, joining with `\n`); ignore comment lines
  (leading `:`), `event:`/`id:`/`retry:` fields (no semantic use in this
  dialect), and events with empty data. Handles CRLF and LF.
- A `data:` payload that JSON-decodes to a notification with method
  `notifications/tools/list_changed` → `McpWireNotificationToolsChanged`
  on `notifications`; other payloads ignored (responses in this dialect
  arrive on the POST reply, not the stream; stream payloads that carry an
  `id` + `result`/`error` are also ignored — reserved, see research.md).
- `send(request)`: throws `McpWireClosedException` when not open; POST to
  `endpoint` with `Content-Type: application/json` + the same auth header;
  body = the JSON-RPC request (generated id, `tools/list` / `tools/call`
  as in the stdio adapter); 2xx → decode body: `result` → Ok, `error` →
  `McpWireResponseError`; non-2xx → typed `McpWireClosedException` naming
  the status.
- `close()`: idempotent; aborts the GET, closes the client, closes the
  notification controller, `isOpen` → false.

### 3. Mock stdio MCP server — `test/mcp/_mock_stdio_mcp_server.dart` (US1, US3, US4 fixtures)

- A plain Dart script run as a subprocess via
  `Process.start(Platform.resolvedExecutable, [scriptPath, mode])` from the
  tests (`Platform.script`-independent; the test passes its own path).
- Modes: `echo` (tools/list → one `echo` tool; tools/call → result
  `{echo: arguments}`), `notify` (writes a tools-changed notification line
  first, then answers normally), `crash` (tools/list answered, then
  `exit(1)` on a `crash` tools/call), `garbage` (writes junk lines between
  valid answers).
- The script speaks exactly the contract in `contracts/mcp-wire-dialect.md`.

### 4. Integration tests — `test/mcp/io_stdio_mcp_transport_test.dart`, `test/mcp/io_sse_mcp_transport_test.dart` (SC-001..SC-005)

- stdio: spawn the mock script per test (modes above); behaviors: open
  reports open; tools/list round-trip; tools/call round-trip; session
  persistence (second call on same transport); tools-changed notification
  observed; garbage lines skipped; child exit → isOpen false + typed
  failure on next send + pending send fails typed; send-before-open typed
  failure; double open / double close no-ops.
- SSE: `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` per test; the
  handler serves the GET (200, `text/event-stream`, writes keep-alive
  comment lines + a tools-changed event) and POSTs (echo result / JSON-RPC
  error / non-200). Behaviors: open + bearer header assertion; tools/list
  + tools/call round-trips; typed error mapping; keep-alive/multi-line/CRLF
  parsing; non-200 open typed failure; send-before-open; idempotent
  open/close.

## Sequencing

1. `/speckit.tasks` — task breakdown.
2. `/speckit.tdd.plan` — derive `tdd/test-list.md` (behaviors below).
3. `/speckit.tdd.run` — red-green-refactor one behavior per cycle, evidence
   in `tdd/cycle-log.md`, commit at green (`test(105):` / `feat(105):`).
4. `/speckit.implement` — remaining non-behavioral wiring (none expected).
5. `/speckit.tdd.verify` — cold-context audit → `tdd/verification.md`;
   deliberate mutants on the highest-risk behaviors (id matching, SSE
   framing, exit handling) per the house pattern.
6. Gates: `rg "TODO|FIXME|HACK" lib/` zero; `dart analyze` clean (baseline
   "No issues found!"); `dart test` green (1202 + new); purity gate.
7. Commit, push, PR (base `master`, closes #107).

## Complexity Tracking

> No constitution violations need justification. The II/III override is the
> user's explicit, scoped instruction for this run — logged per misfire in
> the plan, cycle log, and PR description, with every escalation filed
> upstream before continuing.
