# Tasks: Sub-agents & Declarative Agent Specs (spec 005)

> Acceptance test tasks derived from `spec.md` Acceptance Scenarios (US1–US4). The
> `[A#]` markers match the outer-loop behaviors in `tdd/test-list.md`. Each is `PENDING`
> because no acceptance/integration test drives sub-agent dispatch / spec loading
> yet. Implementation and inner-loop unit tasks are **deferred** until `plan.md`
> exists (this spec has no `plan.md`; `/speckit.tdd.plan` should be re-run then).

## Acceptance (outer loop)

- [ ] [A1] A registered sub-agent type dispatched runs with its own session, allowlist, and budget (spec 002 tree).
- [X] [A2] A completed sub-agent returns only its result summary to the parent context. (test/domain/entities/sub_agent_instance/sub_agent_result_test.dart)
- [X] [A3] A failing sub-agent returns a typed failure result to the parent, which continues. (test/domain/entities/sub_agent_instance/sub_agent_result_test.dart)
- [ ] [A4] A persisted sub-agent instance id resumes its session tree from the stored leaf.
- [ ] [A5] Spec B `extends` spec A: B inherits unspecified fields and overrides specified ones.
- [X] [A6] A spec referencing an unknown tool or with cyclic inheritance fails validation with a precise error. (test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart)
- [ ] [A7] A country playbook YAML loaded as a spec changes agent behavior with no code change.
- [ ] [A8] A dispatch-tool call with type + task creates/resumes the instance and awaits its result.

## Phase 2: TDD remediation

> The feature is **not done** until the following are cleared. These cover the 2 HIGH
> findings from `tdd/verification.md` (A5 and A7 have no test exercising the real entry
> point). Each finding's `traces` in `tdd/test-list.md` points at an entity/validation
> test that does not exercise the acceptance behavior.

- [ ] [F1] (verification F1 — A5) Add an acceptance test that builds spec A and spec B with
  `extendsSpecId: A`, asserts B inherits A's unspecified fields (e.g. systemPrompt,
  toolAllowlist) and overrides the fields B specifies, via the same resolution path a real
  load would use. Proof: `dart test <new test>` fails red (no resolution today), then passes
  green once `extends` resolution/merge is implemented and asserted.
  - file:line: `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart:63-95`
    (only validates the parent-chain; no merge test; `lib` has no resolve/merge impl)

- [ ] [F2] (verification F2 — A7) Add an acceptance test that loads a country-playbook YAML
  as a spec and asserts the resolved agent behavior (e.g. allowlist / system prompt / tools)
  reflects the YAML with no code change. Proof: `dart test <new test>` fails red (no loader
  test today), then passes green once declarative YAML loading is implemented and asserted.
  - file:line: `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`
    (entity/validation only; `grep loadYaml|fromYaml|playbook` across `lib`/`test` returns nothing)
