# Test List: EngineEvent.ToolCallStarted

---
feature: 022-engine-event-tool-call-started
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 5 # implicit acceptance criteria derived from spec.md (Verification section): analyze clean, test pass, is-A, payload shape, dispatcher-emission site documented
planned_at: 4cdf63b
updated_at: HEAD
suite_baseline: green # full suite green at parent commit; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this
spec are exercised through `test/engine/events/engine_event_test.dart`
(this is a library feature; the public `EngineEvent` library is the
entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `ToolCallStarted` is `is EngineEvent` AND `is ToolCallStarted` | spec.md Verification #3, FR-payload | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#22 — EngineEvent.ToolCallStarted::ToolCallStarted is an EngineEvent` |
| A2  | `ToolCallStarted` carries `emittedAt`, `toolName`, `callId` | spec.md Files section, FR-payload | example | DONE | `test/engine/events/engine_event_test.dart::…::ToolCallStarted carries emittedAt, toolName, callId` |
| A3  | `dart analyze --fatal-infos` clean on `lib/src/engine/events/` | spec.md Verification #2 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` green (≥ 145 tests) | spec.md Verification #3 | gate | DONE | 529 tests pass at HEAD |
| A5  | The `switch` over `EngineEvent` is exhaustive with the new `ToolCallStarted` case added (no `default` arm needed — the test's switch lists all 9 subtypes) | spec.md Verification #3 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#24 — sealed EngineEvent library::switch over EngineEvent is exhaustive with all current subtypes` |

## Inner loop: unit behaviors

### `lib/src/engine/events/tool_call_started.dart` (part file)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class ToolCallStarted extends EngineEvent` is declared as a `part of 'engine_event.dart';` with `final DateTime emittedAt; final String toolName; final String callId;` and a `const ToolCallStarted({required this.emittedAt, required this.toolName, required this.callId})` constructor — value semantics, immutable | spec.md Files section | example | DONE | A1, A2 (above) |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U2  | `engine_event.dart` includes `part 'tool_call_started.dart';` directive, picked up by the sealed library | spec.md Files section | gate | DONE | CI Analyze gate (analyzer fails if the part directive is missing because the test references the type) |

### Emission site wiring (`lib/src/engine/tool_dispatcher.dart`)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | The dispatcher interface is documented as the emission site for `ToolCallStarted` — emitted BEFORE the tool implementation runs, paired with `ToolCallCompleted` (issue #21) via `callId`. The current dispatcher is an abstract interface (no concrete dispatcher yet); the emission contract is captured in the spec + dartdoc on `ToolCallStarted` and is enforced when the concrete dispatcher lands in spec-002. | spec.md Summary, FR-payload | docs | DONE | `lib/src/engine/events/tool_call_started.dart` dartdoc references the dispatcher; `lib/src/engine/tool_dispatcher.dart` is the documented emission site. |

## Invariants and edge cases still to place

- `callId` correlation between `ToolCallStarted` and `ToolCallCompleted`: the dispatcher's correlation logic is spec-002 work; the data-type surface is delivered here and the `callId` field is the correlation key (asserted by mutant U1-M2).
- Empty / blank `toolName` or `callId`: not validated at the type level — the dispatcher is the right enforcement site (out of scope). The test asserts the round-trip of a well-formed call; a dispatcher-level guard would catch the empty-string case.

## Out of scope

- The 8 sibling event subtypes — each has its own spec.
- The concrete dispatcher that emits `ToolCallStarted` — spec-002.
- json_serializable for `ToolCallStarted` — issue #15.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md`:

- Single test: `dart test test/engine/events/engine_event_test.dart --name "ToolCallStarted" --reporter expanded`
- Full suite: `dart test`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; profile forbids mid-loop dep additions)
- Mutation: none installed — deliberate mutants per rubric (see `verification.md`)
