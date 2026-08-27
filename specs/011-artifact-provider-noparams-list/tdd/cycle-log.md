# TDD Cycle Log: ArtifactProvider.list NoParams override fix

---
feature: 011-artifact-provider-noparams-list
profile: .specify/memory/tdd-profile.md
started_at: 37399f5 (master) + a1fb738 (pubspec unblock)
---

## Cycle context (honest)

The hand-curated `ArtifactService`/`ArtifactProvider` pair and the contract
test suite landed via **PR #32** (squash commit `861362d`) BEFORE this SDD
cycle ran — the spec draft itself post-dates the implementation
(2026-08-24 vs the merged fix). There is no separable test-first evidence in
history: test and implementation were squashed together. This cycle is a
**verification/documentation completion**: it unblocks the build
off-machine, completes the spec-kit artifacts, and re-proves the behaviors
with fresh green runs and deliberate mutants.

## Cycle 0 — pubspec unblock

- **Red**: `dart test` could not even load the suite on this branch:
  `Error on line 20, column 1 of pubspec.yaml: Duplicate mapping key`
  (stray second `dependency_overrides` pointing at
  `/Users/ahmettok/Developer/zuraffa`, a dev-machine path). SC-001 is
  unrunnable with a broken pubspec.
- **Green**: removed the stray override block (same fix as the spec-007
  stack); `dart pub get` resolves zuraffa 6.0.0 from git; suite loads.
- **Commit**: a1fb738.

## Cycle 1 — contract suite green re-run

- **Run**: `dart test test/data/providers/artifact/artifact_provider_test.dart`
  → **+5 passed** (U1-U5 all green against the merged implementation).
- **Analyze gate**: `dart analyze` on the service+provider pair →
  **No issues found!** (AC-1/AC-2 pinned; no `invalid_override`).

## Cycle 2 — deliberate mutants

- **Mutant 1 (stub semantics)**: `list` body → `async => <ArtifactRef>[]`
  instead of throwing. Result: **+4 -1** (U2 fails). Killed. Restored.
- **Mutant 2 (the #11 bug shape)**: drop the `NoParams params` parameter
  from the provider's `list` override. Result: `dart analyze` reports the
  `invalid_override` error — **killed at compile time**, exactly the
  regression this spec exists to prevent. Restored; suite re-verified +5.

## Final gates

- `dart analyze` (full): **162 issues — exactly the master baseline**
  (139 errors + 23 warnings, all pre-existing); zero in spec-011 files.
- `dart test` (full): **+379 passed / 8 failed** — exactly the master
  baseline (8 pre-existing loading failures in unrelated specs); zero new.
- Purity: no `dart:io` in the pair (constitution VII); hand-curated
  headers with issue #11 links present (FR-006).
