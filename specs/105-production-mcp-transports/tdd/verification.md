---
feature: 105-production-mcp-transports
verified_at: f032778
remediation_passes: 1
suite: "1223 passed, 0 failed, ~2 skipped (~42s wall)"
analyzer: "No issues found!"
hygiene_rg: "zero matches in lib/"
purity_gate: "PASS (run locally with pipeline.yml logic)"
behaviors_total: 24
behaviors_done: 24
test_after: 0
high_smells: 0
med_smells: 0
low_smells: 3 (accepted: behavior-id prefixes in names; _scriptPath duplication; U13 double-open re-check)
audit_mutants: "4 run — 3 killed, 1 judged equivalent"
standard: "speckit-tdd-verify skill text + house precedent (specs 082/104 verification.md); rubric template file absent on this machine (.specify/* gitignored)"
independence: "NOT fully independent — the loop author ran this audit. The smell pass was delegated to a fresh-context subagent (13 findings, all vetted against the cited lines)."
---

# TDD Verification: Production MCP transports — SSE + stdio (spec 105)

## Verdict

**PASS_WITH_GAPS** — every behavior is DONE with red evidence recorded and
deliberate-mutant strength demonstrated, but git cannot independently prove
test-before-implementation ordering inside the one-commit-per-green-cycle
cadence, so test-first classifications are LIKELY rather than PROVEN.

## Remediation pass 1 (post-audit, T019–T022)

Cleared all three MEDIUM findings and the accepted LOWs:

- **MED-1 fixed**: U6 subscribes to `notifications` before `open()` (the
  U18/A3 pattern); proven by 3 consecutive green runs of the file.
- **MED-2 fixed**: `addTearDown(transport.close)` / `addTearDown(mock.stop)`
  at every resource creation in both files and the cross-transport group.
- **MED-3 fixed**: U15 and U8 now assert the exact descriptor map; U7
  asserts the exact descriptor (its junk-skip purpose is decisive; it no
  longer duplicates U8's weak form).
- **LOWs applied**: U14 splits into U14 (404 status asserted via predicate)
  + U14b (endpoint validation); U17 splits into U17 (error-body mapping) +
  U17b (non-2xx typed throw); U13's redundant in-test `mock.stop()` removed;
  `dart format` applied to all three new test files.

Post-remediation suite: 1223 passed / 0 failed (U17→U17b and U14→U14b add
two tests), analyzer clean. Remaining LOWs accepted with rationale:
behavior-id prefixes in test names are the tdd.run tick contract (deliberate
house deviation); `_scriptPath` duplication keeps the two test files
independently runnable; U13's re-check is the idempotence pin's second
observation.

## Test-first evidence (per behavior)

| Classification | Count | Behaviors |
|---|---|---|
| PROVEN (red committed before green) | 0 | — one commit per green cycle: git cannot show intra-commit ordering |
| LIKELY (recorded red + same-commit green) | 13 | U1, U2, U4, U5, U6, U9, U12, U13, U14, U15, U18, A5 (gates), A3/A4 |
| LIKELY + mutant-verified red (pass-first cycles) | 11 | U3, U7, U8, U10, U11, U16, U17, U19, A1, A2 (auth mutant), A4 (exit mutant) |
| TEST_AFTER | 0 | — |
| NO_TEST | 0 | — |

Corroboration for the LIKELY class: each cycle log entry quotes the
verbatim red output — the early reds quote the `UnimplementedError` stub
messages that only existed before the feature (externally verifiable
against the parent commit), and the pass-first cycles each record an
observed mutant kill. The gap is real (self-reported log, not git) and is
the reason the verdict is not PASS.

## Existing-test changes (highest-signal check)

`test/data/providers/mcp_transport/mcp_transport_provider_test.dart`: four
assertions removed — the four "open()/send() throws UnimplementedError"
stub pins (2 SSE, 2 stdio). Each retirement is a stated-reason step recorded
in the cycle log (cycles 1, 2, 14, 16) and in-file. Judged legitimate: the
pins asserted the stub era this spec exists to replace, and the replacement
coverage (real sessions + typed closed-send) is strictly stronger. Not a
weakening-to-reach-green finding.

## Smell pass (fresh-context subagent, vetted)

- **MED-1** `io_stdio_mcp_transport_test.dart:113` — U6 subscribes to
  `notifications` after `open()`; the notify child emits at startup and
  broadcast streams drop unlistened events. Latent race; the file itself
  uses the correct subscribe-before-open pattern elsewhere (U18, A3).
- **MED-2** `io_stdio_mcp_transport_test.dart` (whole file) and
  `io_sse_mcp_transport_test.dart:328-395` — no `addTearDown`; a failing
  expect before the trailing `close()` leaks a live child process / bound
  server.
- **MED-3** `io_sse_mcp_transport_test.dart:168` — U15 asserts
  `isNotEmpty` where the mock defines the exact descriptor list; U7
  (`io_stdio...:75`) is subsumed by U8 for the same reason.
- **LOW (9)**: U14 does not assert `statusCode == 404` though the exception
  carries it; U8's payload assertion could be exact; U13's in-test
  `mock.stop()` duplicates tearDown; A4's SSE half restates U19; behavior-id
  prefixes in test names vs the exemplar's sentence style; U17/U14 pack two
  scenarios per test; `_scriptPath` duplicated across files; a formatting
  artifact at `io_sse...:106`; U13 double-open re-check duplicates U19.

## Test strength (deliberate mutants — sampled, not exhaustive)

| Mutant | Target behavior | Result |
|---|---|---|
| FIFO completion instead of id-matched | U8 | KILLED |
| `data:` join without separator | U18 | SURVIVED — judged EQUIVALENT (JSON is whitespace-insensitive; no JSON payload can distinguish the separator) |
| Per-line dispatch (no event accumulation) | U18 | KILLED |
| Exit handler skips draining pending sends | U9 | KILLED |
| (in-cycle mutants, recorded in log) | U3, U7, U10, U11, U16, U17, U19, A1, A2, A4 | 10 KILLED |

Coverage: not run as a gate (profile has the command; used as corroboration
only where the mutants already decide strength).

## Traceability

| Criterion | Behaviors | Test (exists & runs) |
|---|---|---|
| SC-001 | A1 ← U1–U3, U5, U8 | io_stdio…test.dart ✓ |
| SC-002 | A2 ← U13–U17 | io_sse…test.dart ✓ |
| SC-003 | A3 ← U6, U7, U18 | both files ✓ |
| SC-004 | A4 ← U9–U12, U19 | both files ✓ |
| SC-005 | A5 (gates) | rg + analyze + suite + purity, all green ✓ |
| FR-001..FR-008 | U-rows in test-list `traces` column | all resolve ✓ |

Real entry point: the transports are the public surface; every criterion is
tested through real subprocess / loopback HTTP I/O — no doubled boundaries
at the acceptance level.

## What was not audited

- Performance/latency of the transports (no criterion).
- Real (non-mock) MCP server compatibility — the upstream Streamable-HTTP
  dialect gap is explicitly out of scope (spec Assumptions).
- Mutation was sampled (4 audit mutants + 10 in-cycle), not exhaustive; no
  automated mutation ruleset exists in the repo (profile: `mutation: null`).
- Coverage percentage not used as a gate.
- Windows/macOS process-semantics differences (audited on macOS only).
- The audit was performed by the loop author with a fresh-context smell
  delegate — not a fully independent second session.
