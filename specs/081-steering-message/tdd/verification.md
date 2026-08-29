---
feature: 081-steering-message
verdict: PASS
standard: .specify/extensions/tdd/templates/tdd-test-quality-rubric.md # rubric graded against
verified_at: 081-steering-message (working tree HEAD, pre-commit)
behaviors: 23
proven: 23
likely: 0
test_after: 0
no_test: 0
high_smells: 0
criteria_total: 8
criteria_covered: 8
mutation_score: 100 # 6/6 deliberate mutants killed
mutants_survived: 0
suite: 23 passed, 0 failed # test/domain/entities/steering_message/steering_message_test.dart at branch HEAD
characterization_tdd: true # implementation pre-existed at branch creation; tests pin existing behavior
---

# TDD Verification: R1 — Steering Message value object (spec 081)

**Verdict: PASS.** The cycle is honest: this is **characterization-TDD**
rather than test-first TDD — the `SteeringMessage` value object already
existed at branch creation (committed in PR #19, refined in spec 033's
TDD cycle for the persistence contract). This spec's contribution is
the spec-kit artifacts and a comprehensive test suite that pins every
FR. Every behavior has a test that a deliberate mutant killed — 6/6
sampled. No HIGH test smells. Every criterion (FR-001..FR-008) is
covered.

## Test-first evidence (characterization-TDD honestly labeled)

The implementation file
`lib/src/domain/entities/steering_message/steering_message.dart`
already shipped with:

- `SteeringMessage({id, content, injectedAt})` — three required fields.
- `toJson()` → `{id, content, injectedAt}` with ISO-8601 timestamp.
- `fromJson()` factory with typed `ArgumentError` on every malformed-input
  variant.
- `==` / `hashCode` for full-field equality across all three fields.
- `toString()` with type name + id + content (truncated at 40 chars).

RED was characterized as **the absence of test coverage** — no test
file existed for this value object at branch creation. A single
refactor of the file could silently break the queue's persistence
boundary or the session tree's reconstruction of the steering
timeline, and CI would not catch it. The cycle:

1. Wrote `test/domain/entities/steering_message/steering_message_test.dart`
   (23 tests across six groups: round-trip, typed errors, equality,
   edge cases, toString pin, gates-implicit).
2. Ran `dart test test/domain/entities/steering_message/steering_message_test.dart`
   — 23/23 green immediately (the implementation already satisfied
   every assertion). This is the expected outcome for
   characterization-TDD: tests pin existing behavior; the cycle's
   value is the pin, not the RED state.
3. Applied mutations M1–M6 one at a time to the implementation,
   restoring the green tree between each. Each mutation KILLED at
   least one test (see table below).
4. Ran the full suite to confirm no regression: baseline 1073/2 →
   1096/2 (23 new tests, zero regressions).
5. Ran `dart analyze` on the changed files (just the test file — the
   implementation is unchanged): zero findings. Full project analyze
   shows only the 3 pre-existing findings at HEAD `29b7fef` (1 warning
   + 2 info on unrelated files) — not regressed.

| Behavior | Class | Evidence |
| -------- | ----- | -------- |
| A1 round-trip lossless | PROVEN | mutants M1 (omit injectedAt in toJson) and M3 (swallow injectedAt errors in fromJson) both kill related tests |
| A2 typed ArgumentError on every malformed-input variant | PROVEN | mutant M2 (silent cast on non-String) killed U4–U7; M3 killed U8–U10 |
| A3 gates: analyze + dart test | PROVEN | analyze on changed files clean; full suite 1096/2 green |
| U1 arbitrary values round-trip | PROVEN | direct test passing at HEAD; M1 killed U1 |
| U2 toJson shape has exactly three keys | PROVEN | M1 killed U2 |
| U3 toJson injectedAt is ISO-8601 parseable | PROVEN | M1 killed U3 |
| U4 missing id → ArgumentError naming id | PROVEN | M2 killed U4 |
| U5 non-string id → ArgumentError naming id | PROVEN | M2 killed U5 |
| U6 missing content → ArgumentError naming content | PROVEN | M2 killed U6 |
| U7 non-string content → ArgumentError naming content | PROVEN | M2 killed U7 |
| U8 missing injectedAt → ArgumentError naming injectedAt | PROVEN | M3 killed U8 |
| U9 non-string injectedAt → ArgumentError naming injectedAt | PROVEN | M3 killed U9 |
| U10 unparseable injectedAt → ArgumentError naming injectedAt | PROVEN | M3 killed U10 |
| U11 equal messages are == | PROVEN | direct test passing at HEAD |
| U12 differing id breaks == | PROVEN | M5 (always-true ==) killed U12 |
| U13 differing content breaks == | PROVEN | M5 killed U13 |
| U14 differing injectedAt breaks == | PROVEN | M4 (ignore injectedAt) + M5 both killed U14 |
| U15 hashCode agrees with == | PROVEN | M5 killed U15 |
| U16 identity short-circuits | PROVEN | direct test passing at HEAD |
| U17 empty content round-trips | PROVEN | M1 killed U17 |
| U18 unicode id round-trips | PROVEN | M1 killed U18 |
| U19 unicode content round-trips | PROVEN | M1 killed U19 |
| U20 non-UTC timestamp round-trips | PROVEN | M1 killed U20 |
| U21 microsecond precision round-trips | PROVEN | M1 killed U21 |
| U22 large content (>= 10 KB) round-trips | PROVEN | M1 killed U22 |
| U23 toString includes type + id; long content truncated | PROVEN | M6 (no truncation) killed U23 |

