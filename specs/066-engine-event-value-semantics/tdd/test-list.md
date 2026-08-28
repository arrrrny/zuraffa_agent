# Test List: EngineEvent value semantics

---
feature: 066-engine-event-value-semantics
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — constitution.md gates + 023 artifact as de-facto rubric
spec_criteria: 4 # FR-001..FR-004 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Two independently constructed events with identical fields are `==` (and symmetric); events differing in any single field are not | FR-001 | example | DONE | `test/engine/events/engine_event_test.dart::spec 066 — EngineEvent value semantics::<Type> value equality` (9 blocks) |
| A2  | Equal events have equal `hashCode` (hashCode/== contract) | FR-002 | example | DONE | `…::<Type> hashCode matches for equal events` (9 blocks) |
| A3  | `toString` renders `TypeName(field: value, …)` for ALL fields in declaration order (nullable → `null`, DateTime → its own toString) | FR-003 | example | DONE | `…::<Type> toString renders all fields` (9 blocks) |
| A4  | `dart analyze --fatal-infos` exits 0 and `dart test` passes baseline + new | FR-004 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### The 9 part files (`lib/src/engine/events/*.dart`)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `==` follows the house pattern: `identical` short-circuit, `runtimeType` guard, then every field compared — verified per subtype by flipping each field in turn | FR-001 | example | DONE | A1 blocks assert inequality per varied field |
| U2  | `hashCode` is `Object.hash` over all fields — equal objects hash equal; identity-based hashing (the mutant) breaks A2 | FR-002 | example | DONE | A2 blocks + mutant M2 |
| U3  | `toString` interpolates every field — dropping any field breaks the exact-string assertion | FR-003 | example | DONE | A3 blocks + mutant M3 |
| U4  | `runtimeType` guard: a `TurnStarted` never equals a `TurnCompleted` even when payload shapes coincide | FR-001 | example | DONE | `…::different runtimeTypes are never equal` |

## Invariants and edge cases

- Nullable fields (`turnId`, `reason`, `summary`): `null == null` must hold in equality and render `null` in toString — covered in the respective blocks.
- `identical` short-circuit: trivially satisfied by construction; not separately tested (language guarantee).
- hashCode consistency across a single program run only — the Dart contract; not tested across isolates.

## Out of scope

- `PlanChanged` (spec 067) — brings its own semantics at birth.
- EngineEventLog (spec 068).
- JSON serialization (issue #15 / spec 015).
- Base `EngineEvent` class: no fields, nothing to add — subtype-level only.

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_test.dart --name "spec 066" --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Mutation: deliberate mutants, one at a time (see `verification.md`)
