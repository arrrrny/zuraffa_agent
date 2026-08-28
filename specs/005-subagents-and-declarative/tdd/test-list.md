---
feature: 005-subagents-and-declarative
loop: outside-in # sub-agent dispatch + declarative specs are a user-visible surface (parent agent, operator, model)
profile: .specify/memory/tdd-profile.md
spec_criteria: 8 # numbered Acceptance Scenarios across 4 user stories in spec.md (no global AC ids; traced to FR-xxx)
planned_at: fce207d
updated_at: fce207d
suite_baseline: green # 909 passed, 2 skipped
---

# Test List: Sub-agents & Declarative Agent Specs (spec 005)

> Derived from `spec.md` (User Scenarios & Testing → Acceptance Scenarios, and
> FR-001..FR-005) on `master` @ `fce207d`. **OUTER-ONLY**: `plan.md` is absent, so
> only the outer-loop acceptance behaviors are derived here; the inner loop is
> deferred (see below). No acceptance/integration test exercises these spec
> criteria through the dispatch / spec-loading entry points yet, so every A
> behavior is `PENDING`.

## Outer loop: acceptance behaviors

One per numbered Acceptance Scenario in `spec.md`. Each stays `PENDING` until
sub-agent dispatch and declarative spec loading are driven end to end and asserted.

| id  | behavior                                                                                                  | traces | kind    | state   | test |
| --- | -------------------------------------------------------------------------------------------------------- | ------ | ------- | ------- | ---- |
| A1  | A registered sub-agent type dispatched runs with its own session, allowlist, and budget (spec 002 tree)    | FR-001 | example | PENDING |      |
| A2  | A completed sub-agent returns only its result summary to the parent context                                | FR-005 | example | PENDING |      |
| A3  | A failing sub-agent returns a typed failure result to the parent, which continues                          | FR-001 | example | PENDING |      |
| A4  | A persisted sub-agent instance id resumes its session tree from the stored leaf                            | FR-002 | example | PENDING |      |
| A5  | Spec B `extends` spec A: B inherits unspecified fields and overrides specified ones                         | FR-003 | example | PENDING |      |
| A6  | A spec referencing an unknown tool or with cyclic inheritance fails validation with a precise error         | FR-003 | example | PENDING |      |
| A7  | A country playbook YAML loaded as a spec changes agent behavior with no code change                         | FR-003 | example | PENDING |      |
| A8  | A dispatch-tool call with type + task creates/resumes the instance and awaits its result                    | FR-004 | example | PENDING |      |

## Inner loop: deferred — plan.md absent

`plan.md` does not exist for this feature, so the inner-loop unit behaviors (per
component) cannot be derived. `/speckit.tdd.plan` must be re-run once `plan.md`
exists to populate the `U1..` table (sub-agent type/instance, context isolation,
YAML spec loader/resolver, dispatch tool lifecycle). This list records only the
outer-loop acceptance behaviors.

## Edge cases & invariants (from spec.md)

Carried from the spec's Edge Cases; not yet placed as numbered behaviors:

- Sub-agent dispatch from within a sub-agent → allowed, depth-capped; cycle-free by construction (new instance ids).
- Spec file hot-reload → validated before swap; running missions keep their resolved spec.
- Budget exhaustion inside a sub-agent → typed budget outcome returned to parent (no hang).
- Parallel dispatch of N sub-agents → results collected in dispatch order.

## Shipped unit/provider coverage (inner-loop, NOT outer acceptance — reported, not followed)

The repo already ships inner-loop unit/provider tests for several building blocks
of this feature. These are **not** outer-loop acceptance tests and are explicitly
deferred by this outside-in plan; listed here for accuracy only:

- `test/domain/entities/sub_agent_type_test.dart`, `test/domain/entities/agent_spec_test.dart` — entity construction.
- `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart`, `test/data/providers/sub_agent_spec/*`, `test/data/providers/yaml_agent_spec/*` — spec model & YAML loader.
- `test/data/providers/sub_agent_context/*`, `test/data/providers/sub_agent_instance/*` — isolated context & instance persistence.
- `test/data/providers/dispatch_tool/dispatch_tool_provider_test.dart` — built-in dispatch tool.

## Out of scope

- Inner-loop unit behaviors: deferred until `plan.md` (see above).
- Playbook serving (`raptorr.playbook_get`): upstream; this spec defines the loading side only.
- Engine event emission on sub-agent lifecycle: owned by the engine loop (spec 002).

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}` (format with
  `dart run coverage:format_coverage --packages=.dart_tool/package_config.json --report-on=lib --in=.dart_coverage -l`)
- Mutation / property-based: **not available** in this repo (no `mutation_test` /
  `glados` in the lockfile).
