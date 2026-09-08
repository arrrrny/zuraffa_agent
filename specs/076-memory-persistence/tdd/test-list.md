# Test List: 076-memory-persistence

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-10 | PENDING |
| A11 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-11 | PENDING |
| A12 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-12 | PENDING |
| A13 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-13 | PENDING |
| A14 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-14 | PENDING |
| A15 | the pinned regression test passes (`test/engine/persistent_agent_memory_test.dart`). | AC-15 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `MemoryJsonCodec` MUST losslessly round-trip `MemoryRecord` | FR-001 | PENDING |
| U2 | `PersistentLongTermMemoryStore` MUST mirror every `remember` | FR-002 | PENDING |
| U3 | `restore()` MUST rebuild the store from the file; a missing | FR-003 | PENDING |
| U4 | During restore, malformed individual entries MUST be skipped; | FR-004 | PENDING |
| U5 | Same-id replace MUST write through without duplicating the | FR-005 | PENDING |
| U6 | `PersistentMemoryGraph` MUST mirror every `link` (including | FR-006 | PENDING |
| U7 | Writes MUST be atomic — content lands in a `*.tmp` sibling | FR-007 | PENDING |
| U8 | The facade MUST compose with persistent stores such that | FR-008 | PENDING |
| U9 | `SessionMemoryStore` MUST NOT be persisted (evaporating layer; | FR-009 | PENDING |
| U10 | The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart test` | FR-010 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 138]
route: A2 -> acceptance lane [declared: type marker, spec line 140]
route: A3 -> acceptance lane [declared: type marker, spec line 142]
route: A4 -> acceptance lane [declared: type marker, spec line 144]
route: A5 -> acceptance lane [declared: type marker, spec line 146]
route: A6 -> acceptance lane [declared: type marker, spec line 148]
route: A7 -> acceptance lane [declared: type marker, spec line 150]
route: A8 -> acceptance lane [declared: type marker, spec line 152]
route: A9 -> acceptance lane [declared: type marker, spec line 154]
route: A10 -> acceptance lane [declared: type marker, spec line 156]
route: A11 -> acceptance lane [declared: type marker, spec line 158]
route: A12 -> acceptance lane [declared: type marker, spec line 160]
route: A13 -> acceptance lane [declared: type marker, spec line 162]
route: A14 -> acceptance lane [declared: type marker, spec line 164]
route: A15 -> acceptance lane [declared: type marker, spec line 166]
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

