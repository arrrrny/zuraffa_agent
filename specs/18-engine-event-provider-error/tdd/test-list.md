# Test List: EngineEvent.ProviderError

---
feature: 018-engine-event-provider-error
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — constitution.md gates applied instead (see verification.md)
spec_criteria: 4 # acceptance criteria SC-001, SC-002 + FR-001..FR-004 in spec.md
planned_at: 30b4b94 # master HEAD at cycle start
updated_at: HEAD
suite_baseline: green # 911 passed / 2 skipped (pre-existing KIMI_API_KEY integration skips) at 30b4b94; green criterion for this feature = its tests pass AND full-suite delta vs baseline is 0 new failures
---

## Context at cycle start

`ProviderError` (part file, `part` directive, sealed-switch arm, is-A +
payload tests) landed on master via PR #40 (`20737f0`-line history,
closed issue #18) before this TDD pass ran. This cycle closes the two
gaps that remained against the spec's TDD obligations:

1. `specs/18-engine-event-provider-error/tdd/` artifacts did not exist.
2. Behavioral coverage was partial: the `describe(EngineEvent)` routing
   for `ProviderError` was never asserted, and every pre-existing test
   constructed `providerName` and `error` as the identical string
   `'sample'` — a cross-binding or field-swap defect between the two
   strings was undetectable.

## Outer loop: acceptance behaviors

Per `spec.md`'s Verification section, the acceptance behaviors for this
spec are exercised through `test/engine/events/engine_event_test.dart`
(this is a library feature; the public `EngineEvent` library is the
entry surface).

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | `ProviderError` is `is EngineEvent` AND `is ProviderError` | FR-001, SC-001 | example | DONE | `test/engine/events/engine_event_test.dart::arrarrny/zuraffa_agent#18 — EngineEvent.ProviderError::ProviderError is an EngineEvent` (landed with #40; re-verified this cycle) |
| A2  | `ProviderError` carries `emittedAt`, `providerName`, `error` with the two strings independently assertable (distinct values round-trip to their own fields) | FR-001, SC-002 | example | DONE | `…::ProviderError carries payload fields` (strengthened this cycle: distinct `providerName` vs `error` values) |
| A3  | `dart analyze --fatal-infos` exits 0 | FR-004, SC-001 | gate | DONE | CI gate `.github/workflows/pipeline.yml::verify / Analyze` |
| A4  | `dart test` passes all 911 baseline + new tests | FR-004, SC-002 | gate | DONE | full suite green at HEAD (see verification.md for exact counts) |

## Inner loop: unit behaviors

### `lib/src/engine/events/provider_error.dart` (part file — landed via #40)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `final class ProviderError extends EngineEvent` declared as `part of 'engine_event.dart';` with `final DateTime emittedAt; final String providerName; final String error;` and a `const` all-required constructor — value semantics, immutable | FR-001 | example | DONE | A1, A2 (above); proven by mutants M1/M2 |
| U2  | `providerName` and `error` constructor parameters bind to the fields of the same name (no cross-binding — the failing provider identity and the failure text are distinct concepts) | FR-001 | example | DONE | A2 distinct-values assertions; proven by mutant M2 |

### `lib/src/engine/events/engine_event.dart` (sealed base)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U3  | `engine_event.dart` includes `part 'provider_error.dart';` directive, picked up by the sealed library | FR-002 | gate | DONE | CI Analyze gate; proven by mutant M3 |

### Test file: `test/engine/events/engine_event_test.dart`

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | The `describe(EngineEvent)` `switch` handles `ProviderError` (exhaustive with no `default` arm) and routes it to `provider_error(<providerName>)` — the routing exposes WHICH provider failed, not the error text | FR-003 | example | DONE | `…::describe(EngineEvent) switch routes ProviderError to provider_error(providerName)` (new this cycle; the shared #24 group switch already carries the arm — this test asserts its output AND that the routing keys on `providerName`, not `error`) |

## Invariants and edge cases still to place

- `providerName` != `error` (e.g. `'openai'` vs `'401 unauthorized'`):
  covered by the strengthened A2 with distinct values.
- Terminal-failure classes (auth / rate-limit / network): the spec
  names them as emission triggers, not as typed fields — `error` is the
  free-form diagnostic string. Classification lives in the fallback
  chain (spec-004); out of scope here.
- Pairs with the fallback chain (spec-004): documented at the type
  level in doc comments; the emitting site is the fallback chain
  runtime (out of scope).

## Out of scope

- The 8 sibling event subtypes — each has its own spec (016 and 017
  precede this one; the other six predate it).
- The fallback-chain runtime that emits `ProviderError` (spec-004 /
  spec-008) and any retry/fallback behavior it triggers.
- json_serializable / Zorphy annotations for `ProviderError` —
  issue #15 / spec-015-engine-event-json-part.
- Re-landing the class itself: landed via merged PR #40; this cycle
  completes the spec-kit TDD artifacts and closes the coverage gaps.

## Verification commands

- Single feature: `dart test test/engine/events/engine_event_test.dart --name "ProviderError" --reporter expanded`
- Full suite: `dart test`
- Analyze gate: `dart analyze --fatal-infos`
- Coverage: `dart test --coverage=coverage` (not run — `package:coverage` not installed; adding deps mid-loop is forbidden)
- Mutation: no mutation tool installed — deliberate mutants per rubric (see `verification.md`)
