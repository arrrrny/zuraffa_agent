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
