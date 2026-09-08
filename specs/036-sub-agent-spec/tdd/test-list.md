# Test List: 036-sub-agent-spec

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | `ArgumentError` is thrown naming that field. | AC-1 | PENDING |
| A2 | `ArgumentError` is thrown naming the list. | AC-2 | PENDING |
| A3 | `ArgumentError` is thrown naming the budget field. | AC-3 | PENDING |
| A4 | `ArgumentError` is thrown (1-cycles are ill-formed). | AC-4 | PENDING |
| A5 | `isLeaf` == `subAgents.isEmpty`, `isRoot` == `extendsSpec == null`, and `hasBudgets` reflects the three budget fields (AC covered by existing tests — pinned, not new). | AC-5 | PENDING |
| A6 | they are `==` and share `hashCode` (AC covered by existing tests — pinned, not new). | AC-6 | PENDING |
| A7 | they are unequal. | AC-7 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | `SubAgentSpec` MUST reject with `ArgumentError` any construction where `name`, `description`, or `systemPrompt` is an empty string (the message MUST name the field). | FR-001 | PENDING |
| U2 | `SubAgentSpec` MUST reject with `ArgumentError` any blank id (`''`) inside `tools` or `subAgents` (the message MUST name the offending list). | FR-002 | PENDING |
| U3 | `SubAgentSpec` MUST reject with `ArgumentError` a non-positive budget when supplied: `maxTurns != null && maxTurns < 1`, `contextWindowTokens != null && contextWindowTokens < 1`, or `wallClockTimeout` with negative `Duration` (message MUST name the field). `Duration.zero` remains valid. | FR-003 | PENDING |
| U4 | `SubAgentSpec` MUST reject with `ArgumentError` the 1-cycle `extendsSpec == name`. | FR-004 | PENDING |
| U5 | The structural getters MUST keep their documented semantics: `isLeaf` == `subAgents.isEmpty`; `isRoot` == `extendsSpec == null`; `hasBudgets` == any of the three budget fields non-null. | FR-005 | PENDING |
| U6 | Equality/hashCode MUST keep field-wise value semantics across all ten fields (list-aware for `tools`/`subAgents`), and MUST be constructible with non-const lists without breaking equality. | FR-006 | PENDING |
| U7 | The clean-arch layers (`SubAgentSpecService.current/count`, `SubAgentSpecProvider`) MUST keep their existing signatures and stub behavior (UnimplementedError); no behavioral change to those layers in this feature. | FR-007 | PENDING |

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

