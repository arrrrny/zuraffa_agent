# Tasks: Sub-agents & Declarative Agent Specs (spec 005)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US4). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance/integration test drives sub-agent dispatch / spec loading
> yet. Implementation and inner-loop unit tasks are **deferred** until `plan.md`
> exists (this spec has no `plan.md`; `/speckit.tdd.plan` should be re-run then).

## Acceptance (outer loop)

- [ ] [A1] A registered sub-agent type dispatched runs with its own session, allowlist, and budget (spec 002 tree).
- [ ] [A2] A completed sub-agent returns only its result summary to the parent context.
- [ ] [A3] A failing sub-agent returns a typed failure result to the parent, which continues.
- [ ] [A4] A persisted sub-agent instance id resumes its session tree from the stored leaf.
- [ ] [A5] Spec B `extends` spec A: B inherits unspecified fields and overrides specified ones.
- [X] [A6] A spec referencing an unknown tool or with cyclic inheritance fails validation with a precise error. (test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart)
- [ ] [A7] A country playbook YAML loaded as a spec changes agent behavior with no code change.
- [ ] [A8] A dispatch-tool call with type + task creates/resumes the instance and awaits its result.
