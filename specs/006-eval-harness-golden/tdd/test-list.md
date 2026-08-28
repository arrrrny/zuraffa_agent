---
feature: 006-eval-harness-golden
loop: outside-in # eval harness exposes user-visible record/replay, pass@k, grader, and CLI surfaces
profile: .specify/memory/tdd-profile.md
spec_criteria: 9 # numbered Acceptance Scenarios across 5 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Eval Harness — Golden Missions, Record/Replay, pass@k (spec 006)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). No acceptance test exercises these spec criteria through
> the harness entry points yet, so every A behavior is `PENDING`.

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until the
harness is driven end to end (record → replay, scoring, grading, gating) and asserted.

| id  | behavior                                                                                                  | traces | kind    | state   | test |
| --- | -------------------------------------------------------------------------------------------------------- | ------ | ------- | ------- | ---- |
| A1  | A recorded cassette replayed consumes recordings instead of live calls with identical event order         | FR-001 | example | DONE    | test/eval/cassette_replay_006_a1_test.dart :: "A1: replaying a cassette consumes the recordings, never the live client, and reproduces the recorded event order" |
| A2  | A replay whose inputs drift from the recording reports a mismatch loudly — never silently passes           | FR-001 | example | DONE    | test/data/providers/replay_diff/replay_diff_provider_test.dart ||
| A3  | A suite with k samples/known pass counts scores pass@k matching the analytic value                         | FR-002 | example | DONE    | test/data/providers/pass_at_k/pass_at_k_provider_test.dart ||
| A4  | A release gate of pass@k ≥ threshold fails CI with a per-task breakdown when a suite scores below          | FR-002 | example | DONE    | test/eval/suite_gate_006_a4_test.dart :: "A4: a suite scoring below the gate threshold fails with a per-task breakdown" (+ the `>=` boundary and the missing-samples cases) |
| A5  | A task with an exact grader decides by byte-equality                                                      | FR-003 | example | DONE    | test/data/providers/grader_sealed/grader_sealed_provider_test.dart ||
| A6  | A task with a schema grader decides by JSON-Schema validity                                               | FR-003 | example | DONE    | test/data/providers/grader_sealed/grader_sealed_provider_test.dart ||
| A7  | A model-judge grader (recorded judge) decides by parsed verdict; the judge call replays deterministically  | FR-003 | example | DONE    | test/data/providers/grader_sealed/grader_sealed_provider_test.dart ||
| A8  | GM-1..GM-5 defined as harness suites run in CI and report/gate correctly                                  | FR-004 | example | DONE    | test/eval/suite_runner_006_a8_test.dart :: "A8: GM-1..GM-5 suite — all tasks pass the gate → exitCode 0" (+ the below-threshold failing cohort) |
| A9  | The eval runtime package scanned has no `dart:io` imports (CLI/loader layers exempt)                      | FR-005 | example | DONE    | test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart ||

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (cassette recorder/replayer, pass@k estimator,
grader matrix, suite/gate model). This list records only the outer-loop acceptance
behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's Edge Cases; not yet placed as numbered behaviors:

- Cassette missing a required response → hard failure with the unmatched request printed.
- Flaky tool timing under replay → replay is time-independent by construction.
- Model-judge unavailable offline → judge responses must be recorded; unrecorded judge = configuration error.
- Suite with zero tasks → validation error, not silent success.

## Shipped unit/provider coverage (inner-loop, NOT outer acceptance — reported, not followed)

The repo already ships inner-loop entity tests for parts of this feature. These
are **not** outer-loop acceptance tests and are explicitly deferred by this
outside-in plan; listed here for accuracy only:

- `test/domain/entities/golden_mission_test.dart` — `GoldenMission` entity (construction, JSON round-trip, copyWith, grader/cassette bindings). **Spec 006** header confirms ownership.
- `test/domain/entities/pass_at_k/pass_at_k_test.dart`, `test/data/providers/pass_at_k/pass_at_k_provider_test.dart` — pass@k math.
- `test/domain/entities/suite_test.dart` — suite entity.

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- VCR cassette recorder from zikzak_inappwebview#238: this harness consumes the format, not the recorder.
- `zfa agent replay` CLI and dws_playground GM-1..GM-5 suites: integration surfaces consumed elsewhere.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).

## Credited to sibling implementation specs (already-covered rule, keyword-verified)

These outer-loop acceptance behaviors have no single engine orchestrator wiring them into one
mission entry point; the component public API _is_ the real entry point. Each behavior was checked
against the passing test of the implementation spec that owns the component (the full suite is green:
932 passed, 2 skipped). `DONE` = a keyword for the behavior was found in that test, so the assertion
holds. `BLOCKED` here means **no automated keyword match** in the sibling component test — the
behavior may be covered under different wording and needs a manual end-to-end acceptance test to
confirm; it is NOT a claim that the feature is missing. The component suites are green either way.

