# Tasks: Providers & Fallback Chain (spec 004)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US4). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance/integration test drives the provider/fallback entry points
> yet (the env-gated `test/integration/llm_client_proxy_test.dart` is a smoke test,
> not a criterion suite). Implementation and inner-loop unit tasks are **deferred**
> until `plan.md` exists (this spec has no `plan.md`; `/speckit.tdd.plan` should be
> re-run then).

## Acceptance (outer loop)

- [ ] [A1] Each provider client streams recorded fixtures identically: events, tool-call buffering, and usage fields.
- [X] [A2] With the engine pubspec resolved, `dart_agent_core` is absent and vendored files carry attribution headers. (test/integration/spec_004_a2_dart_agent_core_test.dart)
- [ ] [A3] Every completed LLM call has a `UsageLedger` entry with provider + model + token counts.
- [ ] [A4] Provider A failing is served transparently by B; the mission observes only latency.
- [ ] [A5] A in open state with cooldown elapsed: a half-open probe routes real traffic back on success.
- [ ] [A6] A mid-stream failure after partial chunks restarts on the next provider (or surfaces), never silently truncates.
- [ ] [A7] Any chain state, the `Map<provider, ClientHealth>` snapshot matches the internal breaker states.
