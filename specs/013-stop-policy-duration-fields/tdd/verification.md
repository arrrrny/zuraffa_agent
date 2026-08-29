---
feature: 013-stop-policy-duration-fields
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 3
proven: 0
likely: 0
test_after: 3
no_test: 0
high_smells: 1
criteria_total: 2 # no numbered ACs; spec Summary requires (1) the 5-field spec-exact surface incl. Duration, (2) value-based equality (plan.md Phase 1)
criteria_covered: 2
mutation_score: null # no mutation tool in the lockfile (profile: mutation = null)
mutants_survived: 0 # was 1 (M1 in U2); CLEARED 2026-08-29 — U4 now pins per-field inequality incl. enabled
suite: 1072 passed, 2 skipped, 0 failed, 81s (`dart test`)
---

# TDD Verification: StopPolicy Duration field support

**Verdict: FAIL.** The value-equality behavior does not hold up: deleting
`enabled == other.enabled` from `StopPolicy.operator ==` leaves the whole
`stop_policy_test.dart` file green, so U2's claim that "two policies are equal iff
every field matches" is not actually pinned. On top of that all three behaviors are
`TEST_AFTER` by the test list's own admission — the 5-field surface shipped in
`fc512a1` before the referenced test file existed, and this feature's cycle log
records no red at all.

## Test-first evidence

