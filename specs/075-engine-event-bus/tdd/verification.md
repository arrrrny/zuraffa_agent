# Verification: Engine event bus

---
feature: 075-engine-event-bus
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-075-engine-event-bus (off master fec7889)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 923 passed / 0 failed / 2 skipped (baseline 915/2 at fec7889, +8 new)"
---

## Cycle integrity

- **RED (genuine)**: `test/engine/engine_event_bus_test.dart` written
  first and run against a missing library — `Error when reading
  'lib/src/engine/engine_event_bus.dart': No such file or directory`,
  then `EngineEventBus` undefined, exit 1.
- **GREEN**: implementation landed; file +8. One analyze info during
  GREEN (`unnecessary_underscores` on a test lambda parameter; also one
  `prefer_final_locals` fixed in the same pass) — test-only fixes.
- **M2 SURVIVOR → strengthened test → killed** (the cycle's main event,
  Finding #1): the original test suite could NOT kill the type-filter
  mutant because the erasing invoker's `handler(event as T)` cast threw
  for non-matching events inside the isolation try/catch — the cast was
  acting as a secondary type guard, so observable behavior was nearly
  identical. The strengthened test pins the filter as behavior: the
  error hook must stay silent on non-matching publishes. M2 then died
  (+7 −1).
- All other mutants cp-restored and re-verified green before the next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/engine/engine_event_bus_test.dart) | Result |
| --- | --- | --- |
| FR-001 typed subscription + wildcard | `typed subscriptions filter by exact runtime type` | PASS |
| FR-002 sync publish, registration order, fan-out | `delivery follows registration order`; `one publish fans out to many subscribers`; `onEvent bridge…` | PASS |
| FR-003 error isolation + hook | `a throwing subscriber never breaks delivery` (both hooked and hook-less buses) | PASS |
| FR-004 cancel semantics | `cancel stops delivery and frees the slot` | PASS |
| FR-005 replay broadcast | `replay broadcasts history to current subscribers` (incl. EngineEventLog-shaped Iterable composition) | PASS |
| FR-006 subscriberCount | `subscriberCount tracks live subscriptions` | PASS |
| FR-007 gates | analyze clean; 923/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | publish delivers to the FIRST matching subscriber only | **KILLED** | +2 −6: fan-out, order, cancel-count, replay, bridge tests all starve |
| M2 | type filter dropped (every subscriber invoked for every event) | **SURVIVED → KILLED** | Original run: +8 −0 (all passed — cast-as-guard absorbed it). After strengthening the typed test (error hook must stay silent on non-matching publishes): +7 −1 (`Expected: <0>` hook fires with cast TypeErrors) |
| M3 | replay iterates the history reversed | **KILLED** | +7 −1: `Expected: ['t1','t2','t3']` |
| M4 | isolation removed — subscriber exceptions propagate | **KILLED** | +7 −1: isolation test fails (publish throws / second subscriber starves) |
| M5 | cancel deactivates the handle but never the entry | **KILLED** | +6 −2: delivery continues after cancel; subscriberCount never drops |

**5/5 killed** (M2 after the documented test strengthening).

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **923 passed / 0 failed / 2 skipped** (2 pre-existing KIMI_API_KEY skips, unrelated)

## Findings

1. **M2 survivor — the cast was a shadow type guard (design insight,
   fixed in-cycle).** The erasing invoker `(e) => handler(e as T)`
   enforced the type by throwing inside the isolation catch, making the
   explicit filter observationally redundant EXCEPT through the error
   hook. The strengthened test now pins: non-matching publishes are
   FILTERED before the handler and the hook stays silent. This is
   exactly what mutation testing is for — the original suite had a real
   gap (a misbehaving filter would have spammed onSubscriberError with
   TypeErrors in production).
2. **013 draft deviations documented, not silently dropped**: the
   draft's request/response (FR-002) and AgentController (FR-004) are
   deferred — their event types (BeforeToolCallRequest & co.) don't
   exist in this repo and the sealed union grows only from its own
   spec. FR-005's "engine emits through the bus" is satisfied by the
   bridge pattern (`onEvent: bus.publish`), proven by the A4 test —
   no engine change needed.
3. **No dynamic dispatch**: handler invocation goes through a typed
   erasing closure built at subscribe time; there is no `dynamic` call
   anywhere in the bus.

## Verdict

**PASS** — FR-001..FR-007 all traced to passing tests; 5/5 deliberate
mutants killed (one via honest survivor→strengthen→kill journey); both
gates clean at branch HEAD; genuine RED first.
