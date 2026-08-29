# Tasks: Eval Harness — Golden Missions, Record/Replay, pass@k (spec 006)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US5). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance test drives the harness entry points yet (existing tests
> are entity-level only). Implementation and inner-loop unit tasks are **deferred**
> until `plan.md` exists (this spec has no `plan.md`; `/speckit.tdd.plan` should be
> re-run then).

## Acceptance (outer loop)

- [ ] [A1] A recorded cassette replayed consumes recordings instead of live calls with identical event order.
- [ ] [A2] A replay whose inputs drift from the recording reports a mismatch loudly — never silently passes.
- [ ] [A3] A suite with k samples/known pass counts scores pass@k matching the analytic value.
- [ ] [A4] A release gate of pass@k ≥ threshold fails CI with a per-task breakdown when a suite scores below.
- [ ] [A5] A task with an exact grader decides by byte-equality.
- [ ] [A6] A task with a schema grader decides by JSON-Schema validity.
- [ ] [A7] A model-judge grader (recorded judge) decides by parsed verdict; the judge call replays deterministically.
- [ ] [A8] GM-1..GM-5 defined as harness suites run in CI and report/gate correctly.
- [ ] [A9] The eval runtime package scanned has no `dart:io` imports (CLI/loader layers exempt).

## Phase 2: TDD remediation

> The feature is **not done** until the following are cleared. These cover the 5 HIGH
> findings from `tdd/verification.md` (A2, A5, A6, A7, A9 have no test exercising the real
> entry point — and the execution logic is not implemented in `lib`). Each finding's
> `traces` in `tdd/test-list.md` points at an entity/clean-arch test that does not exercise
> the acceptance behavior.

- [ ] [F1] (verification F1 — A2) Add an acceptance test that drives a replay whose inputs
  drift from the recording and asserts a loud mismatch (a `ReplayDiff` with `driftDetected`
  and a diff summary) rather than a silent pass. Proof: `dart test <new test>` fails red
  (no detection today), then passes green once replay-drift detection is implemented.
  - file:line: `test/data/providers/replay_diff/replay_diff_provider_test.dart:11-40`
    (entity-only; `lib/src/domain/services/replay_diff_service.dart` has no detection method)

- [ ] [F2] (verification F2 — A5) Add an acceptance test that runs an exact grader against a
  task output and asserts it decides by byte-equality (matching hash → pass, differing bytes
  → fail). Proof: `dart test <new test>` fails red (no `grade()` today), then passes green
  once the exact grader is implemented and asserted.
  - file:line: `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`
    (entity-only; `GraderSealed` has no `grade()` method; no grader-execution test in `test/**`)

- [ ] [F3] (verification F3 — A6) Add an acceptance test that runs a schema grader against a
  task output and asserts it decides by JSON-Schema validity. Proof: `dart test <new test>`
  fails red (no schema grader today), then passes green once implemented and asserted.
  - file:line: `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`
    (entity-only; no schema-grader execution test in `test/**`)

- [ ] [F4] (verification F4 — A7) Add an acceptance test that runs a recorded model-judge
  grader and asserts it decides by the parsed verdict, with the judge call replaying
  deterministically from the recording. Proof: `dart test <new test>` fails red (no judge
  grader today), then passes green once implemented and asserted.
  - file:line: `test/data/providers/grader_sealed/grader_sealed_provider_test.dart:11-45`
    (entity-only; no judge-grader execution test in `test/**`)

- [ ] [F5] (verification F5 — A9) Add an acceptance test that scans the eval runtime package
  and asserts `violationCount` is 0 (or lists the violating files) for a package with no
  `dart:io` imports, and non-zero when a `dart:io` import is present. Proof:
  `dart test <new test>` fails red (no scan today), then passes green once the `dart:io`-free
  gate scanning is implemented and asserted.
  - file:line: `test/data/providers/dart_io_free_gate/dart_io_free_gate_provider_test.dart:11-45`
    (entity-only; `lib/src/domain/services/dart_io_free_gate_service.dart` has no scan method)
