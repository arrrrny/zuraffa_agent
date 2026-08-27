# Implementation Plan: ToolResult value object + clean-arch layers

**Branch**: `feat/specs-025-027-029-031` (spec dir: `031-tool-result-value-object`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/031-tool-result-value-object/spec.md`

## Summary

Complete the value-object semantics the task names: add the `isError` discriminator with `success`/`error` factories, add JSON round-trip serialization (`toJson`/`fromJson` with nested artifactRef), add the oversized-result path (`ToolResult.oversized` requiring summary + artifactRef), and fix the scaffolded `hashCode` contract violation (payload excluded from hashing while participating in equality — distinct-but-equal map instances hash differently under Dart's identity-based map hashing). The service/provider layers keep their signatures and stubs (compile parity pinned).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`/`NoParams`), `test` ^1.25.0. ArtifactRef (existing entity) provides kind/id/uri.

**Storage**: N/A — value object; serialization shape matches what a store/event-stream would persist.

**Testing**: `dart test`; single test via `--plain-name`; gates per `.specify/memory/tdd-profile.md` (`dart analyze` 5-issue pre-existing baseline, zero new).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: hashCode computed in O(payload size) with no allocation beyond the fold; serialization is a single pass.

**Constraints**: No `id` field ever (issue #31's whole point); plain Dart value object (no codegen); existing constructor signature `ToolResult({required content, structuredPayload, artifactRef})` stays (additive `isError` param with default); provider/service signatures unchanged.

**Scale/Scope**: 1 lib file enriched + 1 test file rewritten (7 existing tests kept passing, ~14 new) ≈ 21 tests.

## Constitution Check

*No `.specify/memory/constitution.md`; repo AGENTS.md rules apply. Hand-curated banner kept with issue #31 reference. Passed.*

## Project Structure

### Documentation (this feature)

```text
specs/031-tool-result-value-object/
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
lib/src/domain/entities/tool_result/tool_result.dart        # isError + factories + toJson/fromJson + oversized + hashCode fix
test/domain/entities/tool_result/tool_result_test.dart      # NEW: value-object semantics (the task's deliverable)
test/data/providers/tool_result/tool_result_provider_test.dart  # existing: compile parity + stubs keep passing
```

## Architecture / Data Flow

```text
engine dispatch
   │ ToolResult.success / .error / .oversized
   ▼
ToolResult (value object)
   · content / structuredPayload / artifactRef / isError   # fields (no id — issue #31)
   · isSummarized => artifactRef != null                   # spec-003 §4.3 discipline
   · toJson/fromJson                                       # wire/session boundary
   · == (content, payload deep-eq, isError, artifactRef)
   · hashCode consistent with == (order-independent payload fold)  # scaffold bug fixed
   ▼
ToolResultService <- ToolResultProvider (unchanged stubs, compile parity)
```

Key decisions:

1. **`isError` additive, default false** — the existing unnamed constructor keeps compiling; equality/hashCode/serialization all include it. Factories `success`/`error` are ergonomic sugar over the same field.
2. **Order-independent payload hashing** — fold `Object.hash(key, value)` over entries and combine with `Object.hash(content, isError, artifactRef)`; equal maps with different insertion orders or distinct instances hash equally, fixing the scaffold's contract violation (the existing `Object.hash(content, artifactRef)` skips the payload that `==` compares).
3. **Serialization shape** — `{content, structuredPayload?, artifactRef?: {kind, id, uri?}, isError}` matching ArtifactRef's generated JSON shape; null payload and null ref are omitted/nullable so round-trips don't fabricate empty structures (AC US1-3).
4. **`ToolResult.oversized(summary, artifactRef, {structuredPayload, isError})`** — the spec-003 §4.3 path: requires both summary content and ref; `isSummarized` stays derived.
5. **Layers untouched behaviorally** — FR-007: the provider's UnimplementedError stubs are the current contract; only the value object's semantics ship in this feature.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 7 existing tests.** The existing test file constructs `ToolResult(content:..., structuredPayload:..., artifactRef:...)` — the additive defaulted `isError` keeps those compiling and passing; equality additions (`isError`) don't affect cases where both sides default false. The existing hashCode test doesn't exist (only equality) — the new contract is strictly stronger.
- **Risk: hashCode/equality contract on maps.** Dart maps use identity hashing; the fold over entries must be order-independent (sorted or commutative combine — `Object.hash` combine via fold is order-DEPENDENT, so fold over `entries` sorted by key, or use a commutative combiner like XOR/sum of per-entry hashes). Chosen: sum of `Object.hash(key, value)` per entry — commutative, order-independent.
- **Risk: fromJson type coercion.** Payload arrives as `Map<String, dynamic>` from jsonDecode; cast defensively, treat non-map payload as error (ArgumentError) rather than silent null.
- **Risk: oversized error bodies.** Allowed by design (edge-5) — `oversized` takes `isError` too.

## Implementation Phases

Phase 1 — isError + factories + equality/hashCode fix (test-first: the hashCode contract red is the scaffold's live bug).
Phase 2 — serialization round-trip (test-first).
Phase 3 — oversized path (test-first).
Phase 4 — Gates: full suite + analyze; existing provider tests untouched and passing.

All behavioral phases run through the TDD loop with recorded red evidence.
