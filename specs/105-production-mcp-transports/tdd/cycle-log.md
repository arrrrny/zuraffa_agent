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
