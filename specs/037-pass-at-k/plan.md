# Implementation Plan: PassAtK unbiased estimator

**Branch**: `037-pass-at-k` | **Date**: 2026-08-27 | **Spec**: `specs/037-pass-at-k/spec.md`

**Input**: Feature specification from `/specs/037-pass-at-k/spec.md` (refined 2026-08-27).

**Note**: Hand-curated original plan (2026-08-24) delivered the estimator triple; this refinement adds the Technical Context and the eval-run + threshold slice the task spec mandates.

## Summary

Extend the existing `PassAtK` value object with the two surfaces the harness consumes: `fromResults` (outcome-list entry point with explicit without-replacement sampling semantics) and `meetsThreshold` (inclusive threshold decision), plus the k-monotonicity invariant pin. No new files — the entity, service, and provider exist; the deliverable is the extended, tested metric.

## Technical Context

**Language/Version**: Dart SDK ^3.8.0 (pure Dart package, no Flutter SDK — constitution VII).

**Primary Dependencies**: `zuraffa` (git — `NoParams`, `Loggable`, `FailureHandler`), `test` + `mocktail` (dev). No new dependencies.

**Storage**: N/A (pure deterministic metric; provider stays an UnimplementedError stub per FR-005).

**Testing**: `package:test` via `dart test`; baseline at feature start: 709 passed / 0 failed (post-spec-036); single test: `dart test {file} --plain-name "{name}"` (verified, `.specify/memory/tdd-profile.md`).

**Target Platform**: Dart VM (engine package).

**Project Type**: library (agent engine).

**Performance Goals**: `fromResults` is O(n) counting + the estimator's O(k) product; trivial at eval scale (n <= thousands). No change to `compute`'s hot path.

**Constraints**: Runtime paths `dart:io`-free; `dart analyze` zero NEW findings vs the 5-issue baseline; no codegen.

**Scale/Scope**: One entity file extended (`pass_at_k.dart`), one new test file (`test/domain/entities/pass_at_k/pass_at_k_test.dart`); provider suite untouched.

## Constitution Check

- **I. CLI-Built Only** — PASS: speckit pipeline drives the artifacts; hand-curated header lineage (PR #49–#55) is the recorded exemption for this file family.
- **V. Gates Are Non-Negotiable** — PASS: SC-005 gates the feature.
- **VII. Engine Purity** — PASS: no new imports at all.
- **IX. Zorphy Is the Model Layer** — PASS-with-precedent: HAND-CURATED header retained; no new model classes outside the established value-object family.
- **X. Post-Build Analysis Must Be Pristine** — PASS: zero new analyzer findings required.

## Project Structure

### Documentation (this feature)

```text
specs/037-pass-at-k/
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
lib/src/domain/entities/pass_at_k/pass_at_k.dart        # +fromResults (FR-001), +meetsThreshold (FR-002)
lib/src/domain/services/pass_at_k_service.dart           # unchanged (FR-005)
lib/src/data/providers/pass_at_k/pass_at_k_provider.dart # unchanged (FR-005)
test/domain/entities/pass_at_k/pass_at_k_test.dart       # NEW: eval-run + threshold + invariant suite
test/data/providers/pass_at_k/pass_at_k_provider_test.dart # unchanged (pinned, 13 tests)
```

## Phase 1 — Design

- **fromResults**: `static PassAtK fromResults(List<bool> outcomes, {required int k})` — validate `outcomes.isNotEmpty` first (empty → ArgumentError naming outcomes), count c, delegate to `compute` (which owns n/c/k validation — single source of truth; its ArgumentError for k range is reused, so no duplicated bound logic).
- **meetsThreshold**: instance method; validate `threshold` in `[0, 1]` and not NaN (ArgumentError naming threshold), return `value >= threshold`. Inclusive by `>=` — boundary test pins it.
- **k-monotonicity pin**: sweep test over `compute(n: 20, c: 4, k: 1..16)` asserting non-decreasing values — characterization of shipped behavior (pass-first + deliberate mutant).
- **Dart language note**: both new members are absent today, so the first red is a compile error (`Member not found`); per the playbook the minimal stub is added, and the recorded red is the stub's `UnimplementedError` signal driven by the test.

## Phase 2 — Tasks

See `tasks.md` (dependency-ordered; test tasks precede implementation tasks per `/speckit.tdd.plan`).
