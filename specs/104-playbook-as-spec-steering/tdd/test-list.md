# Test List: 104-playbook-as-spec-steering

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the engine | AC-1 | PENDING |
| A2 | loading fails with a | AC-2 | PENDING |
| A3 | the steering queue is seeded FIFO with `s1`, `s2` | AC-3 | PENDING |
| A4 | no playbook steering is injected (behavior identical to | AC-4 | PENDING |
| A5 | dispatch fails | AC-5 | PENDING |
| A6 | dispatch delegates to the | AC-6 | PENDING |
| A7 | the call delegates unchanged — | AC-7 | PENDING |
| A8 | a steering message carrying the language | AC-8 | PENDING |
| A9 | the constrained | AC-9 | PENDING |
| A10 | its | AC-10 | PENDING |
| A11 | the behavior follows the Japan document instead — different | AC-11 | PENDING |
| A12 | it also steers/gates/constrains | AC-12 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The playbook-as-spec schema MUST comprise identity fields | FR-001 | PENDING |
| U2 | The engine MUST load a playbook document (YAML source or the | FR-002 | PENDING |
| U3 | The engine MUST apply a loaded playbook's steering section as | FR-003 | PENDING |
| U4 | The engine MUST apply a loaded playbook's tool-gating section | FR-004 | PENDING |
| U5 | The engine MUST apply a loaded playbook's response section: a | FR-005 | PENDING |
| U6 | Adding a new playbook MUST require no code change — only a | FR-006 | PENDING |
| U7 | The playbook application MUST compose with the existing | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: (gates): `dart analyze --fatal-infos` exit 0 on the changed | FR-008 | PENDING |

## Routing provenance

Per-behavior routing decisions (issue #951): what each decision consulted — a declared marker/contract row, or the labeled legacy fallback to migrate.

route: A1 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A2 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A3 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A4 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A5 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A6 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A7 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A8 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A9 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A10 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A11 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: A12 -> acceptance lane [fallback: legacy description classifier matched — add `**Type**: acceptance` to the scenario]
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

