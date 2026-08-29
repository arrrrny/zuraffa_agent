# Tasks: Event Bus (spec 013)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US3). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because the feature has **no shipped implementation or tests** yet (a repo-wide
> case-insensitive search for `EventBus` / `AgentController` in `lib/` and `test/`
> returned no matches). Implementation and inner-loop unit tasks are **deferred**
> until `plan.md` exists (this spec has no `plan.md`; `/speckit.tdd.plan` should be
> re-run then).

## Acceptance (outer loop)

- [x] [A1] A subscriber to `LLMChunkEvent` receives each chunk event as the model streams.
- [x] [A2] Multiple subscribers each receive an event when it fires.
- [x] [A3] A registered `BeforeToolCallRequest` handler's response is used when the event fires.
- [x] [A4] An `AgentController.publish()` delivers the event to all listeners (identical to EventBus).

## Phase 2: TDD remediation

Source: `tdd/verification.md` @ `01618f3` — **verdict FAIL**. This feature is **not
done** until T1 and T2 below are cleared. HIGH findings only; MED/LOW findings 3–6
are recorded in the report and not tracked here.

- [ ] T1 (finding #1, HIGH) Strengthen the A3 assertion at `test/events/event_bus_test.dart:33`: replace `expect(resp.approved, isTrue)` with an assertion on the handler's actual contribution — `expect(resp.args, {'url': 'x', 'approved': true})` — and add a second case whose handler returns `BeforeToolCallResponse(..., approved: false)` so the flag is not satisfied by its default. Prove it done: re-apply mutant M1 (`lib/src/events/event_bus.dart:60` → `handlers.last(BeforeToolCallRequest('', <String, Object>{}))`), confirm `dart test test/events/event_bus_test.dart -n "A3"` now **fails**, restore the source, and confirm `dart test test/events/event_bus_test.dart` is green.
- [ ] T2 (finding #2, HIGH) Correct the A2 test-first record: `specs/013-event-bus/tdd/cycle-log.md:22-32` presents a self-administered mutant as the red step for a test that passed on first run against source shipped in the previous commit. Re-label cycle 2 as characterization and set A2's class in `tdd/test-list.md` to match, or drive a genuine red for the registration-order guarantee (FR-003) with its own list item. Prove it done: `tdd/verification.md` re-run reports 0 `TEST_AFTER` behaviors for this feature, and `dart test test/events/event_bus_test.dart` is green.
