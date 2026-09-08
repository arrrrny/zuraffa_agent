# Traceability: 037-pass-at-k

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:4b6afe14f35803b526ab2bce7caaeac529cc6c5e457eb80ebabeaa0d7603f585
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a 10-run outcome list with 6 passes, **When** `fromResults(outcomes, k: 3)`, **Then** the result equals `compute(n: 10, c: 6, k: 3)` exactly (same triple, same value). | A1 | automated |
| AC-2 | 27 | 2. **Given** an empty outcome list, or k < 1, or k > n, **When** `fromResults` is called, **Then** `ArgumentError` is thrown (the run is too small to draw from / the draw count is invalid). | A2 | automated |
| AC-3 | 42 | 3. **Given** a pass@k result, **When** `meetsThreshold` is called with t == value, or t just below, **Then** it returns true; with t just above, false (both sides of the boundary). | A3 | automated |
| AC-4 | 44 | 4. **Given** a threshold < 0 or > 1, **When** `meetsThreshold` is called, **Then** `ArgumentError` is thrown. | A4 | automated |
| AC-5 | 59 | 5. **Given** n = 20, c = 4, **When** k sweeps 1..16, **Then** pass@k is non-decreasing across the sweep. | A5 | automated |
| FR-001 | 74 | - **FR-001**: `PassAtK.fromResults(List<bool> outcomes, {required int k})` MUST derive n = outcomes.length and c = count of `true`, MUST throw `ArgumentError` on an empty outcome list (with the k range then necessarily invalid) or on k < 1 / k > n, and MUST produce a result identical (n, c, k, value) to `PassAtK.compute` on the derived triple. | U1 | automated |
| FR-002 | 75 | - **FR-002**: Instance method `meetsThreshold(double threshold)` MUST return `value >= threshold` (inclusive at equality) and MUST throw `ArgumentError` when `threshold < 0 \|\| threshold > 1 \|\| threshold.isNaN`. | U2 | automated |
| FR-003 | 76 | - **FR-003**: The estimator MUST remain monotonic non-decreasing in k for `1 <= k <= n - c` (pinned by an invariant sweep test; endpoints and c-monotonicity remain pinned by the existing suite). | U3 | automated |
| FR-004 | 77 | - **FR-004**: `compute`'s existing validation, formula, `binomial` helper, equality-on-(n,c,k), and `toString` MUST keep their shipped semantics (pinned by the 10 pre-existing metric tests, unchanged). | U4 | automated |
| FR-005 | 78 | - **FR-005**: The clean-arch layers (`PassAtKService.current/count`, `PassAtKProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | U5 | automated |

