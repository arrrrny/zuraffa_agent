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
