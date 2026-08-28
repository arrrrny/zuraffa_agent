# Tasks: Engine Core Loop (spec 002)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US5). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance/integration test drives the engine entry point yet.
> Implementation and inner-loop unit tasks are **deferred** until `plan.md` exists
> (this spec has no `plan.md`; `/speckit.tdd.plan` should be re-run then).

## Acceptance (outer loop)

- [ ] [A1] A mission with tools available dispatches each `tool_calls` result, appends results, and re-invokes the LLM until a non-tool finish reason.
- [ ] [A2] A scripted 200-call mission completes without state corruption or event loss.
- [ ] [A3] Identical inputs + a recorded LLM re-run 10× produce a byte-identical event stream (determinism).
- [ ] [A4] A provider streaming thinking deltas leaves the assistant message carrying thinking blocks next to tool calls at turn completion.
- [ ] [A5] In a multi-turn mission, prior turns' thinking blocks are present when turn N+1 context is assembled.
- [ ] [A6] An enqueued steering message is injected before the next LLM call during a running mission.
- [ ] [A7] Follow-up messages queued at mission end cause the loop to continue with them instead of exiting.
- [ ] [A8] With maxTurns=5 and a model that never stops, the mission ends with `MaxTurnsExceeded` after turn 5.
- [ ] [A9] Identical repeated tool calls hitting the threshold fire `LoopDetected` and abort the mission cleanly.
- [ ] [A10] During any mission, consumers receive events in order with monotonic turn/sequence identifiers.
