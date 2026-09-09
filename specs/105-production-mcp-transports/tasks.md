# Tasks: Production MCP transports — SSE + stdio

**Input**: Design documents from `/specs/105-production-mcp-transports/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required) — both present.

**Tests**: The TDD extension drives this feature: every behavior on
`tdd/test-list.md` (A1–A5, U1–U19) gets a test observed failing before its
implementation (`/speckit.tdd.plan` has made the test tasks below
**mandatory** and ordered before the implementation tasks; behavior ids in
brackets are the load-bearing link `/speckit.tdd.run` ticks against).

**Organization**: Tasks are grouped by user story (US1..US5 from spec.md).
US1 (stdio) and US2 (SSE) are independent transports in different files —
each is a complete, independently testable increment; US3 (notifications)
and US4 (lifecycle) cut across both adapters; US5 is the issue #107 hygiene
acceptance. Behavior ids follow `tdd/test-list.md` (numbered by component:
U1–U12 stdio, U13–U19 SSE).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1..US5)

## Path Conventions

- Single project: `lib/src/mcp/...` sources, `test/mcp/...` mirrored tests
  (house layout; see plan.md Project Structure).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Feature scaffolding the pipeline creates.

- [x] T001 Create `specs/105-production-mcp-transports/` with spec.md seeded
  from issue #107 (done by `/speckit.specify`)
- [x] T002 Write `/speckit.plan` artifacts: plan.md, research.md,
  data-model.md, contracts/mcp-wire-dialect.md, quickstart.md, this tasks.md
  scaffold (setup-script misfire arrrrny/zuraffa#1417 workaround — executed
  directly)

---

## Phase 2: Foundational — mock stdio MCP server fixture (blocks US1/US3/US4 stdio tests)

**Goal**: A hermetic, scriptable mock MCP child process speaking the
contract in `contracts/mcp-wire-dialect.md`.

- [ ] T003 [P] Create `test/mcp/_mock_stdio_mcp_server.dart` — plain Dart
  script, `<mode>` argv: `echo` (tools/list → one `echo` descriptor;
  tools/call → `{echo: arguments}`), `notify` (tools-changed notification
  line first, then normal answers), `crash` (answers tools/list, then
  `exit(1)` on a `crash` tools/call), `garbage` (junk lines — non-JSON and
  valid-JSON-unknown-id — interleaved with valid answers, and an
  `error`-replying tool for [U5]). Newline-delimited JSON-RPC per the
  contract. Test fixture only — no behavior marker (the transports' tests
  are its proof).

**Checkpoint**: fixture runs: feed it
`{"jsonrpc":"2.0","id":0,"method":"tools/list","params":{}}` and it answers
a result line.

---

## Phase 3: US1 Real stdio transport (Priority: P1) 🎯

**Goal**: `IoStdioMcpTransport` spawns the server and round-trips RPC over
stdin/stdout, mapping results and application errors.

**Independent Test**: against the mock child, tools/list returns the
advertised descriptor and tools/call echoes arguments — twice, proving a
session; an error reply maps to the typed error response.

### Tests for US1 (written FIRST, observed failing)

- [x] T004 [P] [US1] Test `test/mcp/io_stdio_mcp_transport_test.dart`
  (round-trip group) — [U1] open() spawns the mock (`echo` mode) and
  `isOpen` is true afterwards, [U2] `tools/list` returns the mock's
  advertised descriptor (`name: echo`, `paramsSchema` preserved),
  [U3] `tools/call` round-trips arguments and a second call on the SAME
  transport succeeds (session, id counter advances), [U5] a JSON-RPC error
  reply maps to `McpWireResponseError` (stringified code + message),
  [U8] a response line with an unknown id is dropped and the in-flight
  request still resolves (garbage mode) — closes acceptance [A1].
- [x] T005 [P] [US1] Test `test/mcp/io_stdio_mcp_transport_test.dart`
  (validation group) — [U4] constructor rejects an empty `executable` with
  `ArgumentError` naming the field (eager, fails at construction).

### Implementation for US1

- [x] T006 [US1] Implement `IoStdioMcpTransport.open/send` +
  `McpWireClosedException` in `lib/src/mcp/io_stdio_mcp_transport.dart`
  (plan.md Component 1: Process.start, line-framed JSON-RPC writes,
  id-matched pending map, error mapping, eager constructor validation;
  header keeps the hand-curated attribution and drops the stub TODO) —
  makes [U1]–[U5], [U8] green and closes [A1].

**Checkpoint**: US1 independently functional — a real stdio MCP session.

---

## Phase 4: US2 Real SSE transport (Priority: P1)

**Goal**: `IoSseMcpTransport` opens the event stream with bearer auth and
round-trips RPC via POST, mapping results and errors.

**Independent Test**: against a loopback `HttpServer` mock, open+auth
succeed, tools/list and tools/call round-trip, open/POST failures map typed.

### Tests for US2 (written FIRST, observed failing)

- [x] T007 [P] [US2] Test `test/mcp/io_sse_mcp_transport_test.dart`
  (round-trip group) — [U13] open() GETs the endpoint with
  `Accept: text/event-stream` and the `Authorization: Bearer` header when a
  token is configured (asserted server-side) and `isOpen` is true,
  [U15] `tools/list` POST returns the mock's advertised payload,
  [U16] `tools/call` POST round-trips arguments/result with the contract's
  JSON-RPC envelope asserted server-side — closes acceptance [A2] together
  with [U14]/[U17].
- [x] T008 [P] [US2] Test `test/mcp/io_sse_mcp_transport_test.dart`
  (failure group) — [U14] non-200 open (404 served) fails with a typed
  exception naming the status and the constructor rejects a non-http(s)
  endpoint with `ArgumentError`, [U17] POST-level failures: a 2xx body with
  a JSON-RPC error object maps to `McpWireResponseError`, a non-2xx POST
  fails the send typed.

### Implementation for US2

- [x] T009 [US2] Implement `IoSseMcpTransport.open/send` in
  `lib/src/mcp/io_sse_mcp_transport.dart` (plan.md Component 2: HttpClient
  GET + POST, bearer header, status checks, JSON-RPC mapping, typed
  `McpWireOpenException`; header updated) — makes [U13]–[U17] green,
  closing [A2] with the US2 tests.

**Checkpoint**: US1 + US2 functional — both real transport modes work.

---

## Phase 5: US3 Server-pushed notifications (Priority: P2)

**Goal**: tools-changed pushes surface on `notifications` from both
transports; garbage is ignored.

**Independent Test**: a mock-pushed tools-changed notification is observed;
junk lines/events produce nothing and no crash.

### Tests for US3 (written FIRST, observed failing)

- [x] T010 [US3] Test `test/mcp/io_stdio_mcp_transport_test.dart`
  (notifications group) — [U6] `notify`-mode mock's
  `notifications/tools/list_changed` line is observed on `notifications`
  before the normal answer resolves, [U7] `garbage`-mode junk lines produce
  no notification and no crash; subsequent RPC still succeeds.
- [x] T011 [P] [US3] Test `test/mcp/io_sse_mcp_transport_test.dart`
  (SSE parsing group) — [U18] a tools-changed SSE event delivered after
  keep-alive comment lines and CRLF terminators is observed on
  `notifications`; empty-data and unrecognized events are ignored; a
  multi-line `data:` field joins into one payload.

### Implementation for US3

- [x] T012 [US3] Implement notification paths: stdio stdout-line
  notification parsing + SSE incremental event parser (plan.md Component 2
  parser: comment/`event:`/`id:`/`retry:` ignored, `data:` join, CRLF/LF) —
  makes [U6], [U7], [U18] green, closing [A3].

**Checkpoint**: both transports push typed notifications; noise is inert.

---

## Phase 6: US4 Lifecycle safety (Priority: P1)

**Goal**: Drops, exits, and misuse are observable and typed — never
`UnimplementedError`, never a hang.

**Independent Test**: child exit flips isOpen and fails pending+subsequent
sends typed; send-before-open fails typed; open/close are idempotent.

### Tests for US4 (written FIRST, observed failing)

- [x] T013 [US4] Test `test/mcp/io_stdio_mcp_transport_test.dart` (exit
  group) — [U9] `crash`-mode child exit: `isOpen` → false, an in-flight
  send completes with the typed failure, a subsequent send throws the same
  typed failure (client reconnect contract: throw, not response),
  notification stream closes.
- [x] T014 [P] [US4] Test both transport files (misuse + teardown group) —
  [U10] send-before-open/after-close throws typed (stdio), [U11] double
  open and double close are no-ops (stdio, no second spawn), [U12] close()
  terminates the child, closes notifications, pending sends fail typed
  (stdio), [U19] SSE lifecycle: send-before-open typed, double open (no
  second GET)/double close no-ops, close() aborts the GET and subsequent
  send throws typed — closes acceptance [A4].

### Implementation for US4

- [x] T015 [US4] Implement lifecycle handling: stdio exit propagation +
  pending-completer resolution + idempotence guards (both adapters);
  `close()` idempotent teardown (plan.md lifecycle state machine) — makes
  [U9]–[U12], [U19] green, closing [A4].

**Checkpoint**: all US1–US4 behaviors green on real I/O.

---

## Phase 7: US5 The issue #107 hygiene acceptance (Priority: P2)

**Goal**: the issue's mechanical definition of done.

- [x] T016 [US5] Acceptance gates [A5]: `rg "TODO|FIXME|HACK" lib/` zero
  hits; `dart analyze` zero findings repo-wide (constitution X); `dart test`
  green (baseline 1202 + new); purity gate unchanged (no new dart:io files
  beyond the two allowlisted adapters). Any red here is a behavior fix with
  its own cycle, not a workaround.

---

## Phase 8: Gates & Polish

- [ ] T017 Run `/speckit.tdd.verify` → `tdd/verification.md` (audits all
  behaviors incl. [A1]–[A5] coverage; deliberate mutants on the
  highest-risk behaviors: id matching, SSE framing, exit propagation).
- [ ] T018 Commit spec-kit artifacts + source per the repo's `spec(105):` /
  `feat(105):` / `test(105):` convention; push branch; open PR to `master`
  closing #107.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: complete.
- **Phase 2 (mock fixture)**: blocks the stdio test tasks (T004, T005, T010,
  T013, T014); independent of SSE tasks.
- **Phase 3 (US1 stdio)** and **Phase 4 (US2 SSE)**: independent — different
  lib files and test files, either can land first (US1 first is the default
  order: no HTTP layer).
- **Phase 5 (US3)**: needs US1+US2 send paths (notifications piggyback on
  the I/O loops).
- **Phase 6 (US4)**: needs US1+US2 (lifecycle wraps their state).
- **Phase 7 (US5 gates)**: needs all behaviors.
- **Phase 8**: last.

### Within Each User Story

- Tests MUST be written and observed failing before implementation
  (TDD extension discipline; `/speckit.tdd.run` drives this).
- Adapter implementation lands only against its failing tests.

### Parallel Opportunities

- T003 first (fixture); T004 ∥ T005; T007 ∥ T008; T010 ∥ T011 (different
  files); gates at the end are serial.

---

## Implementation Strategy

### MVP First (US1 only)

US1 alone is a viable MVP: local-subprocess MCP servers work end-to-end
(the more common integration mode), hermetically tested.

### Incremental Delivery

1. US1 → stdio session (testable, shippable)
2. US2 → SSE session (networked servers)
3. US3 → notifications (cache invalidation feeds spec 082 surfaces)
4. US4 → lifecycle safety (feeds issue #120 resilience work)
5. US5 → issue #107 acceptance gates
6. Gates + PR

---

## Notes

- Commit cadence: one commit per green TDD cycle (test + implementation
  together), message convention `test(105):`/`feat(105):` per `git log`.
- Behavior ids are canonical in `tdd/test-list.md` (this file was re-marked
  by `/speckit.tdd.plan` from its provisional by-story ids to the
  by-component series U1–U19 — every task still open was re-marked, none
  renumbered or reworded otherwise).
- The two lib files are HAND-CURATED (purity allowlist) — the loop edits
  them in place; never regenerate via zfa make.
