# Test List: Request/response pattern (spec 078)

---
feature: 078-request-response
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 9 # FR-001..FR-009 in spec.md
planned_at: master (7fa7e82)
updated_at: feat/spec-078-request-response (all A/U behaviors green, 6/6 mutants killed)
suite_baseline: green # 919 passed / 2 skipped at 7fa7e82 (after 013 A1-A4)
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Request/response round-trip through the controller: handler registered on the wrapped bus, `controller.request` returns the typed modified response | FR-001, FR-003 | example | PASSING | `test/events/request_response_test.dart::spec 078 — request/response::controller.request round-trips a typed handler response` |
| A2  | Controller/bus parity: the same bus + handler answer identically through `EventBus.request` and `AgentController.request` (013 SC-003) | FR-001 | example | PASSING | `…::controller.request behaves identically to bus.request` |
| A3  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 919/2 + new) | FR-009 | gate | PASSING | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `AgentController` (new surface — RED) + `EventBus` (pins)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `controller.on<T>` subscribes exactly like `listen<T>` (alias) | FR-002 | unit | PASSING | `…::controller.on is an alias for listen` |
| U2  | Multiple handlers → the MOST RECENTLY registered responds (override semantics) | FR-004 | pin | PASSING | `…::the last registered handler responds` |
| U3  | A throwing handler's error propagates to the awaiting requester | FR-005 | pin | PASSING | `…::handler exceptions propagate to the requester` |
| U4  | `request` with no registered handler → StateError naming the type | FR-006 | pin | PASSING | `…::request with no handler throws StateError` |
| U5  | Response cast honesty: wrong R → TypeError, never a silent value | FR-007 | pin | PASSING | `…::a wrong response type surfaces as a TypeError` |
| U6  | Late registration serves later requests; distinct request types dispatch independently | FR-008 | pin | PASSING | `…::registration is live and types dispatch independently` |

> **Pin honesty**: U2–U6 pass against current master behavior by design —
> they pin FR-004..FR-008 which A3's cycle shipped unguarded. Each is
> justified by a killer mutant (M3–M6) in verification.md.

## Edge cases & invariants

- Default-constructed controller: handlers register via `controller.bus`
  (the wrap is transparent — FR-003).
- Two request types registered concurrently dispatch to their own
  handlers (no cross-talk).
- Handler registered between two requests serves the second (live
  registration).

## Out of scope

- 013 FR-005 engine-emission wiring (documented deviation — the engine
  channel is the sealed EngineEvent union / 075 EngineEventBus).
- Async/queued dispatch, timeouts, wildcard handlers.
- Changes to `EventBus` internals (pinned as-is; only `AgentController`
  grows).

## Verification commands

- Single test: `dart test {file} -n "{name}"`
- Full suite: `dart test`
- Analyze: `dart analyze --fatal-infos`
