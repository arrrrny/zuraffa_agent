---
feature: 014-planner-todo-system
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 01618f3 # short SHA audited
behaviors: 8
proven: 0
likely: 0
test_after: 8
no_test: 0
high_smells: 2
criteria_total: 5 # US1-AC1, US1-AC2, US2-AC1, US2-AC2, US3-AC1
criteria_covered: 3 # US1-AC2, US2-AC1, US3-AC1 verified; US1-AC1 and US2-AC2 only flag-deep
mutation_score: null # no mutation tool in the lockfile (profile: mutation = null)
mutants_survived: 0 # of 3 deliberate mutants
suite: 1072 passed, 2 skipped, 0 failed, 81s (`dart test`)
---

# TDD Verification: Planner/TODO System

**Verdict: FAIL.** `tasks.md:2` ticks "T1 Write the planner test suite first (TDD
red)" but no red exists anywhere: the cycle log holds only a baseline, and the
entire feature — 10 source files plus its 376-line test file — landed in a single
commit, `0f0145e`. The test suite itself is unusually strong (all three deliberate
mutants were caught, the value-object semantics are pinned tightly), which makes
the false test-first claim the decisive finding rather than a weak safety net.

## Test-first evidence

`specs/014-planner-todo-system/tdd/cycle-log.md` contains **only** the Baseline
entry (`fce207d`, 909 passed). `test-list.md:14-16` states the position honestly:
"the feature is already implemented and merged; this is a **test-after** plan …
No `RED` cycles were driven because the implementation preceded the list."
`tasks.md:2` contradicts that. Git agrees with the test list:

- `0f0145e` — `feat(planner): hand-curate Planner/TODO system + clean-arch layers (spec 014)` — 13 files, 991 insertions, 0 deletions: all seven `lib/src/domain/entities/planner/*.dart` files, the repository, the service, the provider, `plan.md`, `tasks.md`, **and** the complete `test/data/providers/planner/planner_provider_test.dart` (376 lines) in one commit.
- `git log -- lib/src/domain/entities/planner/` and `git log -- test/data/providers/planner/planner_provider_test.dart` each return exactly that one commit. There is no earlier test-only commit and no later source commit.

