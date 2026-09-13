# Test List: 25-repetition_tracker-datasource-pair

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | `isLooping` is false and `count` returns 2. | AC-1 | PENDING |
| A2 | `isLooping` is true (threshold met — "more than N times in the last M seconds" is inclusive of the Nth hit). | AC-2 | PENDING |
| A3 | both loop independently — counts are keyed per signature, never shared. | AC-3 | PENDING |
| A4 | count is 0 and no loop is signalled. | AC-4 | PENDING |
| A5 | only the second record counts (boundary: exactly `window` old is expired; strictly inside is alive). | AC-5 | PENDING |
| A6 | all counts drop to 0, no signature loops, and `current()` still returns the same configuration. | AC-6 | PENDING |
| A7 | it returns the post-record in-window count for that signature (single round-trip read-after-write). | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The `RepetitionTracker` value object MUST expose the loop-detection configuration — `id`, `maxCalls` (N), `window` (M) — with value equality across all fields. | FR-001 | PENDING |
| U2 | `RepetitionTracker` MUST expose a pure predicate `isRepetition(observedCalls)` that returns true iff `observedCalls >= maxCalls`, so threshold logic is testable without a datasource. | FR-002 | PENDING |
| U3 | The datasource interface MUST define the persistence contract: `current()`, `reset()`, `record(signature)`, `count(signature)`, `isLooping(signature)` — all asynchronous. | FR-003 | PENDING |
| U4 | `record` MUST accept an optional injectable timestamp; `count`/`isLooping` MUST accept an optional injectable evaluation time, so window behavior is deterministically testable. | FR-004 | PENDING |
| U5 | The mock datasource MUST implement in-memory sliding-window tracking: per-signature timestamp lists, pruned to the window at write and read time. | FR-005 | PENDING |
| U6 | `isLooping(signature)` MUST equal `current().isRepetition(count(signature))` — the signal is always derived from the live window count and the configured threshold. | FR-006 | PENDING |
| U7 | `reset()` MUST clear every recorded signature history while preserving the tracker configuration returned by `current()`. | FR-007 | PENDING |
| U8 | The entity, interface, and mock MUST keep constructor backward compatibility: `RepetitionTracker({required id})` and `RepetitionTrackerMockDatasource()` must keep compiling with sensible defaults (`maxCalls=5`, `window=60s`). | FR-008 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 62]
route: A7 -> acceptance lane [declared: type marker, spec line 64]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

