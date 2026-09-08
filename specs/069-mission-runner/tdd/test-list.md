# Test List: 069-mission-runner

## Outer loop: acceptance behaviors

One per acceptance criterion in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| A1 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-1 | PENDING |
| A2 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-2 | PENDING |
| A3 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-3 | PENDING |
| A4 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-4 | PENDING |
| A5 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-5 | PENDING |
| A6 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-6 | PENDING |
| A7 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-7 | PENDING |
| A8 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-8 | PENDING |
| A9 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-9 | PENDING |
| A10 | the pinned regression test passes (`test/engine/mission_runner_test.dart`). | AC-10 | PENDING |

## Outer loop: widget behaviors

UI acceptance scenarios (bug #830): asserted through a testWidgets pair — a view-builder subject stub plus a widget test that pumps the view and asserts the scenario.

The `kind` cell is the finder-kind taxonomy (issue #1140): the scenario verbs' predicted assertion classes — presence, absence, route-outcome, enabled-state, sequence — or `none` when no finder is derivable. `zfa tdd gen` selects the assertion template by it and refuses a row whose kind column drifted from the scenario prose; verify-red's kind gate (issue #959/#964) certifies on the same vocabulary.

| id | behavior | kind | traces | state |
| -- | -------- | ---- | ------ | ----- |

## Inner loop: unit behaviors

One per functional requirement in `spec.md`.

| id | behavior | traces | state |
| -- | -------- | ------ | ----- |
| U1 | The system MUST satisfy this requirement: `MissionRunner.run({missionId, messages, planner?})` emits, in | FR-001 | PENDING |
| U2 | The system MUST satisfy this requirement: Natural completion: when a turn's `finishReason == 'stop'` and | FR-002 | PENDING |
| U3 | The system MUST satisfy this requirement: Tool dispatch: each planned `ToolCall` is dispatched | FR-003 | PENDING |
| U4 | The system MUST satisfy this requirement: Steering drain: when constructed with a `SteeringQueue`, all | FR-004 | PENDING |
| U5 | The system MUST satisfy this requirement: Budgets (from `StopPolicy`, when `enabled`): effective turn cap | FR-005 | PENDING |
| U6 | The system MUST satisfy this requirement: Provider failure: if `executor.runTurn` throws, the runner | FR-006 | PENDING |
| U7 | The system MUST satisfy this requirement: `MissionResult` carries value semantics (spec 066 house | FR-007 | PENDING |
| U8 | The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green | FR-008 | PENDING |

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
route: U1 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U2 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U3 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U4 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U5 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U6 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U7 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]
route: U8 -> unit lane [fallback: legacy description classifier matched — trace FR to a declared contract row]

