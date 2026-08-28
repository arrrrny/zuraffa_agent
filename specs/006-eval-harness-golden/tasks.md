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
