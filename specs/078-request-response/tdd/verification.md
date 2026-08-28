# Verification: Request/response pattern (spec 078)

---
feature: 078-request-response
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
executed_at: feat/spec-078-request-response (off master 7fa7e82)
gates:
  analyze: "dart analyze --fatal-infos → No issues found! (exit 0)"
  tests: "dart test → 927 passed / 0 failed / 2 skipped (baseline 919/2 at 7fa7e82, +8 new)"
---

## Cycle integrity

- **RED (genuine, new surface)**: `test/events/request_response_test.dart`
  written first and run against master's `AgentController` —
  `Error: The getter 'bus' isn't defined for the type 'AgentController'`,
  `The method 'request' isn't defined`, `The method 'on' isn't defined`;
  compile failure, exit 1. The three members did not exist.
- **GREEN**: the three additive members landed
  (`bus` getter, `on<T>` alias, `request<R>` delegate); target file 8/8
  first full run; `dart analyze` clean throughout.
- **Pins are honest, not theater**: U2–U6 (last-handler-wins, exception
  propagation, no-handler StateError, type honesty, live registration)
  pin behavior that master's A3 cycle shipped UNGUARDED — they pass
  immediately by design (013's own A2 cycle-log precedent), and each is
  justified by a killer mutant below.
- All mutation runs executed in this session with outputs captured
  verbatim; every mutant cp-restored and re-verified 8/8 green before the
  next.

## Acceptance criteria → tests (all FRs traced)

| FR | Test (test/events/request_response_test.dart) | Result |
| --- | --- | --- |
| FR-001 controller.request parity | `controller.request round-trips a typed handler response`; `controller.request behaves identically to bus.request` | PASS |
| FR-002 controller.on alias | `controller.on is an alias for listen` | PASS |
| FR-003 bus getter (transparent wrap) | exercised by every controller test (registration via `controller.bus`) | PASS |
| FR-004 last-registered responds | `the last registered handler responds` | PASS |
| FR-005 exception propagation | `handler exceptions propagate to the requester` | PASS |
| FR-006 no-handler StateError | `request with no handler throws StateError` (+ pre-registration arm of the live-registration test) | PASS |
| FR-007 type honesty | `a wrong response type surfaces as a TypeError` | PASS |
| FR-008 live registration + type independence | `registration is live and types dispatch independently` | PASS |
| FR-009 gates | analyze clean; 927/2 | PASS |

## Mutation results (deliberate, one at a time, cp-restored)

| id | mutant | result | evidence (test file run) |
| -- | ------ | ------ | ------------------------ |
| M1 | `controller.request` throws UnimplementedError instead of delegating | **KILLED** | +6 −2: both controller.request tests fail with `UnimplementedError` |
| M2 | `controller.on` is a no-op (never subscribes) | **KILLED** | +7 −1: alias test `Expected: ['o:x'] Actual: []` — the via-on subscriber hears nothing |
| M3 | bus dispatches to the FIRST-registered handler instead of the last | **KILLED** | +7 −1: override pin `Expected: 'second' Actual: 'first'` |
| M4 | bus swallows handler exceptions (try/catch → `null as R`) | **KILLED** | +7 −1: propagation pin `Expected: throws StateError with message contains 'handler exploded'` — the error never reaches the requester |
| M5 | no-handler `StateError` removed (null-check crash instead) | **KILLED** | +6 −2: `Which: threw _TypeError: Null check operator used on a null value` — both no-handler arms fail (wrong error type, type name lost) |
| M6 | the `as R` response cast erased | **KILLED** (compile-level) | `dart analyze` → `return_of_invalid_type`; test file cannot load (+0 −1). The typed `Future<R>` contract structurally requires the cast; the runtime TypeError for a wrong `R` is separately pinned by U5 — double-guarded |

**6/6 killed.** (M6's kill is at compile time — documented as such; a
runtime-surviving variant of this mutant does not exist because the erased
cast breaks the method's return type.)

## Gates (actual runs at branch HEAD)

- `dart analyze --fatal-infos` → **No issues found!** (exit 0)
- `dart test` → **927 passed / 0 failed / 2 skipped** (2 pre-existing
  KIMI_API_KEY skips, unrelated)

## Findings

1. **The edit is additive-only on a file with direct-to-master history.**
   `lib/src/events/event_bus.dart` carries the A1–A4 cycles committed
   straight to master; this spec's diff is exactly three new members +
   doc refresh (the stale `// Stub: no delivery until implemented.`
   comment from A4's cycle is replaced with real docs). No existing line
   of behavior was rewritten — verified by reading the diff before
   commit.
2. **`bus` getter is a spec'd extension beyond 013's four methods**
   (FR-003). Without it, a default-constructed `AgentController` can
   never acquire a handler — `request()` would be dead surface. The wrap
   must be transparent, not a black box; the extension is documented in
   this spec rather than smuggled in.
3. **Pins preceded guards.** Master shipped `request`/`registerHandler`
   with exactly zero tests for multi-handler dispatch, error
   propagation, the no-handler error, or cast honesty (A3's test covers
   only the happy path). Five of this spec's eight tests exist to make
   already-shipped behavior refactor-safe — the deliberate-mutant runs
   prove each pin actually bites.
4. **013 FR-005 remains deferred, deviation documented** (spec.md): the
   engine's event channel in this repo is the sealed `EngineEvent` union
   (075 `EngineEventBus`, PR #86); wiring the engine onto the generic bus
   would fork the event channel. Recorded as out of scope here.

## Verdict

**PASS.** All 9 FRs traced to passing tests; RED was genuine for the new
surface (three undefined members); 6/6 mutants killed with verbatim
evidence (one compile-level, documented); gates clean at 927/2 (baseline
919/2 + 8).