A single commit carrying a source file and its test is normal for a per-cycle loop
and would be `PROVEN` *if the cycle log had the red for it* (rubric, "Test-first
evidence"). It does not, so every behavior fails closed:

| Behavior | Class      | Evidence                                                                                                      |
| -------- | ---------- | ------------------------------------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | No red recorded; test and `step_status.dart` both first appear in `0f0145e`                                    |
| U2       | TEST_AFTER | No red recorded; test and `plan_step.dart` both first appear in `0f0145e`                                      |
| U3       | TEST_AFTER | No red recorded; test and `plan_state.dart` both first appear in `0f0145e`                                     |
| U4       | TEST_AFTER | No red recorded; test and `plan_mode.dart` both first appear in `0f0145e`                                      |
| U5       | TEST_AFTER | No red recorded; test and `plan_changed_event.dart` both first appear in `0f0145e`                             |
| U6       | TEST_AFTER | No red recorded; test and `write_todos_tool.dart` / `planner.dart` both first appear in `0f0145e`              |
| U7       | TEST_AFTER | No red recorded; test and `plan_state.dart` both first appear in `0f0145e`                                     |
| U8       | TEST_AFTER | No red recorded; test, `plan_state_repository.dart`, `planner_service.dart`, `planner_provider.dart` in `0f0145e` |

No pre-existing test was weakened, loosened, renamed, or skipped: `0f0145e` is a
pure-addition commit (991 insertions, 0 deletions) and touches no other test file.

## Findings

| #   | Severity | Finding                                                                                                                                                                                                                                                                                                                                                                                    | Evidence                                                              |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| 1   | HIGH     | **`tasks.md` claims a red that never happened.** `- [x] T1 Write the planner test suite first (TDD red)` is ticked, but the cycle log records no cycle and `0f0145e` shipped tests and source together. Either the tick or the claim must go; the honest record is the one already in `test-list.md:14-16`.                                                                                       | `specs/014-planner-todo-system/tasks.md:2`; `tdd/cycle-log.md:1-10`   |
| 2   | HIGH     | **Assertion-free test.** `'PlanStateRepository is usable as a type bound'` calls a no-op generic function and then asserts `expect(true, isTrue)`. It cannot fail for any reason related to `PlanStateRepository`; it is a compile-time check dressed as a test. Either delete it (the type bound is already enforced by `dart analyze --fatal-infos`) or replace it with a real fake implementation asserting `getCurrent`/`update`/`reset` round-trip a snapshot. | `test/data/providers/planner/planner_provider_test.dart:370-374`      |
| 3   | HIGH     | **All 8 behaviors are `TEST_AFTER`.** Under the rubric this alone is a `FAIL`. It cannot be repaired retroactively; it can only be recorded and the strength of the tests demonstrated by other means (see Mutation results).                                                                                                                                                                    | `test-list.md:14`; `tdd/cycle-log.md:1-10`                            |
| 4   | HIGH     | **US1-AC1 and US2-AC2 are covered only flag-deep.** US1-AC1 is "**When** the model calls `write_todos`, **Then** the plan state is updated" — nothing invokes the tool; only its `AgentTool` *declaration* is asserted (`:248-257`), and the tool's execution semantics are declared out of scope (`test-list.md:54`). US2-AC2 is "**When** the mission starts, **Then** planning is required before execution" — the only assertion is that the enum getter `requiresPlanningBeforeExecution` returns `true` (`:243`, `:288`); no engine, loop, or caller ever consults it, so nothing verifies planning is actually *required*. Both criteria are therefore unverified requirements, not covered ones. | `planner_provider_test.dart:243,248,285-290`; `spec.md:23,37`         |
| 5   | MED      | **Framework/type-system under test.** Three of the five "Clean-architecture layers" tests assert language facts rather than feature behavior: `isA<PlannerService>()` (`:346-348`), the identity of an identity function (`:364-368`), and the type bound above. The two `UnimplementedError` tests (`:350-362`) do pin real (stub) behavior.                                                    | `planner_provider_test.dart:345-375`                                  |
| 6   | MED      | **Test file location does not mirror `lib/src`.** The profile records the convention "tests … mirroring `lib/src` structure". Seven of the eight behaviors are `lib/src/domain/entities/planner/*` value objects, but all of them live in `test/data/providers/planner/planner_provider_test.dart`. The expected home is `test/domain/entities/planner/`, with only U8 under `test/data/providers/planner/`. | `test/data/providers/planner/planner_provider_test.dart:1`; `.specify/memory/tdd-profile.md:37-39` |
| 7   | MED      | **One 376-line file for eight behaviors, keyed only by group name.** The test-list `test` column addresses behaviors as `planner_provider_test.dart::<group> / <test>`, but the profile's red command is `dart test {file} -n "{name}"`, and several group/test name fragments (e.g. `PlanState`) select many tests at once. Splitting per source file would make single-behavior selection exact. | `test-list.md:31-43`                                                  |
| 8   | MED      | **`PlanChangedEvent` (FR-005) is never emitted by anything.** U5 constructs the event by hand and asserts its fields. No producer exists in `lib/`, so "Plan changes MUST emit PlanChangedEvent" is verified as a data class, not as an emission. `test-list.md:52-53` acknowledges the wiring belongs to spec 045.                                                                             | `planner_provider_test.dart:293-343`; `spec.md:59`                    |
| 9   | LOW      | **Repeated `DateTime.utc(2026, 8, 27, 12, 0, 0)` literal** across three tests with no named constant, and `1e-9` tolerances inline. Deterministic (no real clock — good), but the values are unexplained.                                                                                                                                                                                    | `planner_provider_test.dart:298,304,313,321,329,117,208`              |

Suite properties: the tests are isolated (fresh `threeTodos()` per test via a local
factory at `:44`), deterministic (no clock, random, network, sleep, or shared
state), fast (54 tests across the five audited files in ~2s), and behavior-named.
Failure specificity is good except in the eager cases noted in finding #7.

## Mutation results

No mutation tool in this repository (`.specify/memory/tdd-profile.md`:
`mutation: null`), so deliberate mutants were used. **2 of 8 behaviors sampled**
(U3 — SC-001 count accuracy; U7 — SC-003 five-turn persistence), chosen because
they are the two the measurable success criteria depend on. Each mutant was applied
to `lib/src/domain/entities/planner/plan_state.dart`, the full behavior file run,
then the source restored from a pristine copy and verified with `git diff --quiet`;
the audited files were re-run green (54 passed) and the full suite re-run green
(1072 passed, 2 skipped).

| Mutant                                                                                                                       | Behavior | Survived | Judgment                                                                                                          |
| ---------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| M1 `plan_state.dart:71` — `completedCount / steps.length` → `(completedCount + cancelledCount) / steps.length`                | U3       | No       | Caught: `Expected: <0.0> Actual: <0.3333333333333333>` (`:135`). Cancelled-is-not-progress is genuinely pinned.    |
| M2 `plan_state.dart:76` — drop the `steps.isNotEmpty &&` guard from `isComplete`                                              | U3       | No       | Caught: `Expected: false Actual: <true>` (`:124`). The empty-plan boundary is pinned.                              |
| M3 `plan_state.dart:128` — `s.copyWith(status: status)` → `s.copyWith(status: StepStatus.completed)` (markStep ignores the requested status) | U7, U3, U5 | No       | Caught by 3 tests at once (`Expected: <1> Actual: <0>`, `<2>`/`<3>`, `<-1>`/`<0>`). Status threading is pinned.     |

No survivors. U1, U2, U4, U5, U6, U8 were **not** sampled.

## Traceability

| Criterion | Behaviors        | Tests                                                                                       | End to end |
| --------- | ---------------- | ------------------------------------------------------------------------------------------- | ---------- |
| US1-AC1 (model calls `write_todos` → plan state updated) | U1, U2 | `planner_provider_test.dart:55,63,72,79,89` | **No** — declaration only, tool never invoked (finding #4) |
| US1-AC2 (query plan → accurate counts) | U3 | `planner_provider_test.dart:102,113,120,127,138,149,164,173,179` | Yes — real `PlanState`, no doubles |
| US2-AC1 (planMode=auto → tools available but optional) | U4, U6 | `planner_provider_test.dart:224,231,236,270,281` | Yes — real `Planner.toolsForInjection()` |
| US2-AC2 (planMode=must → planning required before execution) | U4, U6 | `planner_provider_test.dart:241,285` | **No** — asserts the enum flag, no enforcement point exists (finding #4) |
| US3-AC1 (plan updated at turn 3 survives to turn 5) | U7 | `planner_provider_test.dart:190,213` | Yes — value threading, as `plan.md` designs it |
| FR-002 (status set) | U1, U2 | `planner_provider_test.dart:55,63,72` | Yes |
| FR-005 (plan changes emit `PlanChangedEvent`) | U5 | `planner_provider_test.dart:294,307,328` | **No** — no emitter exists (finding #8) |
| `plan.md` Phase 1 clean-arch layers | U8 | `planner_provider_test.dart:346,350,357,364,370` | Partial — 2 of 5 assert behavior (finding #5) |

Untested criteria: US1-AC1 and US2-AC2 have no test that exercises the stated
trigger; FR-005 has no test of the emission. Tests tracing to nothing:
`'PlanStateRepository is usable as a type bound'` (`:370`) and
`'PlannerService is usable as a type bound'` (`:364`) assert no requirement in
`spec.md` or `plan.md`.

`tasks.md` cross-check: `[U1]`–`[U8]` are ticked `[x]` and all eight are `DONE` in
`test-list.md`, so no ticked behavior task points at a non-`DONE` behavior. The
violation is `T1` (finding #1), a process task whose claim the evidence contradicts.

## What was not audited

- **Coverage was not collected** for `lib/src/domain/entities/planner/*`, so uncovered-branch corroboration is absent.
- **Six of eight behaviors were not mutation-sampled** (U1, U2, U4, U5, U6, U8). This report is not an exhaustive strength measurement.
- **`write_todos` runtime execution** is out of scope per `test-list.md:54` (spec 002 engine loop owns it) and was not assessed beyond confirming no test exists.
- **`PlanChangedEvent` wiring into the sealed `EngineEvent` union** is out of scope per `test-list.md:52` (spec 045) and was not assessed.
- **`PlanStateRepository` has no implementation** anywhere in `lib/` — only the abstract interface ships. Persistence (FR-004) is therefore verified as value threading only, never as storage.
- **`WriteTodosTool` JSON-Schema validity** beyond `paramsSchema!['required']` containing `'todos'`; the schema's shape was not validated against any JSON-Schema validator.
- **Performance / large-plan behavior**: no criterion, no test, not assessed.
