# Test List: EngineEvent sealed library + TurnStarted

---
feature: 024-engine-event-turn-started
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 4 # acceptance criteria SC-001..SC-004 in spec.md
planned_at: 4cdf63b
updated_at: HEAD
suite_baseline: green # 134 pre-existing tests on the parent commit; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Outer loop: acceptance behaviors

One per success criterion in `spec.md`, exercised through the new `test/engine/events/engine_event_test.dart` suite (this is a library feature; the public `EngineEvent` library is the entry surface — no separate acceptance runner, per the stack profile).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `TurnStarted` is `is EngineEvent` — sealed-class subtype check compiles & succeeds | SC-001, SC-003, FR-001, FR-002 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#24 — sealed EngineEvent library::TurnStarted is an EngineEvent` |
| A2  | `TurnStarted` carries `emittedAt` and optional `turnId` (null for ephemeral turns) | SC-001, FR-002 | example | DONE | `test/engine/events/engine_event_test.dart::…::TurnStarted carries emittedAt + optional turnId` + `…::TurnStarted.turnId defaults to null for ephemeral turns` |
| A3  | A `switch` over `EngineEvent` is exhaustive when every current subtype is handled with no `default` arm — proves the sealed union is well-formed | SC-001, SC-003, FR-004 | example | DONE | `test/engine/events/engine_event_test.dart::…::switch over EngineEvent is exhaustive with all current subtypes` |
| A4  | `dart analyze --fatal-infos` reports zero `invalid_use_of_type_outside_library` codes on `lib/src/engine/events/` (compiler-level guarantee — surfaced by the analyzer gate in CI, not by a `dart test`) | SC-001, SC-003, FR-004 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |

## Inner loop: unit behaviors

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `EngineEvent` is `sealed` so subtypes declared in foreign libraries are rejected with `invalid_use_of_type_outside_library` (compiler guard — verified by the green analyzer gate, not by a runtime test) | FR-001, FR-004 | gate | DONE | CI Analyze gate |

### `lib/src/engine/events/turn_started.dart` (part file)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U2  | `TurnStarted` declares `final DateTime emittedAt; final String? turnId;` with a `const TurnStarted({required this.emittedAt, this.turnId})` constructor — value semantics, immutable | FR-002 | example | DONE | A2 (above) |

### `lib/zuraffa_agent.dart` (public export)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `export 'src/engine/events/engine_event.dart';` is reachable from the public package entry, so downstream consumers can `import 'package:zuraffa_agent/zuraffa_agent.dart'` and see `EngineEvent` + `TurnStarted` | FR-003 | example | DONE | indirect — `engine_event_test.dart` imports via `package:zuraffa_agent/src/engine/events/engine_event.dart`; the public-export reachability is structurally enforced by the analyzer when consumers use the barrel. |

## Invariants and edge cases still to place

- Exhaustive `switch` over `EngineEvent` while there is only one subtype: handled by adding a `default`/`_` arm — covered by the sibling-spec evolution (#23 `TurnCompleted`, #22 `ToolCallStarted`, …) which extend the switch exhaustively. The current test demonstrates the multi-subtype exhaustive form.
- JSON serialization of `EngineEvent` subtypes: tracked separately as issue #15 (`engine-event-json-part`); the `part 'engine_event.g.dart';` directive is already in place so the generator can emit it later without re-touching the file. No test here — out of scope for #24.
- `DateTime` purity: `DateTime` is `dart:core` — does not pull in `dart:io` (constitution VII). Implicit; no dedicated test.

## Out of scope

- The 8 sibling event subtypes (#16..#23) — each has its own spec and PR.
- The json_serializable part (#15) — separate spec.
- Emission of `TurnStarted` by the engine loop (spec-002) — this spec delivers the data type only.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test test/engine/events/engine_event_test.dart --name "TurnStarted" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; profile forbids mid-loop dep additions)
- Mutation: none installed — deliberate mutants per rubric (see `verification.md`)
