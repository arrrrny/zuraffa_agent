---
feature: 038-ui-tree-payload
verdict: PASS
verified_at: 7e69612
behaviors_total: 17
behaviors_done: 17
test_first: 8 PROVEN (U1..U6, U9, U10 — compile reds recorded), 3 baseline (U7, U8, clean-arch row — pre-existing), 6 acceptance behaviors green
mutation: 4/4 killed (M1 value-arm, M1b full mimeType check, M2 changed-detection, M3 toJson key) + 1 initially mis-aimed survivor documented
criteria_covered: 7/7 acceptance criteria, 6/6 FRs
suite: 727 passed, 0 failed
analyze: 5 pre-existing issues, 0 new (two fixture warnings caught and fixed pre-commit)
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
---

# TDD Verification: UiTreePayload value object (serialization + diffing slice)

## Verdict

**PASS** — the ui/tree+json serialization contract (exact four-key toJson,
mimeType-checked lossless fromJson) and the path-keyed structural diff with
pinning-drift flags are traced to red-first tests with verbatim compile-error
evidence; four deliberate mutants were killed (plus one documented mis-aimed
mutant re-run correctly); the 11 pre-existing tests pass unchanged; the full
suite is green at 727 with the analyzer held at the 5-issue baseline — two
inference warnings in the new fixtures were caught by the analyze gate and
fixed BEFORE the commit that would have violated constitution X.

Independence note: same-session audit; findings re-derived from the files.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | U1..U6, U9, U10 | cycle-log cycles 1-2: compile reds (`Member not found: 'UiTreePayload.fromJson'`, `The method 'toJson'/'diff' isn't defined`), all recorded before implementation; commits `fda576f`, `7e69612` |
| BASELINE (pre-existing) | U7, U8, clean-arch row | 11 provider-suite tests green throughout; file byte-identical to `43dffd7` |

Changes to pre-existing tests: NONE.

Process deviation disclosed: a cycle-1 implementation edit briefly included
cycle-2's diff code; it was reverted before any test run or commit, and diff
landed strictly after its own red in cycle 2 (cycle log records it).

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 | `parsedMime != mimeType` arm disabled (`\|\| false`) | first aimed at "U2: missing mimeType" -> SURVIVED (the `is! String` guard covers the missing case); re-aimed at "U2: wrong mimeType" | KILLED — `Expected: throws ... contains 'mimeType' / Actual: <Closure: () => UiTreePayload>` |
| M1b | whole mimeType check removed (`if (false)`) | "U2: missing mimeType" | KILLED — same shape; both arms load-bearing |
| M2 | changed-detection disabled | U4 | KILLED — `Expected: ['root/1'] / Actual: []` |
| M3 | toJson key `mimeType` -> `mimeTypeX` | U1 | KILLED — `Expected: Set:['mimeType', ...] / Actual: Set:['mimeTypeX', ...]` |

All mutants restored exactly (`git diff --stat lib/` = 0) and the file re-run
green (11/11) after each. The M1 mis-aim is recorded as an audit lesson: a
mutant proves only the arm its test actually exercises.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 lossless round-trip | A1 (U1, U6) | PROVED |
| AC US1-2 mimeType entry check | A2 (U2; M1/M1b killed) | PROVED |
| AC US1-3 pinning/tree shape errors | A3 (U2) | PROVED |
| AC US2-1 exact path sets on mixed fixture | A4 (U3, U4; M2 killed) | PROVED |
| AC US2-2/3 pinning flags + empty diff | A5 (U5) | PROVED |
| AC US3-1 precompute pins | A6 (U8 baseline) | PROVED (baseline-pinned) |
| AC US3-2 construction validation pins | A7 (U7 baseline) | PROVED (baseline-pinned) |

FR-001..FR-006 traced (FR-006 by the untouched green provider tests);
SC-001..SC-006 proved — SC-006 via the final gates below.

## Final gates

- `dart test` -> **727 passed, 0 failed** (`All tests passed!`, pipefail-gated)
- `dart analyze` -> 5 issues, all pre-existing. Zero new (two fixture
  inference warnings were introduced and eliminated before the commit).

## Findings

- **LOW** — the M1 survivor incident: a mutant aimed at the wrong test
  initially "passed"; the audit re-aimed it and recorded both runs. No code
  change resulted; the test suite itself was never weak — the mutant's aim
  was.
- **LOW** — positional diff semantics: a mid-list insert surfaces as a run of
  changed paths rather than a minimal add/remove pair (documented in code and
  spec; a keyed-by-id diff is future work if node ids enter the vocabulary
  contract).
- **INFO** — minimal-anchor semantics (ancestors never flagged for descendant
  changes) were decided BY the red test in cycle 2 — the specification
  benefit of writing the expectation first.

No HIGH findings. No criteria without tests. No tests tracing to nothing.
