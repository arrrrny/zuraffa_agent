# Feature Specification: PassAtK unbiased estimator (R6 eval harness)

**Branch**: `037-pass-at-k` | **Date**: 2026-08-24

## Summary
Hand-curated `PassAtK` value object — spec-exact from epic #1 §R6.2 (issue #7 body: "Metrics: pass@k (unbiased estimator), pass^k (empirical); graders: exact / schema / model-judge"). Implements the unbiased pass@k estimator from the CodeForces/HumanEval paper (Chen et al., 2021): `pass@k = E[1 - C(n-c, k) / C(n, k)]` where n=total samples, c=correct samples, k=draw count. Pure deterministic function — no LLM, no I/O, no randomness. The repo doesn't yet ship a record/replay harness or any grader; this PR adds the **metric** that the harness will emit per mission.

This advances epic issue #7 (R6 — eval harness). The record/replay cassettes and the grader matrix (exact / schema / model-judge) build on this surface in later PRs.

## Files
- `lib/src/domain/entities/pass_at_k/pass_at_k.dart` — `PassAtK` value object (n + c + k + value (precomputed at construction); value-based equality on n/c/k; static `compute(n, c, k)` factory; static `_binomial(a, b)` helper). Validates `0 ≤ c ≤ n` and `1 ≤ k ≤ n`; throws `ArgumentError` on invalid input.
- `lib/src/domain/services/pass_at_k_service.dart` — abstract `PassAtKService` (current(NoParams), count(NoParams)).
- `lib/src/data/providers/pass_at_k/pass_at_k_provider.dart` — concrete `PassAtKProvider` stub (UnimplementedError bodies).
- `test/data/providers/pass_at_k/pass_at_k_provider_test.dart` — 13 regression tests (10 metric + 3 clean-arch).
- `specs/037-pass-at-k/{spec,plan,tasks}.md`.

## Verification
- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — All pre-existing + 13 new tests pass

## Advances #7 (R6 — eval harness)
