# Test List: EngineEvent.ToolCallCompleted

---
feature: 21-engine-event-tool-call-completed
loop: outside-in
profile: .specify/memory/tdd-profile.md # profile present at HEAD (verified during setup)
spec_criteria: 4 # spec.md declares no explicit SC-###/FR-### ids; count reflects the 4 acceptance behaviors derived from its Files + Verification sections (is-A identity, payload value-object, analyze gate, full-suite gate)
planned_at: b9ba15c # master HEAD at cycle start
updated_at: b9ba15c
suite_baseline: green # 909 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at b9ba15c; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Context at cycle start

`ToolCallCompleted` (part file, `part` directive, sealed-switch arm, is-A +
payload tests) already ships on master: `lib/src/engine/events/tool_call_completed.dart`
landed and `test/engine/events/engine_event_test.dart` carries its `#21` group
before this TDD pass ran. This cycle therefore records the spec-kit TDD
artifacts for an already-shipped, TEST-AFTER feature.

**Discrepancy found (spec vs shipped code):** spec.md's Files section requires
the `describe(EngineEvent)` switch to be extended with a `ToolCallCompleted`
case "and add is-A + payload tests." Shipped code did the is-A and payload
tests, and the switch arm IS present (compile-time exhaustive, no `default`),
but there is **no dedicated `describe(EngineEvent) switch routes
ToolCallCompleted to tool_call_completed(toolName)` assertion test** — unlike the
sibling specs #16/#17/#18 (and `ProviderError`) which each carry such a
routing-assertion test. The routing for #21 is therefore only guaranteed at
compile time via the shared exhaustive-switch test, not behaviorally asserted.
Recorded as DONE (arm present, suite green) and flagged below as a recommended
follow-up; the shipped code is followed for the DONE determination per the
hard rule.

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this spec are
exercised through `test/engine/events/engine_event_test.dart` (this is a library
feature; the public `EngineEvent` library is the entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `ToolCallCompleted` is `is EngineEvent` AND `is ToolCallCompleted` | spec.md §Files | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#21 — EngineEvent.ToolCallCompleted::ToolCallCompleted is an EngineEvent` (shipped; re-verified this cycle) |
| A2  | `ToolCallCompleted` carries `emittedAt`, `toolName`, `callId`, `ok` as independently assertable values (distinct `toolName`/`callId` strings and `ok: true` round-trip to their own fields) | spec.md §Files | example | DONE | `…::ToolCallCompleted carries payload fields` (shipped; re-verified this cycle) |
| A3  | `dart analyze --fatal-infos` exits 0 | spec.md §Verification | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` passes all 909 baseline + new tests | spec.md §Verification | gate | DONE | full suite green at HEAD (see cycle-log.md for exact counts) |

## Inner loop: unit behaviors

### `lib/src/engine/events/tool_call_completed.dart` (part file — shipped on master)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class ToolCallCompleted extends EngineEvent` declared as `part of 'engine_event.dart';` with `final DateTime emittedAt; final String toolName; final String callId; final bool ok;` and a `const` all-required constructor — value semantics, immutable | spec.md §Files | example | DONE | A1, A2 (above) |
| U2  | `emittedAt`, `toolName`, `callId`, `ok` constructor parameters bind to the fields of the same name (no cross-binding) | spec.md §Files | example | DONE | A2 distinct-values assertions |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `engine_event.dart` includes `part 'tool_call_completed.dart';` directive, picked up by the sealed library | spec.md §Files | gate | DONE | CI Analyze gate |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | The `describe(EngineEvent)` `switch` handles `ToolCallCompleted` (exhaustive with no `default` arm); the arm is present in the shared `#24` exhaustive-switch test and the shared routing-switch literals | spec.md §Files | example | DONE | `…::switch over EngineEvent is exhaustive with all current subtypes` (arm present at line 31; compiles, proving the routing arm exists) — **DISCREPANCY:** no dedicated `describe(EngineEvent) switch routes ToolCallCompleted to tool_call_completed(toolName)` assertion test (see Context) |

## Invariants and edge cases still to place

- Dedicated routing-assertion test (the `describe(EngineEvent) switch routes
  ToolCallCompleted to tool_call_completed(toolName)` form that #16/#17/#18 /
  ProviderError carry): ABSENT in shipped code — see Context discrepancy.
  Recommended follow-up, not required by the spec's literal "extend switch with
  case" wording.
- `ok: false` (error return) and correlation with `ToolCallStarted` via `callId`:
  not asserted at the type level; the tool dispatch layer owns `ok` semantics and
  `callId` correlation (issue #22). Tests assert a representative `ok: true` and a
  distinct `callId` round-trip.
- `final class` drop mutant (subclassable): unenforceable — the sealed-class
  final-class drop is not detectable by a test, same caveat as #16/#17/#18.

## Out of scope

- The 8 sibling event subtypes — each has its own spec (#16/#17/#18 precede; the
  other five predate). `ToolCallStarted` (issue #22) is the paired start event.
- The concrete tool dispatch layer that emits `ToolCallCompleted` — spec-002 /
  spec-003 tools.
- json_serializable / Zorphy annotations for `ToolCallCompleted` — issue #15 /
  spec-015-engine-event-json-part.
- Re-landing the class itself: already shipped on master; this cycle completes
  the spec-kit TDD artifacts.

## Verification commands

Copied verbatim from `.specify/memory/tdd-profile.md` at planning time:

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Coverage: `dart test --coverage=.dart_coverage {files}`
- Mutation: `package:mutation_test` NOT in lockfile — audit falls back to deliberate mutants

Applied to this feature:

- Single feature: `dart test test/engine/events/engine_event_test.dart -n "ToolCallCompleted"`
- Analyze gate: `dart analyze --fatal-infos`
