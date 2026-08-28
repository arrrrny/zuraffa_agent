# Implementation Plan: SubAgentSpec value object

**Branch**: `036-sub-agent-spec` | **Date**: 2026-08-27 | **Spec**: `specs/036-sub-agent-spec/spec.md`

**Input**: Feature specification from `/specs/036-sub-agent-spec/spec.md` (refined 2026-08-27).

**Note**: Hand-curated original plan (2026-08-24) delivered the ten-field aggregate; this refinement adds the Technical Context and the validation slice the task spec mandates.

## Summary

Add construction-time validation to the existing `SubAgentSpec` value object (FR-001..004) and pin the already-shipped structural getters and equality with tests. No new files: the aggregate, service, and provider exist; the deliverable is the validated aggregate plus its test coverage. Pattern mirrors spec 031 (ToolResult): the value object's public API is the entry point, the clean-arch layers stay pinned stubs.

## Technical Context

**Language/Version**: Dart SDK ^3.8.0 (pure Dart package, no Flutter SDK — constitution VII).

**Primary Dependencies**: `zuraffa` (git, ecosystem core — supplies `NoParams`, `Loggable`, `FailureHandler`), `zorphy`/`zorphy_annotation` (model layer for pipeline-generated entities; NOT used by this hand-curated value object), `test` + `mocktail` (dev).

**Storage**: N/A (pure value object; provider stays an UnimplementedError stub per FR-007).

**Testing**: `package:test` via `dart test`; suite baseline 695 passed / 0 failed at `7da6902`; ~36s wall. Single test: `dart test {file} --plain-name "{name}"` (verified, see `.specify/memory/tdd-profile.md`).

**Target Platform**: Dart VM (engine package consumed by ecosystem apps).

**Project Type**: library (agent engine).

**Performance Goals**: Construction-time validation must be O(1) per field (no allowlist deep scans beyond an emptiness pass over ids — lists are spec-sized, ≤ dozens).

**Constraints**: Runtime paths `dart:io`-free (constitution VII); `dart analyze` zero NEW findings vs the 5-issue baseline (constitution X); no codegen introduced.

**Scale/Scope**: One entity file touched (`sub_agent_spec.dart`), one test file extended (`sub_agent_spec_provider_test.dart` + new entity test file under `test/domain/entities/sub_agent_spec/`).

## Constitution Check

- **I. CLI-Built Only** — PASS: this feature flows through the speckit pipeline (`specify init` done, speckit skills driving artifacts); the hand-curated header lineage (PR #49–#55 precedent) is the recorded exemption for this file family.
- **II. Stop on First Misfire** — PASS: every gate below halts on failure.
- **V. Gates Are Non-Negotiable** — PASS: SC-004 gates the feature.
- **VII. Engine Purity** — PASS: no Flutter, no dart:io imports added.
- **IX. Zorphy Is the Model Layer** — PASS-with-precedent: file carries the HAND-CURATED header exempting the established value-object family from codegen; no new model classes outside Zorphy are created.
- **X. Post-Build Analysis Must Be Pristine** — PASS: zero new analyzer findings required.

## Project Structure

### Documentation (this feature)

```text
specs/036-sub-agent-spec/
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
lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart   # +validation (FR-001..004)
lib/src/domain/services/sub_agent_spec_service.dart          # unchanged (FR-007)
lib/src/data/providers/sub_agent_spec/sub_agent_spec_provider.dart  # unchanged (FR-007)
test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart # NEW: validation + semantics suite
test/data/providers/sub_agent_spec/sub_agent_spec_provider_test.dart  # unchanged (pinned, 11 tests)
```

## Phase 1 — Design

- **Validation placement**: constructor initializer + body asserts are unavailable to const constructors for argument checks; the constructor becomes non-const (mirrors `UiTreePayload`, which is already non-const) and validates in an initializer-list-friendly way: empty-string checks on `name`/`description`/`systemPrompt` (FR-001), blank-id scan on `tools`/`subAgents` (FR-002), budget checks (FR-003), and `extendsSpec == name` (FR-004), each throwing `ArgumentError.value(field, name, reason)`.
- **Const-ness impact**: dropping `const` from the constructor breaks nobody today (all existing call sites construct at runtime; `dart analyze` proves it), and the existing equality tests construct with `const []` default lists which remain const-evaluable. The provider tests construct normally.
- **Behavior compatibility**: all 11 existing tests construct valid specs → stay green (SC-003).
- **Test placement**: new entity suite at `test/domain/entities/sub_agent_spec/sub_agent_spec_test.dart` mirroring the 031 exemplar (`test/domain/entities/tool_result/tool_result_test.dart`); the provider suite stays untouched as the clean-arch pin.

## Phase 2 — Tasks

See `tasks.md` (dependency-ordered; test tasks precede implementation tasks per `/speckit.tdd.plan`).
