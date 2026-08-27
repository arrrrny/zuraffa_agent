---
feature: 031-tool-result-value-object
verdict: PASS
verified_at: f5c4e92
behaviors_total: 17
behaviors_done: 17
test_first: 16 PROVEN, 1 NOT_APPLICABLE (U9 baseline)
mutation: 4/5 killed, 1 equivalent-by-design (M5, documented)
criteria_covered: 8/8 acceptance criteria, 7/7 FRs
suite: 578 passed, 0 failed
analyze: 5 pre-existing issues, 0 new
---

# TDD Verification: ToolResult value object

## Verdict

**PASS** — success/error discrimination, JSON round-trip serialization, and
oversized-result handling are traced to passing tests through the value
object's public API; the change landed test-first with compile-level red
evidence; four of five deliberate mutants were killed, the fifth being
equivalent-by-design; and the one inaccurate claim made during planning (the
scaffold hashCode "contract violation") was experimentally falsified and
corrected in the spec before this report was written.

## Test-first evidence

| class          | behaviors | evidence |
| -------------- | --------- | -------- |
| PROVEN         | A1..A8 + U1..U8 | test-only commit (16 tests) precedes the implementation commit `bf98bbb`; red recorded as compile errors (`Member not found: 'ToolResult.error'/'success'`) — the whole surface was absent |
| NOT_APPLICABLE | U9 (7 pre-existing provider/compile-parity tests) | green against untouched layers (FR-007) |

Honest granularity note: the three planned behavior groups (isError/equality,
serialization, oversized) share one test-first commit because the file does not
compile until the surface exists; behavior-level reds were not individually
staged. Recorded in the cycle log.

Changes to pre-existing tests: NONE — the 7 pre-existing tests pass unchanged
(verified in the green run and again after every mutant restore).

## Mutation results (deliberate hand-mutants)

| mutant | change | run | result |
| ------ | ------ | --- | ------ |
| M1 isError dropped from toJson | serialization loses the flag | A2 | KILLED — parsed result had `isError: false` |
| M2 fromJson ignores isError | parse always false | A2 | KILLED — same observable, parse side |
| M3 isSummarized inverted | `!= null` → `== null` | A4 + A6 | KILLED both directions — `Expected: true, Actual: <false>` and inverse |
| M4 equality ignores isError | `==` drops the axis | U3 | KILLED — success/error pair compared equal |
| M5 payload fold removed from hashCode | hash drops payloadHash | A7 | SURVIVED — **equivalent-by-design**: this is the scaffold's own legal hash; hash quality (collision distribution) cannot be asserted deterministically because collisions are legal. Documented, not remediated |

Every mutant was restored exactly (`git diff --stat lib/` = 0) and the affected
files re-run green.

## Acceptance-criteria coverage

| criterion | behaviors | status |
| --------- | --------- | ------ |
| AC US1-1 success+payload round-trip | A1 | PROVED |
| AC US1-2 error round-trip | A2 (+M1/M2 killed) | PROVED |
| AC US1-3 absent payload stays absent | A3 | PROVED |
| AC US2-1 oversized path shape | A4 (+M3 killed) | PROVED |
| AC US2-2 ref survives round-trip | A5, U8 | PROVED |
| AC US2-3 inline omits ref | A6 (+M3 killed) | PROVED |
| AC US3-1 equal results hash equally | A7, U4 | PROVED (contract guard — green on both scaffold and refined hash) |
| AC US3-2 per-axis inequality | A8 (+M4 killed) | PROVED |

FR-001..FR-007 traced (FR-007 by the untouched green provider tests); SC-001..
SC-006 proved (SC-006 via final gates below).

## Final gates

- `dart test` -> **578 passed, 0 failed** (post-29 baseline 562; +16)
- `dart analyze` -> 5 issues, all pre-existing and unrelated. Zero new issues.

## Findings

- **LOW** — planning claim corrected during verification: the scaffolded
  hashCode did NOT violate the ==/hashCode contract (proven by running A7
  against the reverted scaffold hash — it passed). The real weakness was
  deterministic payload-only collisions (legal). Spec/plan amended in
  `f5c4e92`; the refined commutative payload fold ships as a distribution
  improvement whose quality is not deterministically testable (M5 equivalent).
- **LOW** — process incident: one `git checkout` during the scaffold-hash
  experiment discarded the then-uncommitted implementation; it was rewritten
  identically and committed before further experiments. All later restores were
  verified against committed state. No code was lost in the final history.
- **INFO** — U6 (oversized requires summary + ref) asserts the constructor
  accepts the full contract; Dart const constructors cannot assert required
  named params beyond the type system, so the "requires" is enforced by the
  parameter list itself (compile-time), with the test pinning behavior.

No HIGH findings. No criteria without tests. No tests tracing to nothing.
