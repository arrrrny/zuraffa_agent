# Implementation Plan: SteeringQueue + SteeringMessage — enqueue/dispatch/inject semantics

**Branch**: `feat/specs-032-033-034-035` (spec dir: `033-steering-queue`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/033-steering-queue/spec.md`

## Summary

Complete the queue semantics the task names: add the pure `enqueue` transition (FIFO append + `lastInjectedAt` stamp, immutable snapshot), add the `pop` dispatch transition (Dart 3 record `({message, queue})`, `processedCount` increment, `StateError` on empty), close the defensive-immutability gap (the scaffold stores the caller's list reference — constructor defensively copies into an unmodifiable list), and add the persistence contract (`toJson`/`fromJson` on both the queue and the message). The service/provider layers keep their signatures and stubs (compile parity pinned by the 9 existing tests).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK; Dart 3 records available for `pop()`.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`/`NoParams` for the service surface), `test` ^1.25.0. No new dependencies.

**Storage**: N/A in this feature — the value objects define the JSON contract a between-turns store consumes; the existing stores are not rewired.

**Testing**: `dart test`; single test via `dart test <file> -n "<name>"`; gates per `.specify/memory/tdd-profile.md` (`dart analyze --fatal-infos` clean; full suite post-032 baseline 611 passed).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: `enqueue`/`pop` allocate one snapshot + one list each (O(n) copy is inherent to snapshot semantics, n = pending depth); `toJson` is a single pass; no shared mutable state.

**Constraints**: Hand-curated plain Dart value objects (no `@Zorphy` codegen — established pattern for this entity family). No `dart:io` (constitution VII). Existing constructor signature and equality semantics unchanged; all additions additive (the constructor body change for the defensive copy keeps the signature).

**Scale/Scope**: 2 lib files enriched (SteeringMessage, SteeringQueue) + 1 new test file (~16 tests) + spec/plan/tasks/tdd artifacts.

## Constitution Check

`.specify/memory/constitution.md` read. IX (Zorphy model layer): this entity family ships as HAND-CURATED plain Dart by explicit repo precedent (header: "Pattern: plain Dart value object (no @Zorphy annotation)... same as AgentSession (PR #50)") — the refinement stays inside that documented exception. VII (engine purity): no dart:io. X (pristine analysis): gate is `dart analyze --fatal-infos` zero findings. Passed.

## Project Structure

### Documentation (this feature)

```text
specs/033-steering-queue/
├── spec.md            # refined via /speckit.specify
├── plan.md            # this file
├── tasks.md           # /speckit.tasks output
└── tdd/
    ├── test-list.md
    ├── cycle-log.md
    └── verification.md
```

### Source Code (repository root)

```text
lib/src/domain/entities/steering_message/steering_message.dart   # + toJson/fromJson
lib/src/domain/entities/steering_queue/steering_queue.dart        # + enqueue/pop/toJson/fromJson + defensive copy
test/domain/entities/steering_queue/steering_queue_test.dart      # NEW: queue semantics (the deliverable)
test/data/providers/steering_queue/steering_queue_provider_test.dart # existing: compile parity + stubs keep passing
```

## Architecture / Data Flow

```text
mid-turn user input                    engine loop between turns (spec 002)
   │ enqueue(message)                    │ pop() → ({message, queue})
   ▼                                     ▼
SteeringQueue (immutable snapshot)
   · id                                     # per-mission queue identity
   · pending (unmodifiable, FIFO)           # head at index 0
   · processedCount                         # +1 per pop (drain ledger)
   · lastInjectedAt                         # stamped by enqueue
   · enqueue → new snapshot (append + stamp)
   · pop → ({message, queue}) new snapshot  # head out, count up, StateError on empty
   · toJson/fromJson                        # persistence contract (FR-004)
   ▼
SteeringInjected (engine event, NOT modified) — carries the popped message's content/injectedAt
   ▼
SteeringQueueService <- SteeringQueueProvider (unchanged stubs, compile parity)
```

Key decisions:

1. **Pure snapshot transitions** — `enqueue`/`pop` return new instances (CircuitBreaker / AgentSession precedent). `pop` returns a Dart 3 record `({SteeringMessage message, SteeringQueue queue})` — no wrapper class.
2. **Defensive immutability (FR-001)** — constructor stores `List.unmodifiable(pending)`: the scaffold's "immutable snapshot" doc claim becomes load-bearing. Equality stays deep over pending (unchanged `_listEq`).
3. **`StateError` for empty pop** — the empty-pop is a usage error (the engine consults `isEmpty` first), not an argument error; `StateError` with the queue id in the message.
4. **JSON shape** — queue: `{id, pending: [{id, content, injectedAt}...], processedCount, lastInjectedAt?}`; message: `{id, content, injectedAt}`; camelCase, nulls omitted, ISO-8601 timestamps — the spec-031/032 house shape.
5. **Layers untouched behaviorally** — FR-006: the provider's UnimplementedError stubs are the current contract.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 9 existing tests.** The existing tests construct `SteeringQueue(pending: [m1, m2], ...)` and read `pending`, `head`, `isEmpty`, `pendingCount`, equality — all preserved. The defensive copy changes only the stored list's identity/modifiability, not its contents; `equals(b.pending, [m1, m2])` still holds. Verified in the green run.
- **Risk: const constructor lost.** `List.unmodifiable` is not const, so the constructor can no longer be `const`. No existing call site uses `const SteeringQueue(...)` (verified by grep); the 9 tests construct non-const. `SteeringMessage` keeps its const constructor.
- **Risk: record return type on pop.** Records need sdk ≥3.0 — satisfied (^3.8.0). Test destructuring reads clearly.
- **Risk: fromJson nested shapes.** `pending` entries must each be a map; any non-map entry or ill-typed field throws `ArgumentError` naming the path (typed failures, never silent skips).
- **Risk: enqueue stamp semantics.** `lastInjectedAt = message.injectedAt` (the message's own injection time) rather than a separate clock — the queue records when the message was injected, which IS the message's `injectedAt`. Documented in FR-002.

## Implementation Phases

Phase 1 — defensive immutability + enqueue (test-first: AC US1-1..3, edge-2/3).
Phase 2 — pop dispatch transition (test-first: AC US2-1..3).
Phase 3 — persistence contract on both value objects (test-first: AC US3-1..3).
Phase 4 — Gates: full suite + analyze; existing provider tests untouched and passing; mutation spot-checks.

All behavioral phases run through the TDD loop with recorded red evidence.