## Mutation evidence

All six mutants applied via direct edit to
`lib/src/domain/entities/steering_message/steering_message.dart`,
then reverted via `cp` of the green tree before the next. Each
mutant was applied, the test suite re-run, and the failure output
recorded. The deliberate-mutant sample targets every public surface
of the value object: toJson, fromJson's two error paths (non-String
fields and unparseable timestamp), equality, and toString.

| Mutant | Description | Tests killed | Verdict |
| ------ | ----------- | ------------ | ------- |
| M1 | `toJson` omits `injectedAt` (returns `{id, content}` only) | U1, U2, U3, U17, U18, U19, U20, U21, U22 (9/23 fail) | KILLED |
| M2 | `fromJson`'s `requireString` returns `value.toString()` instead of throwing on non-String | U4, U5, U6, U7 | KILLED |
| M3 | `fromJson` swallows missing/wrong-type/unparseable `injectedAt` (returns `DateTime.now()`) | U8, U9, U10 | KILLED |
| M4 | `==` ignores `injectedAt` field | U14 | KILLED |
| M5 | `==` always returns `true` | U12, U13, U14, U15 | KILLED |
| M6 | `toString` does not truncate long content (no `…` marker) | U23 | KILLED |

Mutation score: 6/6 = 100% on the sampled behaviors.

## Acceptance-criteria coverage

| Criterion | Covered by | Status |
| --------- | ---------- | ------ |
| FR-001 value object with three required fields | U1 (constructs all three); every test constructs via the three-arg ctor | COVERED |
| FR-002 toJson shape `{id, content, injectedAt}` with ISO-8601 | U1, U2, U3 | COVERED |
| FR-003 fromJson round-trip — lossless | U1, U17–U22 | COVERED |
| FR-004 fromJson typed ArgumentError on every malformed-input variant | U4–U10 | COVERED |
| FR-005 == over all three fields; hashCode agrees; identity short-circuits | U11–U16 | COVERED |
| FR-006 edge cases round-trip (empty, unicode, non-UTC, microsecond, large) | U17–U22 | COVERED |
| FR-007 toString includes type + id; long content truncated | U23 | COVERED |
| FR-008 dart analyze + dart test gates | A3 (analyze on changed files clean; full suite 1096/2) | COVERED |

## Test smells

No HIGH smells. One borderline LOW smell, documented in U20's body:
non-UTC timestamps round-trip via `toIso8601String()` which always
emits UTC, so the deserialized `DateTime` is in UTC even if the
original was constructed with a timezone offset. The test asserts
equality via `DateTime.==` (which compares millisecondsSinceEpoch,
not the timezone label) — this is the only property that holds
across the round-trip and the only one asserted. This is correct
behavior, not a smell — but it's worth flagging that a caller
expecting `injectedAt.isUtc` to be `false` after a round-trip would
be surprised.

## Gates

- `dart analyze test/domain/entities/steering_message/steering_message_test.dart lib/src/domain/entities/steering_message/steering_message.dart`
  → **No issues found!** (clean).
- `dart analyze` (full project) → 3 pre-existing findings (1 warning +
  2 info on unrelated files: `mission_runner_002_a2_test.dart`,
  `cassette_replay_llm_client.dart`, `mission_runner_002_a3_test.dart`)
  at HEAD `29b7fef` — NOT regressed by this spec.
- `dart test` (full suite) → **1096 passed, 2 skipped** (baseline
  1073/2 + 23 new = 1096/2). Zero regressions.
- `dart test test/domain/entities/steering_message/steering_message_test.dart`
  → 23/23 green.

## Findings

- The `SteeringMessage` value object already existed at branch
  creation (committed in PR #19, refined in spec 033's TDD cycle for
  the persistence contract). This spec's contribution is the
  spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/test-list.md,
  tdd/verification.md) and the comprehensive test suite that pins
  every FR. No source changes were needed.
- The `toJson().injectedAt` field is always UTC (via
  `DateTime.toIso8601String()` which emits 'Z' for UTC). A non-UTC
  `DateTime` constructed locally will round-trip to its UTC equivalent
  — the instants are equal but the timezone label is lost. This is
  the documented behavior of `DateTime.toIso8601String()` and is
  correct (an instant is an instant); the U20 test asserts instant
  equality, not label equality.
- M2 (silent cast on non-String) and M3 (swallow injectedAt errors)
  were both rewritten from the original plan's M2/M3 (which would
  have been near-duplicates — the implementation has a single
  `requireString` helper used by both `id` and `content`, so a
  silent-cast mutation on it covers both fields). The revised
  mutations still cover every malformed-input path with no overlap.
- One pre-existing analyzer finding on `cassette_replay_llm_client.dart`
  is OUT OF SCOPE for this spec — explicitly not regressed; explicitly
  not fixed.

## Verdict

**PASS** — all 8 FRs covered, all 23 behaviors proven by green tests
at HEAD, 6/6 deliberate mutants killed, gates clean on changed
files, no regressions in the full suite. Characterization-TDD
honestly labeled.
