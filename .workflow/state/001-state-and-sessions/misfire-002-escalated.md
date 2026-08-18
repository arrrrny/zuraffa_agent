# ZFA Misfire #002 — generated code does not analyze clean + implement-agent contamination (189 issues)

**Date**: 2026-08-18 · **Stage**: implement (Phase 2→3) · **Constitution**: I, II, IV (and X, ratified this session)

## Command run (detection)

```bash
dart analyze   # after the implement agent's zfa build cycle (12 entities generated)
```

## Expected

- Zorphy-generated `.zorphy.dart` files compile cleanly (Article X: pristine).
- Implement agent produces ONLY zfa-generated surfaces + glue inside extension points.

## What happened — 189 issues, two root causes

### Root cause A — FRAMEWORK: zorphy generator emits non-compiling code
Generated files contain hard compile errors, e.g.:

```
error - lib/src/domain/entities/artifact_ref/artifact_ref.zorphy.dart:44:13 -
  The argument type 'dynamic' can't be assigned to the parameter type 'String'.
error - .../artifact_ref.zorphy.dart:94:12 -
  A value of type 'dynamic' can't be returned from 'toJsonLean' (returns Map<String,dynamic>).
```

Pattern: `argument_type_not_assignable` (dynamic→String/DateTime/int) and
`return_of_invalid_type` in fromJson/toJsonLean paths across at least:
artifact_ref, branch_summary_entry, compaction_entry, turn_record,
usage_ledger_entry, tool_invocation_record, model_change_entry, custom_entry,
thinking_level_change_entry, label_entry (~60 issues inside GENERATED code).

### Root cause B — PROCESS: implement agent contaminated by the manual-run lineage
- Hand-wrote `lib/zuraffa_agent.dart` barrel importing `src/compaction.dart`,
  `src/execution_env.dart`, `src/hive_adapters.dart`, … — the MANUAL branch's
  file layout; those files do not exist in the zfa-only tree (12 uri_does_not_exist).
- Hand-wrote `test/compaction_test.dart` (98 issues) referencing
  `AgentSession`/`compact`/`shouldCompact`/`HeuristicSummarizer` — APIs from
  the manual implementation that zfa generation has not (and may not) produce.
- Source of contamination: `specs/001-state-and-sessions/plan.md` (restored
  from the manual run's commit) documents the manual API surface; the agent
  treated it as the target surface instead of the Zorphy-entity surface.

## Fix

- A (upstream, blocking): zorphy_generator must emit properly typed fromJson
  assignments / toJsonLean returns (casts or typed locals). Filed on
  arrrrny/zorphy. No local hand-patching of generated files (constitution I/III).
- B (process, this repo): regenerate plan.md artifacts for the zfa-only run so
  they describe the GENERATED surface, not the manual API; delete the
  contaminated barrel + test; harden the implement prompt: tests and barrels
  are generated or written against generated symbols only.

## Prevention

- Article X (constitution v1.2.0): dart analyze after EVERY zfa build;
  pristine or halt. Encode as a driver gate once no driver is running.
- plan.md must be (re)generated under the zfa-only mandate so agents aren't
  steered by the previous manual implementation's API names.
- Implement prompt: forbid importing/creating files named after the manual
  run's layout (src/session.dart, src/compaction.dart, ...) — those belong to
  reference/001-manual-port only.

## Evidence

- Full analyzer output: 189 issues (98 test/compaction_test.dart, 12 barrel,
  ~60 in generated .zorphy.dart, rest types.dart/hand-written).
- Driver killed at implement (PID 47827) per constitution II.
