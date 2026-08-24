# Implementation Plan: PassAtK unbiased estimator
**Branch**: `037-pass-at-k` | **Date**: 2026-08-24

## Summary
Hand-curate the `PassAtK` value object (R6.2 spec-exact) + `PassAtKService` + `PassAtKProvider`. Pattern mirrors PR #49 (ToolResult value object + clean-arch layers) and PR #50 (AgentSession root entity): plain Dart value object, no `@Zorphy` codegen, compiles without `build_runner`. The repo doesn't yet ship a record/replay harness; this PR adds the metric that the harness will emit per mission.

## Phase 1 — Design
- **PassAtK** (value object): captures a single pass@k computation — `n` (int, total samples), `c` (int, correct samples, 0 ≤ c ≤ n), `k` (int, draw count, 1 ≤ k ≤ n), `value` (double, the unbiased pass@k estimator, 0.0 to 1.0, precomputed at construction). Static factory `compute({required int n, required int c, required int k})` validates inputs (`ArgumentError` on invalid) and computes the unbiased estimator per Chen et al. 2021: `pass@k = 1 - C(n-c, k) / C(n, k)`; if `n - c < k`, the answer is `1.0` (every combination includes at least one correct sample). Static helper `_binomial(a, b)` computes C(a, b) = a! / (b! * (a-b)!) with overflow-safe integer multiplication. Value equality across n/c/k (the value field is derived, so equality on n/c/k implies value equality). `toString` reports the input triple and the computed value.
- **Service** (`PassAtKService`): abstract, two `NoParams`-param methods — `current(NoParams)` returns the most-recently-computed pass@k snapshot, `count(NoParams)` returns the count of pass@k computations logged in the active mission.
- **Provider** (`PassAtKProvider`): concrete stub implementing `PassAtKService` with matching `NoParams` signatures; bodies throw `UnimplementedError`.

## Phase 2 — Tasks
See `tasks.md`.
