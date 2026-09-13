# Test List: 077-memory-distiller

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/engine/memory_distiller_test.dart`). | AC-10 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `DistillationPolicy` MUST expose `salienceThreshold` | FR-001 | PENDING |
| U2 | `distill(sessionId)` MUST promote exactly the session | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: Boundary: `salience == threshold` promotes. | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: A record whose normalized content (trim + case-fold) already | FR-004 | PENDING |
| U5 | With `maxPerSession` set, promotions MUST be capped to the | FR-005 | PENDING |
| U6 | Below-threshold records MUST be skipped with | FR-006 | PENDING |
| U7 | `distill` MUST be idempotent — a second run on the same | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: Unknown / empty session → empty report, no throw. | FR-008 | PENDING |
| U9 | `DistillationReport` MUST carry `promoted` (ids, promotion | FR-009 | PENDING |
| U10 | The system MUST satisfy this requirement: Composed with the 076 persistent stores, distilled records | FR-010 | PENDING |
| U11 | The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart | FR-011 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 135]
route: A2 -> acceptance lane [declared: type marker, spec line 137]
route: A3 -> acceptance lane [declared: type marker, spec line 139]
route: A4 -> acceptance lane [declared: type marker, spec line 141]
route: A5 -> acceptance lane [declared: type marker, spec line 143]
route: A6 -> acceptance lane [declared: type marker, spec line 145]
route: A7 -> acceptance lane [declared: type marker, spec line 147]
route: A8 -> acceptance lane [declared: type marker, spec line 149]
route: A9 -> acceptance lane [declared: type marker, spec line 151]
route: A10 -> acceptance lane [declared: type marker, spec line 153]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U9 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U10 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U11 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

