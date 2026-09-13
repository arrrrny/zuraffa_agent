# Test List: 006-eval-harness-golden

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the engine consumes recordings instead of live calls with identical event order. | AC-1 | PENDING |
| A2 | the harness reports a mismatch loudly — never silently passes. | AC-2 | PENDING |
| A3 | pass@k matches the analytic value. | AC-3 | PENDING |
| A4 | CI fails with per-task breakdown. | AC-4 | PENDING |
| A5 | byte-equality decides. | AC-5 | PENDING |
| A6 | JSON-Schema validity decides. | AC-6 | PENDING |
| A7 | the parsed verdict decides, and the judge call is replayed deterministically. | AC-7 | PENDING |
| A8 | all report and gate correctly. | AC-8 | PENDING |
| A9 | no dart:io imports exist (CLI/loader layers exempt). | AC-9 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The harness MUST record LLM + tool traffic and replay deterministically, detecting input drift. | FR-001 | PENDING |
| U2 | Scoring MUST implement pass@k (unbiased estimator) and pass^k (empirical) with per-task breakdowns. | FR-002 | PENDING |
| U3 | Graders MUST include exact, schema, and model-judge (recorded) types. | FR-003 | PENDING |
| U4 | The harness MUST be consumable by `zfa agent replay` (plugin CLI) and dws_playground suites. | FR-004 | PENDING |
| U5 | The eval runtime MUST be dart:io-free (enforced by static gate). | FR-005 | PENDING |

## Key entities

| entity | fields |
| ------ | ------ |
| GoldenMission |  |
| Suite |  |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 41]
route: A4 -> acceptance lane [declared: type marker, spec line 43]
route: A5 -> acceptance lane [declared: type marker, spec line 56]
route: A6 -> acceptance lane [declared: type marker, spec line 58]
route: A7 -> acceptance lane [declared: type marker, spec line 60]
route: A8 -> acceptance lane [declared: type marker, spec line 73]
route: A9 -> acceptance lane [declared: type marker, spec line 86]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

