# Test List: 037-pass-at-k

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the result equals `compute(n: 10, c: 6, k: 3)` exactly (same triple, same value). | AC-1 | PENDING |
| A2 | `ArgumentError` is thrown (the run is too small to draw from / the draw count is invalid). | AC-2 | PENDING |
| A3 | it returns true; with t just above, false (both sides of the boundary). | AC-3 | PENDING |
| A4 | `ArgumentError` is thrown. | AC-4 | PENDING |
| A5 | pass@k is non-decreasing across the sweep. | AC-5 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `PassAtK.fromResults(List<bool> outcomes, {required int k})` MUST derive n = outcomes.length and c = count of `true`, MUST throw `ArgumentError` on an empty outcome list (with the k range then necessarily invalid) or on k < 1 / k > n, and MUST produce a result identical (n, c, k, value) to `PassAtK.compute` on the derived triple. | FR-001 | PENDING |
| U2 | Instance method `meetsThreshold(double threshold)` MUST return `value >= threshold` (inclusive at equality) and MUST throw `ArgumentError` when `threshold < 0 || threshold > 1 || threshold.isNaN`. | FR-002 | PENDING |
| U3 | The estimator MUST remain monotonic non-decreasing in k for `1 <= k <= n - c` (pinned by an invariant sweep test; endpoints and c-monotonicity remain pinned by the existing suite). | FR-003 | PENDING |
| U4 | `compute`'s existing validation, formula, `binomial` helper, equality-on-(n,c,k), and `toString` MUST keep their shipped semantics (pinned by the 10 pre-existing metric tests, unchanged). | FR-004 | PENDING |
| U5 | The clean-arch layers (`PassAtKService.current/count`, `PassAtKProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | FR-005 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 43]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 60]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