`specs/013-stop-policy-duration-fields/tdd/cycle-log.md` contains **only** a
Baseline entry (`fce207d`, 909 passed): no cycle, no red command, no failure
output. `test-list.md:14-16` states this outright ("this is a **test-after** plan
… No `RED` cycles were driven because the implementation preceded the list").

Relevant history for this feature's subject:

- `fc512a1` — `fix(stop_policy): extend with spec-exact Duration fields (closes #13) (#47)` — adds the 5 fields to `lib/src/domain/entities/stop_policy/stop_policy.dart` **and** 81 lines to `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` in one commit. No red is recorded for it anywhere.
- `a57f81f` — `test(spec 027): add StopPolicy default constant tests (red)` — creates `test/domain/entities/stop_policy/stop_policy_test.dart` (the file U1–U3 point at), five commits and one spec later.
- `515a01b` — `feat(spec 027): add StopPolicy.defaultPolicy canonical constant (green)`.

| Behavior | Class      | Evidence                                                                                                                                                                                                                                        |
| -------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | The 5-field surface this spec ships landed in `fc512a1`; `stop_policy_test.dart` was created later (`a57f81f`). The `defaultPolicy` half of U1 does show a test-before-source pair (`a57f81f` → `515a01b`) but belongs to spec 027 and has no red recorded in this feature's cycle log. |
| U2       | TEST_AFTER | Same file, same commit (`a57f81f`), no red output recorded for this feature; the `==`/`hashCode` implementation predates it in `fc512a1`.                                                                                                        |
| U3       | TEST_AFTER | As U2.                                                                                                                                                                                                                                          |

No existing test was weakened, loosened, renamed, or skipped: `a57f81f` is a
pure-addition commit (63 insertions, 0 deletions) and `fc512a1` deletes 15 lines
only from `stop_policy.dart` (the pre-#13 field set), not from any test.

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                                                                                                                                                                                     | Evidence                                                                        |
| --- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1   | CLEARED  | **[CLEARED 2026-08-29] Value equality is asserted only in the positive direction.** U2 built two identical policies and asserted they were equal; U3 varied exactly one field (`maxTurns`) for inequality. Nothing pinned inequality on `wallClockTimeout`, `repetitionThreshold`, or `enabled`. Confirmed by surviving mutant M1. Now resolved: U4 asserts `isNot(equals(...))` for each of the five fields (incl. `enabled`), so `operator ==` can no longer silently drop a field. | `test/domain/entities/stop_policy/stop_policy_test.dart:22,40,64`                   |
| 2   | HIGH     | **All three behaviors are `TEST_AFTER`.** No red was ever recorded for this feature; the cycle log holds only a baseline. Under the rubric this alone is a `FAIL` and cannot be repaired retroactively — it can only be recorded honestly and strengthened with the mutants the tests should have been driven by.                                                                                | `specs/013-stop-policy-duration-fields/tdd/cycle-log.md:1-10`; `test-list.md:14` |
| 3   | MED      | **The tests this spec's own `spec.md` names are not in the test list.** `spec.md:10` claims "5 new tests (#13 regression block)" in `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`, and `fc512a1` really did add them there alongside the source. `test-list.md` traces U1–U3 to a different file and never records those regression tests, so the list under-reports the coverage that actually exists for this feature. | `specs/013-stop-policy-duration-fields/tdd/test-list.md:46-51`                   |
| 4   | MED      | **Ownership drift in the test header.** The file U1–U3 point at declares itself `// Spec 27 — StopPolicy entity tests (TDD cycle 1).` and traces to spec 027's `FR-001, SC-002`. A reader arriving from spec 013 finds no marker connecting the file to this feature.                                                                                                                          | `test/domain/entities/stop_policy/stop_policy_test.dart:1-5`                     |
| 5   | MED      | **`Duration.zero` semantics are unpinned.** `stop_policy.dart:28-29` documents "Duration.zero means no wall-clock limit". U1 asserts the default *value* is `Duration.zero` but nothing asserts the meaning; the rule lives only in a comment.                                                                                                                                                | `test/domain/entities/stop_policy/stop_policy_test.dart:17`                      |
| 6   | LOW      | **Duplicated setup / magic values.** The `id: 'p1', maxTurns: 10, wallClockTimeout: Duration(seconds: 30), repetitionThreshold: 3` literal block is copied three times across U2 and U3 with no factory and no explanation of why those numbers.                                                                                                                                              | `test/domain/entities/stop_policy/stop_policy_test.dart:23,30,41,47,54`          |
| 7   | LOW      | **`toString()` is untested.** `stop_policy.dart:79-82` ships an override no behavior claims. Harmless, but it is code with no test.                                                                                                                                                                                                                                                            | `lib/src/domain/entities/stop_policy/stop_policy.dart:79`                        |

## Mutation results

No mutation tool in this repository (`.specify/memory/tdd-profile.md`:
`mutation: null`), so deliberate mutants were used. **2 of 3 behaviors sampled**
(U2/U3 equality, U1 defaults). Each mutant was applied, the file's tests run, then
the source restored from a pristine copy and verified with `git diff --quiet`; the
audited test files were re-run green (54 passed) and the full suite re-run green
(1072 passed, 2 skipped).

| Mutant                                                                                                            | Behavior | Survived | Judgment                                                                                                                                        |
| ----------------------------------------------------------------------------------------------------------------- | -------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| M1 `lib/src/domain/entities/stop_policy/stop_policy.dart:68` — drop `enabled == other.enabled` from `operator ==`  | U2, U3   | **No (cleared 2026-08-29)** | Was a survivor: two policies differing only in `enabled` compared equal and the test stayed green. CLEARED — U4 now asserts per-field inequality for all five fields incl. `enabled`; mutant M1 re-applied → U4 fails (expected), source restored → green. Source `operator ==` already compared `enabled` (line 68); the test was the gap. |
| M2 `lib/src/domain/entities/stop_policy/stop_policy.dart:53` — `defaultPolicy.maxTurns` `100` → `101`              | U1       | No       | Caught: `Expected: <100> Actual: <101>`. The documented defaults are pinned.                                                                     |

Not sampled: the `hashCode` half of U3 (`Object.hash` over five fields) — a
dropped field there is observable only through a hash collision, which is not a
reliable deliberate mutant.

## Traceability

This spec is a short PR-style document with **no numbered acceptance scenarios**
(`test-list.md` frontmatter: `spec_criteria: 0`). The two requirements graded are
the ones `spec.md` Summary and `plan.md` Phase 1 state:

| Criterion                                                                     | Tests                                                     | End to end |
| ----------------------------------------------------------------------------- | --------------------------------------------------------- | ---------- |
| Spec-exact 5-field surface (`maxTurns:int`, `wallClockTimeout:Duration`, `repetitionThreshold:int`, `enabled:bool`) | U1 (`stop_policy_test.dart:13`)  | Yes — real value object, no doubles |
| Value-based equality across all five fields (`plan.md` Phase 1)                | U2, U3 (`stop_policy_test.dart:22,40`)                    | Yes, but only positively (finding #1) |

Untested criteria: none of the two, though the second is covered too weakly to
count as verified. Tests tracing to nothing: none — all three tests in
`stop_policy_test.dart` map to U1–U3. Conversely, the 5 `#13` regression tests in
`stop_policy_mock_datasource_test.dart` trace to no behavior in this list
(finding #3).

`tasks.md` cross-check: `[U1]`, `[U2]`, `[U3]` are ticked `[x]` and all three are
`DONE` in `test-list.md`. No ticked task points at a non-`DONE` behavior. `T1`–`T5`
carry no checkbox at all, so nothing is over-claimed there.

## What was not audited

- **Coverage was not collected** for `lib/src/domain/entities/stop_policy/stop_policy.dart`.
- **The `#13` regression tests** in `test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart` were not graded: the test list does not claim them, and that file's header assigns it to spec 027.
- **Datasource / repository / service / provider layers** are out of scope for this spec (spec 027 and `014-stop-policy-clean-arch-layers` own them) and were audited separately.
- **`hashCode` field-completeness** was not mutation-tested (see above).
- **The zfa-generator claim** in `spec.md` ("zfa v6.0.0 rejects `Duration`") was not reproduced; no zfa invocation was made.
- **Performance / serialization behavior**: no criterion, no test, not assessed.
