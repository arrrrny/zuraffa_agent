# TDD Cycle Log: Production MCP transports — SSE + stdio (spec 105)

Append-only record of the red-green-refactor cycles. One entry per cycle;
RED evidence quoted verbatim from the failing runs.

## Baseline

- **planned_at**: 2026-09-09, HEAD `09e63f6` (branch `105-production-mcp-transports`)
- **suite**: 1202 passed, 0 failed, ~2 skipped, ~70s wall (`dart test`,
  default lane, `slow` tier excluded per dart_test.yaml)
- **analyzer**: `No issues found!` (repo-wide)
- **hygiene gate**: `rg "TODO|FIXME|HACK" lib/` → 2 hits (the two stub
  TODO comments this spec removes — the pre-feature RED state of A5)
- **misfires**: #1 — `.specify/scripts/bash/setup-plan.sh` /
  `setup-tasks.sh` / `check-prerequisites.sh` absent on fresh clone
  (`.specify/*` gitignored, not CLI-regenerable) → filed
  arrrrny/zuraffa#1417; workaround: plan/tasks/test-list workflows executed
  directly, feature pinned via `.specify/feature.json`. Per the run's
  explicit misfire protocol (user-authorized override of constitution II/III
  for this run): report upstream, continue with the workaround.

## Cycle 1 — stdio open: a real subprocess session (U1)

**Scope**: `IoStdioMcpTransport.open` spawns the mock child and reports open;
`close()` kills the child. Fixture `test/mcp/_mock_stdio_mcp_server.dart`
created as test infrastructure (no behavior marker of its own).

### RED

```
$ dart test test/mcp/io_stdio_mcp_transport_test.dart
00:00 +0 -1: spec-105 — IoStdioMcpTransport U1: open spawns the mock child and reports open [E]
  UnimplementedError: IoStdioMcpTransport.open not yet implemented — see spec 015 plan.md Phase 8
  package:zuraffa_agent/src/mcp/io_stdio_mcp_transport.dart 37:5  IoStdioMcpTransport.open
```

### GREEN

`open()`: `Process.start` + stdout/stderr drained through a LineSplitter (a
child blocked on a full pipe is a hung session; line semantics arrive with
the send path), `_isOpen = true`. `close()`: kill + cancel subs + close the
notification controller.

```
$ dart test
00:31 +1202 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None needed — open/close pairing is the minimal shape.

### Notes

- Existing pin `IoStdioMcpTransport stub behavior > open() throws
  UnimplementedError` (test/data/providers/mcp_transport/mcp_transport_provider_test.dart)
  broke on this cycle — it pinned the stub era this spec replaces. Per the
  loop's Hard Rule 4 the outdated pin was retired as its own step, reason
  recorded in the test file; the `send()` pin stays until the send-path
  cycle replaces it. Suite: −1 (pin) +1 (U1) = 1202.
- 3 analyzer findings in the new fixture (dynamic / `List` inference)
  fixed within the same green step — constitution X (pristine analysis).

## Cycle 2 — stdio tools/list round-trip (U2)

**Scope**: `send` writes the contract's JSON-RPC envelope to the child's
stdin and resolves with the id-matched `result` payload.

### RED

```
$ dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "U2: tools/list round-trips the advertised descriptors"
00:00 +0 -1: spec-105 — IoStdioMcpTransport U2: tools/list round-trips the advertised descriptors [E]
  UnimplementedError: IoStdioMcpTransport.send not yet implemented — see spec 015 plan.md Phase 8
```

### GREEN

`send`: closed-guard (typed `McpWireClosedException`), monotonic id,
per-request envelope via exhaustive switch on the sealed request family,
`writeln`+`flush` to stdin, future from the pending map. `_handleLine`:
JSON-decode (junk skipped), id-matched `result` → `McpWireResponseOk`.

```
$ dart test
00:35 +1202 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None — first shape of the parse path; error/notify branches arrive with
their own cycles (U5, U6).

### Notes

- The remaining `send() throws UnimplementedError` pin (stdio group,
  provider tests) retired in this cycle per the reason recorded in-file at
  cycle 1. Suite: −1 (pin) +1 (U2) = 1202.

## Cycle 3 — stdio tools/call round-trip + session persistence (U3)

**Scope**: `tools/call` carries arguments through the envelope; a second
call on the same transport proves a session.

### RED

First run PASSED (the U2 send path is generic over the sealed request
family) → deliberate-mutant check per the playbook:

```
MUTANT: tools/call envelope drops 'arguments'
$ dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "U3:"
00:00 +0 -1: spec-105 — IoStdioMcpTransport U3: tools/call round-trips arguments and the session persists [E]
  Expected: {'echo': {'x': 1}}
    Actual: {'echo': {}}
```

The test detects an argument round-trip regression. Mutant restored exactly.

### GREEN

```
$ dart test
00:53 +1203 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None needed.

### Notes

- Suite +1 (U3, no pin removed this cycle) = 1203.

## Cycle 4 — stdio constructor validation (U4)

**Scope**: an empty `executable` fails at construction, before any process.

### RED

```
$ dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "U4:"
00:00 +0 -1: spec-105 — IoStdioMcpTransport U4: constructor rejects an empty executable [E]
  Expected: throws <Instance of 'ArgumentError'>
     Which: returned <Instance of 'IoStdioMcpTransport'>
```

### GREEN

Constructor eagerly validates `executable` (`ArgumentError.value` naming the
field) — misconfiguration fails at construction, per data-model.md.

```
$ dart test
00:53 +1204 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None needed.

## Cycle 5 — stdio garbage-line tolerance (U7) — driven out of list order

**Scope**: non-JSON log-noise lines from the child are skipped; the session
survives. Driven BEFORE U5/U8 (deliberate execution-order deviation): their
tests use the same `garbage`-mode child, whose junk lines would fail their
reds for the wrong reason until this tolerance exists.

### RED

First run PASSED (cycle 2's parser already swallowed `FormatException`) →
deliberate-mutant check:

```
MUTANT: junk tolerance removed from _handleLine
$ dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "U7:"
00:00 +0 -1: spec-105 — IoStdioMcpTransport U7: garbage lines are skipped and the session survives [E]
  FormatException: Unexpected character (at character 1)
```

Mutant restored exactly.

### GREEN

```
$ dart test
00:38 +1205 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None needed.

### Notes

- Suite +1 = 1205.

## Cycle 6 — stdio JSON-RPC error mapping (U5)

**Scope**: a child's `error` response object becomes
`McpWireResponseError` (stringified code + message), not an exception.

### RED

```
$ dart test test/mcp/io_stdio_mcp_transport_test.dart --plain-name "U5:"
00:00 +0 -1: spec-105 — IoStdioMcpTransport U5: a JSON-RPC error response maps to the typed error response [E]
  Expected: <Instance of 'McpWireResponseError'>
    Actual: <Instance of 'McpWireResponseOk'>
```

### GREEN

`_responseFor`: `error` map → `McpWireResponseError(code, message)`;
otherwise `result` map → `McpWireResponseOk`.

```
$ dart test
00:57 +1206 ~2: All tests passed!
$ dart analyze
No issues found!
```

### REFACTOR

None — the mapping extracted into `_responseFor` is the cycle's own shape.
