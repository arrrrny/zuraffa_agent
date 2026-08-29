---
feature: 063-replay_cli_surface
verdict: FAIL
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md
verified_at: 01618f3
behaviors: 6
proven: 0
likely: 0
test_after: 6
no_test: 0
high_smells: 0
criteria_total: 0
criteria_covered: 0
mutation_score: null # no high-risk path (spec_criteria: 0; no auth/secrets/persistence/money) — mutation scoped out per rubric
mutants_survived: null
suite: 6 passed, 0 failed (file `test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`)
---

# TDD Verification: ReplayCliSurface (spec 063)

**Verdict: FAIL.** All six behaviors are `TEST_AFTER`: the feature was
implemented and merged before the test list existed, no `cycle-log.md` red was
recorded, and the list states *"No RED cycles were driven because the
implementation preceded the list"*. The regression tests are reasonable but the
red-before-green discipline was not followed. (The spec name implies a CLI
surface, but the shipped artifact is a plain value object + provider stub with no
real CLI entry point — see Findings #3.)

## Test-first evidence

| Behavior | Class      | Evidence                                                                          |
| -------- | ---------- | --------------------------------------------------------------------------------- |
| U1       | TEST_AFTER | No red recorded; `test-list.md` declares the feature merged before the list.       |
| U2       | TEST_AFTER | No red recorded.                                                                  |
| U3       | TEST_AFTER | No red recorded. `isA` subtype check.                                             |
| U4       | TEST_AFTER | No red recorded. Default-snapshot assertion.                                      |
| U5       | TEST_AFTER | No red recorded. Injected-snapshot assertion.                                     |
| U6       | TEST_AFTER | No red recorded. `count() == 1` assertion.                                        |

`git log --follow` shows the test file landed in squashed commit `39dd392`
together with the source; per-cycle ordering is not visible and PROVEN cannot be
claimed; with no cycle-log red, all behaviors grade TEST_AFTER (fail-closed).

## Findings

| #   | Severity | Finding                                                                                                                                                | Evidence                                          |
| --- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| 1   | LOW      | `U3` (`ReplayCliSurfaceProvider is a ReplayCliSurfaceService`) is an `isA` subtype check — a compile-time guarantee, green by definition. Matches the house pattern. | `replay_cli_surface_provider_test.dart:27-30`      |
| 2   | LOW      | Spec/code drift (reported, not followed): `spec.md`/`plan.md` describe a `UnimplementedError` stub; the shipped `ReplayCliSurfaceProvider` returns a default snapshot and honors an injected value. Tests assert shipped behavior; spec text is stale. | `spec.md:11` vs `replay_cli_surface_provider.dart` |
| 3   | LOW      | Spec/name drift: the spec is named "replay CLI surface" and `spec.md` claims declarative replay invocation (mission id, recorded traffic, grader matrix), but the shipped code is only a 4-field value object — no CLI command, no dispatch. The test list records this as out-of-scope. | `spec.md:5-6` vs `replay_cli_surface.dart`         |

No `HIGH` smells. Value-equality (`U1`/`U2`) and default-snapshot (`U4`/`U5`)
assertions are non-vacuous by inspection. No weakened or skipped existing tests.

## Mutation results

No mutation run. Spec 063 has `spec_criteria: 0` and no auth/secrets/
persistence/money/acceptance-criterion path, so deliberate mutants were scoped
out per the rubric. The value and default-snapshot tests assert specific values
and are non-vacuous by inspection.

## Traceability

`spec.md` declares `spec_criteria: 0`; the feature advances epic #6 §R6.4
(issue #7 US4) with no numbered acceptance criteria. All 6 behaviors trace to
`R6.4` and each maps to a test that exists and runs (confirmed green: 6/0).
Untested requirements: the spec's named replay-invocation CLI behavior is
unimplemented (recorded out-of-scope). Tests tracing to nothing: none.

## What was not audited

- No mutation tool in this repo; deliberate mutants scoped out (no high-risk path).
- Full suite not re-run end to end; only the spec test file executed (green).
- Stale `UnimplementedError`-stub and CLI-surface descriptions in `spec.md` are
  noted as LOW findings, not remediated.
