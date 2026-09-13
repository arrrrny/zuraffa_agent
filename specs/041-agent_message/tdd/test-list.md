# Test List: 041-agent_message

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | `ArgumentError` is thrown naming the field. | AC-1 | PENDING |
| A2 | they are `==` and share `hashCode` (the bug the shipped `parts == other.parts` identity comparison causes). | AC-2 | PENDING |
| A3 | they are unequal. | AC-3 | PENDING |
| A4 | the result keeps messages 2..3 (the most recent), `episodicMemories` is unchanged, and `memorySummaries` is unchanged. | AC-4 | PENDING |
| A5 | messages is empty and memories survive; given `truncate(-1)`, Then `ArgumentError`. | AC-5 | PENDING |
| A6 | the result equals a history with the same messages/memories (content-equal, not necessarily identical). | AC-6 | PENDING |
| A7 | messages grow oldest-first at the end and memories are unchanged (pin of shipped behavior). | AC-7 | PENDING |
| A8 | all pre-existing types tests pass (pinned; no new code). | AC-8 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `AgentMessage` MUST reject with `ArgumentError` an empty `id` or empty `role` (message naming the field); `parts` may be any (including empty) list. | FR-001 | PENDING |
| U2 | `AgentMessage` equality MUST compare `id`, `role`, and `parts` with ELEMENT-WISE list equality (distinct-but-equal instances compare equal); `hashCode` MUST fold `parts` content (e.g. `Object.hashAll`) so equal messages hash equally. | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: `AgentMessageHistory.appendMessages` keeps its shipped semantics (new messages appended oldest-first; memories untouched) — pinned, not changed. | FR-003 | PENDING |
| U4 | `AgentMessageHistory.truncate(int keep)` MUST return a new history whose `messages` are the LAST `keep` messages (`0` → empty), with `episodicMemories` unchanged; `keep < 0` MUST throw `ArgumentError`; `keep >= length` MUST return a content-equal history. | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: `addMemory` keeps its shipped semantics (insertion-order append of an episodic memory) — pinned, not changed. | FR-005 | PENDING |
| U6 | The sealed `AgentMessage` hierarchy in `lib/src/types.dart` (roles, content parts, JSON round-trips) MUST remain byte-identical — its coverage stays in `types_test.dart` (pinned). | FR-006 | PENDING |
| U7 | The clean-arch layers (`AgentMessageService.current/count`, `AgentMessageProvider`) MUST keep their existing signatures and stub behavior; no behavioral change in this feature. | FR-007 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [declared: type marker, spec line 26]
route: A2 -> acceptance lane [declared: type marker, spec line 28]
route: A3 -> acceptance lane [declared: type marker, spec line 30]
route: A4 -> acceptance lane [declared: type marker, spec line 45]
route: A5 -> acceptance lane [declared: type marker, spec line 47]
route: A6 -> acceptance lane [declared: type marker, spec line 49]
route: A7 -> acceptance lane [declared: type marker, spec line 51]
route: A8 -> acceptance lane [declared: type marker, spec line 66]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

