# Cycle Log: Sub-agents & Declarative Agent Specs (spec 005)

Append only. Newest last. This file currently holds only the Baseline entry; no
cycles have been driven yet because `plan.md` is absent and the outer-only TDD
plan is being recorded before any change.

## Baseline

- suite: `dart test` -> 909 passed, 2 skipped (0 failed)
- commit: `fce207d`
- recorded: cycle 0, before any change

## Cycle A6 — declarative spec validation (red -> green)

- test: `test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart` ::
  "spec 005 A6 - declarative spec validation diagnostics"
- RED: new group asserts (1) a spec referencing an unknown tool yields a precise
  error `unknown tool 'unknown_tool' referenced by spec 'id-x'`, and (2) cyclic
  inheritance (`a -> b -> a`) yields `cyclic inheritance in spec 'a': b -> a -> b`.
  Compile failure: `The method 'validate' isn't defined for the type 'YamlAgentSpec'`
  (no validate method existed) — valid red per the "symbol must exist" rule.
- GREEN: added a minimal `YamlAgentSpec.validate({required parentOf, required
  knownTools})` returning `List<String>` of precise diagnostics — unknown-tool,
  unknown-parent, and cycle detection (walk `extendsSpecId` chain). The entity
  doc already named "validation diagnostics" as in-scope (issue #6 §R5.3).
- Deliberate mutant: removed the `chain.contains(current)` guard -> cyclic case
  returned no error -> A6 cyclic test failed. Restored.
- No refactor needed.
- suite after: `dart test` -> 934 passed, 2 skipped (0 failed).

## Cycle A2/A3 — typed SubAgentResult (success summary + typed failure) (red -> green)

- test: `test/domain/entities/sub_agent_instance/sub_agent_result_test.dart` ::
  "spec 005 A2/A3 - SubAgentResult typed outcome"
- RED: new test asserts `SubAgentResult.success` carries a `summary` (ok) and
  `SubAgentResult.failure` is typed (`ok == false`, `failureKind` + `failureReason`).
  Compile failure with the entity hidden: `Undefined name 'SubAgentResult'` /
  `'SubAgentFailureKind'` — valid red (symbol must exist).
- GREEN: added `lib/src/domain/entities/sub_agent_instance/sub_agent_result.dart`
  — a plain-Dart value object (mirrors SubAgentInstance) with `SubAgentResult.success`
  and `SubAgentResult.failure` factories and a `SubAgentFailureKind` enum. The prior
  `SubAgentInstance.lastRunOutcome` was a raw String; this is the typed result the
  behaviors require.
- Deliberate mutant: changed `SubAgentResult.failure` to set `ok = true` -> A3 test
  failed (`ok` expected false). Restored; green.
- No refactor needed.
- suite after: `dart test` -> 939 passed, 2 skipped (0 failed).

## Cycle: A4 — resume a persisted sub-agent instance by id

- test: `test/data/datasources/sub_agent_instance/sub_agent_instance_store_test.dart`
  :: "A4: a persisted instance id resumes its session tree from the stored leaf"
- RED: `dart test test/data/datasources/sub_agent_instance/sub_agent_instance_store_test.dart`
  -> `Error: Method not found: 'SubAgentInstanceStore'.` — nothing persisted
  sub-agent instances; `SubAgentInstanceProvider` only held one in-memory snapshot.
- GREEN: added a hand-written `fromJson`/`toJson` pair to the `SubAgentInstance`
  value object and `lib/src/data/datasources/sub_agent_instance/sub_agent_instance_store.dart`
  (`save` / `resume` / `all`) backed by the allowlisted `JsonlEntityStorage`
  adapter, volatile in-memory when `path` is null. The restart is modelled by
  constructing a second store over the same JSONL path. Full suite green
  (942 passed, 2 skipped, 77s).
- Deliberate mutant: `'parentSessionId': parentSessionId` -> `'mutant'` in
  `toJson` -> A4 failed on the resumed leaf. Restored.
- No refactor needed: the store mirrors the existing remote-datasource shape
  (nullable path, storage-or-memory) rather than inventing a second pattern.
- commit: (this cycle)
