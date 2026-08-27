# Implementation Plan: AgentSession root entity — aggregate transitions + persistence contract

**Branch**: `feat/specs-032-033-034-035` (spec dir: `032-agent-session-root`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/032-agent-session-root/spec.md`

## Summary

Complete the session-root aggregate behavior the task names: add the pure cursor transition `appendEntry` (advance `currentEntryId`, stamp `updatedAt`, immutable snapshot), add the branch transition `fork` (child session linked via `parentSessionId` at the current head, root anchor fallback for fresh sessions), and add the persistence contract (`toJson`/`fromJson` round-tripping all seven fields with absent-never-fabricated optionals and typed `ArgumentError`s on malformed input). The service/provider layers keep their signatures and stubs (compile parity pinned by the 8 existing tests).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`/`NoParams` for the service surface), `test` ^1.25.0. No new dependencies.

**Storage**: N/A in this feature — the value object defines the JSON contract the existing stores (`jsonl_session_storage.dart`, `hive_session_store.dart`) will consume when their specs land; this feature does not rewire them.

**Testing**: `dart test`; single test via `dart test <file> -n "<name>"`; gates per `.specify/memory/tdd-profile.md` (`dart analyze --fatal-infos` clean — current baseline 0 issues after 9d8b5bd; full suite 597 passed).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: transitions allocate one snapshot; `toJson` is a single pass; no O(n) work anywhere (the root holds ids only).

**Constraints**: Hand-curated plain Dart value object (no `@Zorphy` codegen — established pattern for this entity family; constitution IX exception documented in the file header). No `dart:io` (constitution VII). Existing constructor signature unchanged; all additions additive.

**Scale/Scope**: 1 lib file enriched + 1 new test file (~16 tests) + spec/plan/tasks/tdd artifacts.

## Constitution Check

`.specify/memory/constitution.md` read. IX (Zorphy model layer): this entity family ships as HAND-CURATED plain Dart by explicit repo precedent (header comment: "Declared as a plain Dart value object (no @Zorphy annotation)... until then it is the canonical source for the AgentSession surface") — the refinement stays inside that documented exception. VII (engine purity): no dart:io anywhere in the new code. X (pristine analysis): gate is `dart analyze --fatal-infos` zero findings. Passed.

## Project Structure

### Documentation (this feature)

```text
specs/032-agent-session-root/
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
lib/src/domain/entities/agent_session/agent_session.dart          # + appendEntry/fork/toJson/fromJson
test/domain/entities/agent_session/agent_session_test.dart        # NEW: aggregate semantics (the deliverable)
test/data/providers/agent_session/agent_session_provider_test.dart # existing: compile parity + stubs keep passing
```

## Architecture / Data Flow

```text
engine loop (spec 002 territory)          mission fork (R2.2)
   │ appendEntry(entryId, at)                │ fork(sessionId, at)
   ▼                                         ▼
AgentSession (immutable root snapshot)
   · id / missionId? / rootEntryId           # identity + tree anchor
   · currentEntryId?  ← cursor               # advanced by appendEntry only
   · parentSessionId? ← branch link          # set by fork only
   · createdAt / updatedAt                   # updatedAt stamped per transition
   · isBranch / isHead                       # derived reads (existing)
   · toJson/fromJson                         # persistence contract (FR-004)
   ▼
AgentSessionService <- AgentSessionProvider (unchanged stubs, compile parity)
   ▼
(existing) jsonl_session_storage / hive_session_store   # consumers, NOT rewired
```

Key decisions:

1. **Pure snapshot transitions** — `appendEntry`/`fork` return new instances, mirroring CircuitBreaker's `recordFailure`/`recordSuccess`/`tryHalfOpen` (the repo's established transition style). No shared mutable state, no timers, no I/O.
2. **Fork-point fallback** — `currentEntryId ?? rootEntryId`: a fresh session forks at its root anchor so the child is never born cursor-null pointing nowhere (AC US2-2); a headed session forks at its head (AC US2-1).
3. **JSON shape** — `{id, missionId?, rootEntryId, currentEntryId?, parentSessionId?, createdAt, updatedAt}` camelCase, matching the spec-031 ToolResult precedent; nulls omitted; timestamps ISO-8601.
4. **Typed parse failures** — `fromJson` throws `ArgumentError` naming the offending key; never fabricates defaults (dispatch-safety discipline shared with 031).
5. **Layers untouched behaviorally** — FR-005: the provider's UnimplementedError stubs are the current contract.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 8 existing tests.** All additions are additive methods; the unnamed constructor, fields, `==`, `hashCode`, `isBranch`, `isHead` are untouched — the existing tests keep compiling and passing (verified in the green run).
- **Risk: fork semantics guessing.** The scaffold docs describe `parentSessionId` ("non-null when this session is a fork/branch of another") and the cursor ("mutable, points at the head the engine is appending to") but no fork mechanics; pi_agent's session tree forks at the current head. The fallback rule (`?? rootEntryId`) covers the only undefined case (fresh session) and is documented as an assumption.
- **Risk: timestamp zone drift.** `DateTime.parse` of an ISO string ending in `Z` yields UTC; tests use `DateTime.utc` values so round-trips are exact. Non-UTC values normalize to UTC — documented in spec Assumptions.
- **Risk: `fromJson` type coercion.** Values from `jsonDecode` are dynamic; each required key is checked for presence AND type with a named `ArgumentError` (no silent `as String` crash with an unhelpful cast error).

## Implementation Phases

Phase 1 — cursor transition `appendEntry` (test-first: AC US1-1..3).
Phase 2 — branch transition `fork` (test-first: AC US2-1..3).
Phase 3 — persistence contract `toJson`/`fromJson` (test-first: AC US3-1..3).
Phase 4 — Gates: full suite + analyze; existing provider tests untouched and passing; mutation spot-checks.

All behavioral phases run through the TDD loop with recorded red evidence.
