# Feature Specification: PassAtK unbiased estimator (R6 eval harness)

**Feature Branch**: `037-pass-at-k`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation — eval-run sampling + threshold semantics added, criteria made measurable)

**Status**: Approved

**Input**: Verbatim task spec — "037-pass-at-k — Pass@k evaluation metric. Existing: lib/src/data/providers/pass_at_k/pass_at_k_provider.dart, lib/src/domain/services/pass_at_k_service.dart, lib/src/domain/entities/pass_at_k/pass_at_k.dart. Spec + tests for pass@k computation over eval runs (threshold, sampling semantics)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - pass@k is computed over an eval run's outcomes (Priority: P1)

As the eval harness (R6), after a mission's n recorded runs I hold a list of per-run pass/fail outcomes; I ask `PassAtK.fromResults(outcomes, k: 3)` for the unbiased estimator without hand-counting, with the sampling semantics explicit: n = number of recorded samples, c = samples that passed, and k draws are taken **without replacement** from those n outcomes — `pass@k = 1 - C(n-c, k)/C(n, k)` (Chen et al. 2021).

**Why this priority**: The harness speaks in outcome lists, not (n, c) triples. This is the entry point every eval consumer uses; everything else serves it.

**Independent Test**: `fromResults` on a fixed outcome list equals `compute(n: length, c: trueCount, k)` on the same inputs; empty outcome lists and k outside `[1, n]` throw `ArgumentError`.

**Acceptance Scenarios**:

1. **Given** a 10-run outcome list with 6 passes, **When** `fromResults(outcomes, k: 3)`, **Then** the result equals `compute(n: 10, c: 6, k: 3)` exactly (same triple, same value).
2. **Given** an empty outcome list, or k < 1, or k > n, **When** `fromResults` is called, **Then** `ArgumentError` is thrown (the run is too small to draw from / the draw count is invalid).

---

### User Story 2 - Threshold decisions gate missions on the metric (Priority: P2)

As the eval reporter, I compare a pass@k value against a policy threshold ("mission passes eval at pass@1 >= 0.8") and need the decision to live on the metric object: `result.meetsThreshold(0.8)`.

**Why this priority**: Graders and CI gates consume thresholds; off-the-cuff comparisons drift (>= vs >). Anchoring the semantics (inclusive) on the value object makes gates reproducible.

**Independent Test**: `meetsThreshold(t)` returns `value >= t` inclusively at the boundary; thresholds outside [0, 1] throw `ArgumentError`.

**Acceptance Scenarios**:

1. **Given** a pass@k result, **When** `meetsThreshold` is called with t == value, or t just below, **Then** it returns true; with t just above, false (both sides of the boundary).
2. **Given** a threshold < 0 or > 1, **When** `meetsThreshold` is called, **Then** `ArgumentError` is thrown.

---

### User Story 3 - Estimator invariants hold across the sampling space (Priority: P3)

As a metric consumer, I rely on the estimator's mathematical shape: monotonic non-decreasing in c, monotonic non-decreasing in k (bigger draws hit a correct sample more easily), 0 at c = 0, 1 at n - c < k — all pinned so refactors cannot silently bend the formula.

**Why this priority**: These invariants are what make the number trustworthy; the existing suite covers c-monotonicity and the 0/1 endpoints, but k-monotonicity is unpinned.

**Independent Test**: For a fixed n, sweeping k from 1..n-c yields non-decreasing values (existing coverage pinned for c-sweep and endpoints).

**Acceptance Scenarios**:

1. **Given** n = 20, c = 4, **When** k sweeps 1..16, **Then** pass@k is non-decreasing across the sweep.

### Edge Cases

- fromResults with all-false outcomes? → c = 0 → value 0.0 (valid; existing estimator semantics).
- fromResults with all-true outcomes? → n - c = 0 < k always → value 1.0.
- meetsThreshold(0.0) / (1.0)? → Valid bounds; value 0.0 meets 0.0 (inclusive); nothing exceeds 1.0 but value 1.0 meets 1.0.
- Repeated identical outcomes (list order)? → Order-independent: only the count of trues matters (pinned by using shuffled fixtures in tests).
- Threshold NaN? → Outside [0,1] check must reject (`NaN` fails both bounds comparisons — thrown as ArgumentError via the explicit NaN test).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `PassAtK.fromResults(List<bool> outcomes, {required int k})` MUST derive n = outcomes.length and c = count of `true`, MUST throw `ArgumentError` on an empty outcome list (with the k range then necessarily invalid) or on k < 1 / k > n, and MUST produce a result identical (n, c, k, value) to `PassAtK.compute` on the derived triple.
- **FR-002**: Instance method `meetsThreshold(double threshold)` MUST return `value >= threshold` (inclusive at equality) and MUST throw `ArgumentError` when `threshold < 0 || threshold > 1 || threshold.isNaN`.
- **FR-003**: The estimator MUST remain monotonic non-decreasing in k for `1 <= k <= n - c` (pinned by an invariant sweep test; endpoints and c-monotonicity remain pinned by the existing suite).
- **FR-004**: `compute`'s existing validation, formula, `binomial` helper, equality-on-(n,c,k), and `toString` MUST keep their shipped semantics (pinned by the 10 pre-existing metric tests, unchanged).
- **FR-005**: The clean-arch layers (`PassAtKService.current/count`, `PassAtKProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature.

### Key Entities *(include if feature involves data)*

- **PassAtK** (value object, existing): n/c/k/value + `compute` factory; this feature adds `fromResults` (FR-001) and `meetsThreshold` (FR-002) and changes nothing else.
- **PassAtKService / PassAtKProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 13 tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `fromResults` over a 10-outcome (6 true) run at k=3 equals `compute(n:10, c:6, k:3)` — same triple, value `closeTo` within 1e-12 (AC US1-1).
- **SC-002**: `fromResults` throws on empty outcomes, k=0, k=n+1 (AC US1-2).
- **SC-003**: `meetsThreshold` returns true at t==value and just-below, false just-above; throws on -0.1, 1.1, NaN (AC US2-1..2, both boundary sides).
- **SC-004**: k-sweep monotonicity proved (AC US3-1); all 13 pre-existing tests pass unchanged (FR-004/005).
- **SC-005**: `dart analyze` zero new findings vs the 5-issue baseline; full `dart test` green.

## Assumptions

- "Outcomes" are per-run booleans (pass/fail); weighted or partial credit is out of scope (grader matrix owns it).
- Inclusive `>=` threshold semantics follow the PR-text convention "meets threshold"; the boundary test pins it either way.
- `fromResults` is a factory (returns a full PassAtK value), not a bare double, so the snapshot can flow to `PassAtKService.current` later.
