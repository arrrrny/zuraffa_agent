# Implementation Plan: R1 — Steering Message value object (spec 081)

## Approach

The implementation already exists and is spec-exact. This plan's
contribution is a comprehensive test suite that pins every FR and
a set of mutations to prove the pins hold. No source changes are
needed; the test file is the only code artifact.

The cycle is **characterization-TDD** rather than test-first TDD:
the code exists at branch creation, so RED is the absence of tests
(no coverage pinning the contract). Tests are written to fail IF
the implementation regressed (a deliberate mutant applied to the
implementation must kill at least one test).

## Components

### 1. Test file (`test/domain/entities/steering_message/steering_message_test.dart`)

Lives in the conventional `test/domain/entities/<entity>/` mirror
of `lib/src/domain/entities/<entity>/`, matching the existing
`steering_queue/steering_queue_test.dart` pattern. Six groups,
mirroring the four user stories + the toString pin + the gate:

**Group A — round-trip (US1 / FR-002 / FR-003)**:
- T1: arbitrary id + content + UTC timestamp → `toJson` → `fromJson` → equals original.
- T2: `toJson` shape — exactly three keys `id`, `content`, `injectedAt`; no extras, no omissions.
- T3: `toJson`'s `injectedAt` is an ISO-8601 string (parseable by `DateTime.parse`).

**Group B — typed ArgumentError on malformed input (US2 / FR-004)**:
- T4: missing `id` → `ArgumentError` with `.name = 'id'`.
- T5: `id` is not a String (e.g. an int) → `ArgumentError` with `.name = 'id'`.
- T6: missing `content` → `ArgumentError` with `.name = 'content'`.
- T7: `content` is not a String → `ArgumentError` with `.name = 'content'`.
- T8: missing `injectedAt` → `ArgumentError` with `.name = 'injectedAt'`.
- T9: `injectedAt` is not a String → `ArgumentError` with `.name = 'injectedAt'`.
- T10: `injectedAt` is a String but unparseable → `ArgumentError` with `.name = 'injectedAt'`.

**Group C — equality (US3 / FR-005)**:
- T11: two messages with the same id+content+timestamp compare `==`.
- T12: differing `id` breaks `==`.
- T13: differing `content` breaks `==`.
- T14: differing `injectedAt` breaks `==`.
- T15: `hashCode` agrees with `==` for both equal and unequal cases.
- T16: identity equality — `msg == msg` is `true` (same instance).

**Group D — edge cases (US4 / FR-006)**:
- T17: empty `content` round-trips.
- T18: unicode in `id` (Chinese, emoji) round-trips.
- T19: unicode in `content` (Chinese, emoji, RTL text) round-trips.
- T20: non-UTC `injectedAt` (with explicit timezone offset) round-trips.
- T21: microsecond precision in `injectedAt` round-trips.
- T22: large `content` (>= 10 KB) round-trips.

**Group E — toString pin (FR-007)**:
- T23: `toString()` returns a string containing the type name `SteeringMessage` and the `id` field; long content is truncated.

**Group F — gate**:
- T24: `dart analyze` on the test file is clean; `dart test` runs green.

### 2. Mutations (M1–M6, one at a time, cp-restored)

Mutants are applied to `lib/src/domain/entities/steering_message/steering_message.dart`,
the test suite re-run, and the failure output recorded. The mutant
must kill at least one test:

- **M1**: `toJson` omits `injectedAt` (guards T1, T2, T3).
- **M2**: `fromJson` accepts a non-String `id` (silent cast) (guards T5).
- **M3**: `fromJson` accepts a non-String `content` (guards T7).
- **M4**: `fromJson` swallows unparseable `injectedAt` and returns `DateTime.now()` (guards T10).
- **M5**: `==` ignores `injectedAt` (guards T14, T15).
- **M6**: `==` always returns `true` (guards T12, T13, T14, T15, T16).

## Sequencing

1. RED — write `test/domain/entities/steering_message/steering_message_test.dart`
   (24 tests across six groups). Because the implementation already
   exists at branch creation, RED is characterized as "no test
   coverage exists" — the first run of the test file should pass
   (GREEN immediately). This is documented in `tdd/verification.md`
   as characterization-TDD rather than test-first TDD.
2. GREEN — confirm 24/24 green at branch HEAD.
3. MUTATIONS — M1–M6, one at a time, `cp`-restored between runs.
   Each must KILL (i.e. at least one test fails when the mutant is
   applied; the test passes again when the mutant is retracted).
4. GATES — `dart analyze --fatal-infos` exit 0 on the changed files;
   full `dart test` green (baseline + 24 new).
5. ARTIFACTS — `tdd/verification.md` records the cycle integrity,
   mutation evidence verbatim, the FR table, and the verdict.
6. COMMIT (spec.md + plan.md + tasks.md + tdd/test-list.md +
   tdd/verification.md + the new test file) and open PR with base
   `master` titled `feat(081): steering message value object — JSON
   contract & equality` closing #92.
