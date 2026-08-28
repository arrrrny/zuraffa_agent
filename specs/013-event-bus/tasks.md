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
- [ ] [A2] Multiple subscribers each receive an event when it fires.
- [ ] [A3] A registered `BeforeToolCallRequest` handler's response is used when the event fires.
- [ ] [A4] An `AgentController.publish()` delivers the event to all listeners (identical to EventBus).
