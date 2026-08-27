# Implementation Plan: AgentMessage (multimodal parts) + history

**Branch**: `041-agent_message` | **Date**: 2026-08-27 | **Spec**: `specs/041-agent_message/spec.md`

**Input**: Feature specification from `/specs/041-agent_message/spec.md` (refined 2026-08-27).

**Note**: Hand-curated original plan (2026-08-24) delivered the 3-field entity + service/provider stubs; this refinement adds the Technical Context and the semantics slice the task spec mandates (roles validation, parts value-equality fix, history truncate).

## Summary

Fix the shipped parts-equality bug in the domain `AgentMessage` (identity comparison → element-wise value comparison, hashCode folding parts content), add construction validation (non-empty id/role), and add `AgentMessageHistory.truncate` (last-N retention, memories untouched). Everything else — append, addMemory, the sealed hierarchy, the clean-arch stubs — is pinned, not changed.

## Technical Context

**Language/Version**: Dart SDK ^3.8.0 (pure Dart package, no Flutter SDK — constitution VII).

**Primary Dependencies**: `zuraffa` (git — `NoParams`, `Loggable`, `FailureHandler`), `test` + `mocktail` (dev). No new dependencies.

**Storage**: N/A (value objects; provider stays an UnimplementedError stub per FR-007).

**Testing**: `package:test` via `dart test`; baseline at feature start: 727 passed / 0 failed (post-spec-038); single test: `dart test {file} --plain-name "{name}"` (verified, `.specify/memory/tdd-profile.md`). Exemplars: `test/llm/agent_message_history_test.dart` (history), `test/domain/entities/*/` (entity suites).

**Target Platform**: Dart VM (engine package).

**Project Type**: library (agent engine).

**Performance Goals**: truncate is O(1) list slicing; equality O(parts) worst case — trivial at message scale.

**Constraints**: Runtime paths `dart:io`-free; `dart analyze` zero NEW findings vs the 5-issue baseline; no codegen; `lib/src/types.dart` byte-identical (FR-006).

**Scale/Scope**: Two files touched (`agent_message.dart` entity, `agent_message_history.dart`), two test files added (entity suite + history suite); provider suite, `types.dart`, and `types_test.dart` untouched.

## Constitution Check

- **I. CLI-Built Only** — PASS: speckit pipeline drives the artifacts; hand-curated header lineage is the recorded exemption for this file family.
- **V. Gates Are Non-Negotiable** — PASS: SC-005 gates the feature.
- **VII. Engine Purity** — PASS: no new imports.
- **VIII. Attributed Ports** — PASS: `agent_message_history.dart`'s dart_agent_core attribution header retained untouched.
- **IX. Zorphy Is the Model Layer** — PASS-with-precedent: HAND-CURATED headers retained; no new model classes outside the established value-object family.
- **X. Post-Build Analysis Must Be Pristine** — PASS: zero new analyzer findings required.

## Project Structure

### Documentation (this feature)

```text
specs/041-agent_message/
├── spec.md              # Refined 2026-08-27 (/speckit.specify)
├── plan.md              # This file (/speckit.plan refinement)
├── tasks.md             # /speckit.tasks dependency-ordered rewrite
└── tdd/
    ├── test-list.md     # /speckit.tdd.plan
    ├── cycle-log.md     # /speckit.tdd.run evidence (append-only)
    └── verification.md  # /speckit.tdd.verify audit
```

### Source Code (repository root)

```text
lib/src/domain/entities/agent_message/agent_message.dart  # +validation (FR-001), =equality fix (FR-002)
lib/src/llm/agent_message_history.dart                     # +truncate (FR-004); attribution header untouched
lib/src/types.dart                                         # BYTE-IDENTICAL (FR-006)
test/domain/entities/agent_message/agent_message_test.dart # NEW: validation + equality suite
test/llm/agent_message_history_041_test.dart               # NEW: truncate + append/addMemory pins
test/data/providers/agent_message/agent_message_provider_test.dart # unchanged (pinned, 5 tests)
test/types_test.dart                                       # unchanged (role/part coverage pinned)
```

## Phase 1 — Design

- **Entity validation + equality**: constructor drops `const` (no const call sites — analyzer-verified); body validates `id`/`role` non-empty (`ArgumentError.value`); `==` compares parts via a private `_partsEq` element-wise helper (same pattern as `SubAgentSpec._listEq`); `hashCode` becomes `Object.hash(id, role, Object.hashAll(parts))` so equal-content parts hash equally.
- **truncate**: `AgentMessageHistory truncate(int keep)` — `keep < 0` throws ArgumentError; `keep == 0` → `messages: const []`; otherwise `messages.sublist(messages.length - keep)`; `episodicMemories` passed through unchanged. Pure function; receiver untouched.
- **Pins**: appendMessages/addMemory covered by new tests in a NEW file (`test/llm/agent_message_history_041_test.dart`) so the spec-010 file stays byte-identical; sealed-hierarchy role coverage credited to `types_test.dart` as BASELINE.
- **Dart language note**: `truncate` is absent today → first red is a compile error; validation/equality reds are assertion failures (surface exists).

## Phase 2 — Tasks

See `tasks.md` (dependency-ordered; test tasks precede implementation tasks per `/speckit.tdd.plan`).
