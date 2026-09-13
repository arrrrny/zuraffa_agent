# Test List: 083-usage-ledger

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/usage_ledger_083_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-14 | PENDING |
| A15 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-15 | PENDING |
| A16 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-16 | PENDING |
| A17 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-17 | PENDING |
| A18 | the pinned regression test passes (`test/usage_ledger_test.dart`). | AC-18 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: `UsageLedger` is constructed by defensive copy into an | FR-001 | PENDING |
| U2 | The system MUST satisfy this requirement: `UsageLedger.entries` exposes the (unmodifiable) entry | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: `UsageLedger.toJson()` serializes the projection as | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: Equality is ordered-sequence equality over structurally | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: Existing aggregate surface is unchanged: | FR-005 | PENDING |
| U6 | The system MUST satisfy this requirement: Sub-ledgers are themselves full projections: `byTurn` / | FR-006 | PENDING |
| U7 | The system MUST satisfy this requirement: Edge cases: an empty ledger equals every other empty ledger, | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: Gates — `dart analyze` reports no new issues relative to the | FR-008 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 169]
route: A2 -> acceptance lane [declared: type marker, spec line 171]
route: A3 -> acceptance lane [declared: type marker, spec line 173]
route: A4 -> acceptance lane [declared: type marker, spec line 175]
route: A5 -> acceptance lane [declared: type marker, spec line 177]
route: A6 -> acceptance lane [declared: type marker, spec line 179]
route: A7 -> acceptance lane [declared: type marker, spec line 181]
route: A8 -> acceptance lane [declared: type marker, spec line 183]
route: A9 -> acceptance lane [declared: type marker, spec line 185]
route: A10 -> acceptance lane [declared: type marker, spec line 187]
route: A11 -> acceptance lane [declared: type marker, spec line 189]
route: A12 -> acceptance lane [declared: type marker, spec line 191]
route: A13 -> acceptance lane [declared: type marker, spec line 193]
route: A14 -> acceptance lane [declared: type marker, spec line 195]
route: A15 -> acceptance lane [declared: type marker, spec line 197]
route: A16 -> acceptance lane [declared: type marker, spec line 199]
route: A17 -> acceptance lane [declared: type marker, spec line 201]
route: A18 -> acceptance lane [declared: type marker, spec line 203]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

