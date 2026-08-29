# Test List: R1 — Steering Message value object (spec 081)

---
feature: 081-steering-message
loop: characterization # implementation pre-existed at branch creation; tests pin existing behavior — see tdd/verification.md
profile: .specify/memory/tdd-profile.md # file absent at HEAD — rubric graded against the tdd-test-quality-rubric template + constitution.md Principles II/V/IX
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: master (29b7fef)
updated_at: 081-steering-message (planned)
suite_baseline: 1073 passed / 2 skipped at 29b7fef (master)
suite_after: 1096 passed / 2 skipped at 081-steering-message HEAD (+23 new, 0 regressions)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | A `SteeringMessage` with arbitrary id + content + UTC timestamp round-trips through `toJson` → `fromJson` to an equal message (lossless) | FR-002, FR-003, US1 | example | PASSING | `test/domain/entities/steering_message/steering_message_test.dart::spec 081 — SteeringMessage::round-trip — arbitrary values round-trip losslessly` |
| A2  | Every malformed-input variant throws `ArgumentError` whose `.name` matches the offending key — never a generic exception, never a silent default | FR-004, US2 | example | PASSING | `…::typed errors — every malformed-input variant throws ArgumentError naming the offending key` |
| A3  | Gates: `dart analyze --fatal-infos` exit 0 on the changed files; full `dart test` green (baseline 1073/2 + 23 new) | FR-008 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### Round-trip (FR-002 / FR-003)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | Arbitrary id + content + UTC timestamp → `toJson` → `fromJson` → equals original (by FR-005) | FR-002, FR-003 | unit | PASSING | `…::round-trip — arbitrary values round-trip losslessly` |
| U2  | `toJson` produces exactly three keys: `id`, `content`, `injectedAt`; no extras, no omissions | FR-002 | unit | PASSING | `…::toJson — shape has exactly three keys` |
| U3  | `toJson`'s `injectedAt` is an ISO-8601 string parseable by `DateTime.parse` | FR-002 | unit | PASSING | `…::toJson — injectedAt is ISO-8601 parseable` |

### Typed ArgumentError on malformed input (FR-004)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U4  | Missing `id` key → `ArgumentError` with `.name = 'id'` | FR-004 | unit | PASSING | `…::typed errors — missing id throws ArgumentError naming id` |
| U5  | `id` is not a String (e.g. an int) → `ArgumentError` with `.name = 'id'` | FR-004 | unit | PASSING | `…::typed errors — non-string id throws ArgumentError naming id` |
| U6  | Missing `content` key → `ArgumentError` with `.name = 'content'` | FR-004 | unit | PASSING | `…::typed errors — missing content throws ArgumentError naming content` |
| U7  | `content` is not a String → `ArgumentError` with `.name = 'content'` | FR-004 | unit | PASSING | `…::typed errors — non-string content throws ArgumentError naming content` |
| U8  | Missing `injectedAt` key → `ArgumentError` with `.name = 'injectedAt'` | FR-004 | unit | PASSING | `…::typed errors — missing injectedAt throws ArgumentError naming injectedAt` |
| U9  | `injectedAt` is not a String → `ArgumentError` with `.name = 'injectedAt'` | FR-004 | unit | PASSING | `…::typed errors — non-string injectedAt throws ArgumentError naming injectedAt` |
| U10 | `injectedAt` is a String but unparseable as ISO-8601 → `ArgumentError` with `.name = 'injectedAt'` | FR-004 | unit | PASSING | `…::typed errors — unparseable injectedAt throws ArgumentError naming injectedAt` |

### Equality (FR-005)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U11 | Two messages with the same id+content+timestamp compare `==` | FR-005 | unit | PASSING | `…::equality — equal messages are ==` |
| U12 | Differing `id` breaks `==` | FR-005 | unit | PASSING | `…::equality — differing id breaks ==` |
| U13 | Differing `content` breaks `==` | FR-005 | unit | PASSING | `…::equality — differing content breaks ==` |
| U14 | Differing `injectedAt` breaks `==` | FR-005 | unit | PASSING | `…::equality — differing injectedAt breaks ==` |
| U15 | `hashCode` agrees with `==` for both the equal case and each unequal case | FR-005 | unit | PASSING | `…::equality — hashCode agrees with ==` |
| U16 | Identity equality — `msg == msg` is `true` (same instance) | FR-005 | unit | PASSING | `…::equality — identity short-circuits` |

### Edge cases (FR-006)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U17 | Empty `content` (length 0) round-trips losslessly | FR-006 | unit | PASSING | `…::edge case — empty content round-trips` |
| U18 | Unicode in `id` (Chinese characters, emoji) round-trips losslessly | FR-006 | unit | PASSING | `…::edge case — unicode id round-trips` |
| U19 | Unicode in `content` (Chinese, emoji, RTL text) round-trips losslessly | FR-006 | unit | PASSING | `…::edge case — unicode content round-trips` |
| U20 | Non-UTC `injectedAt` (with explicit timezone offset) round-trips losslessly (instant equality — see verification.md) | FR-006 | unit | PASSING | `…::edge case — non-UTC timestamp round-trips` |
| U21 | Microsecond precision in `injectedAt` round-trips losslessly | FR-006 | unit | PASSING | `…::edge case — microsecond precision round-trips` |
| U22 | Large `content` (>= 10 KB) round-trips losslessly | FR-006 | unit | PASSING | `…::edge case — large content round-trips` |

### toString pin (FR-007)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U23 | `toString()` returns a string containing the type name `SteeringMessage` and the `id` field; content longer than 40 chars is truncated | FR-007 | unit | PASSING | `…::toString — includes type name and id; long content truncated` |

## Edge cases & invariants

- Identity equality (`identical(a, a)`) short-circuits to `true`
  even when fields are equal — already in the implementation; pinned
  by U16.
- `hashCode` agreement is the only contractually-required property;
  unequal messages MAY collide but the test asserts the equal-case
  agreement only (U15).
- `fromJson` accepts a JSON map whose top-level keys include extras
  beyond `id`, `content`, `injectedAt` (e.g. a version tag) — extras
  are ignored, not errors. This is the existing behavior; not pinned
  by a dedicated test (low risk; documented here).
- The `SteeringQueue`'s FIFO behavior and the `SteeringInjected`
  event are out of scope — they have their own test files.

## Out of scope

- The `SteeringQueue` itself (spec 033) — already has its own test
  file at `test/domain/entities/steering_queue/steering_queue_test.dart`.
- The `SteeringInjected` engine event (PR #19).
- Multimodal content (R2 concern — steering is text-only for now;
  documented in the value object's `content` field doc comment).
- Backward compatibility with a previous JSON shape — this is the
  only published JSON shape for `SteeringMessage`.

## Verification commands

- Single test: `dart test test/domain/entities/steering_message/steering_message_test.dart -N 'spec 081 — SteeringMessage'`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos test/domain/entities/steering_message/steering_message_test.dart lib/src/domain/entities/steering_message/steering_message.dart`
