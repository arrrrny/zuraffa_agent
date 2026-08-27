# Implementation Plan: AgentTool entity + RiskTier enum — classification, registry persistence, hash contract

**Branch**: `feat/specs-032-033-034-035` (spec dir: `034-agent-tool-risk-tier`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/034-agent-tool-risk-tier/spec.md`

## Summary

Complete the risk-tier semantics the task names: add `RiskTier.fromString`/`ExecutionMode.fromString` (exact-match parse with typed `ArgumentError` — the classification surface dispatch/approval consumes), add the registry persistence contract (`toJson`/`fromJson` with tier/mode names and deep schema copy), and FIX the scaffold's live `==`/`hashCode` contract violation (verified by probe: equal tools with distinct-but-equal `paramsSchema` instances hash differently because `Object.hash` hashes the Map by identity) with a recursively order-independent hash fold. The service/provider layers keep their signatures and stubs (compile parity pinned by the 10 existing tests).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`/`NoParams` for the service surface), `test` ^1.25.0. No new dependencies.

**Storage**: N/A in this feature — the value object defines the JSON contract the registry's persistence consumes; no store is rewired.

**Testing**: `dart test`; single test via `dart test <file> -n "<name>"` (mind regex-special characters in names — see the 033 cycle-log lesson); gates per `.specify/memory/tdd-profile.md` (`dart analyze --fatal-infos` clean; full suite post-033 baseline 626 passed).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: hashCode computed in O(schema size) with no allocation beyond the fold; serialization is a single pass.

**Constraints**: Hand-curated plain Dart value objects (no `@Zorphy` codegen — established pattern for this entity family). No `dart:io` (constitution VII). Existing constructor signature, equality, and enum surfaces unchanged; all additions additive except the hashCode fix (a correction, not a signature change).

**Scale/Scope**: 1 lib file enriched (AgentTool + both enums) + 1 new test file (~13 tests) + spec/plan/tasks/tdd artifacts.

## Constitution Check

`.specify/memory/constitution.md` read. IX (Zorphy model layer): this entity family ships as HAND-CURATED plain Dart by explicit repo precedent (header: "Pattern: plain Dart value object (no @Zorphy annotation)... same as AgentSession (PR #50)") — the refinement stays inside that documented exception. VII (engine purity): no dart:io. X (pristine analysis): gate is `dart analyze --fatal-infos` zero findings. Passed.

## Project Structure

### Documentation (this feature)

```text
specs/034-agent-tool-risk-tier/
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
lib/src/domain/entities/agent_tool/agent_tool.dart        # + fromString x2, toJson/fromJson, hashCode fix
test/domain/entities/agent_tool/agent_tool_test.dart      # NEW: classification + persistence + hash contract
test/data/providers/agent_tool/agent_tool_provider_test.dart # existing: compile parity + stubs keep passing
```

## Architecture / Data Flow

```text
tool declaration (YAML agent spec / MCP manifest — string tier)
   │ RiskTier.fromString('confirm')            ← typed ArgumentError on unknown
   ▼
AgentTool (declaration value object)
   · id / description                          # registry namespace + model-facing text
   · riskTier (safe|confirm|admin)             # R3.2 dispatch policy
   · executionMode (sequential|parallel)       # R3.1 batch discipline
   · paramsSchema? (JSON Schema, deep map)
   · requiresConfirmation / isAdmin            # dispatch/approval reads (existing)
   · toJson/fromJson                           # registry persistence contract (FR-004)
   · == (deep _mapEq — correct, untouched)
   · hashCode (FIXED: recursive order-independent schema fold)  # FR-006
   ▼
tool registry (registration-time collision rejection — the hash consumer)
   ▼
AgentToolService <- AgentToolProvider (unchanged stubs, compile parity)
```

Key decisions:

1. **Exact-match `fromString` with typed failure** — dispatch safety: an unknown tier must never silently become `safe` (under-classification). Case-significant: `'SAFE'` rejects.
2. **Recursive order-independent hash fold** — spec 031's commutative-sum approach extended over nested maps (`_foldHash`: sum of per-entry `Object.hash(key, foldedValue)`; lists folded entry-wise, order-SENSITIVE — JSON-Schema arrays are ordered). Deep-equal schemas in any map insertion order hash equally.
3. **Equality untouched** — the scaffold's `_mapEq` is correct; only the hash is broken (verified by probe). The fix adds no equality axis; per-axis inequality tests keep passing unchanged.
4. **JSON shape** — `{id, description, riskTier: 'confirm', executionMode: 'parallel', paramsSchema?}` camelCase, tier/mode as names, nulls omitted — the house shape from 031/032/033.
5. **Layers untouched behaviorally** — FR-007: the provider's UnimplementedError stubs are the current contract.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 10 existing tests.** The existing tests exercise the constructor, defaults, enum getters, equality (incl. the deep-schema pair with the SAME map instance — hashes equal by identity), and per-axis inequality with distinct schemas (== false regardless of hash). The hash fix changes no `==` outcome; the equality test's `expect(a.hashCode, b.hashCode)` uses the SAME schema instance for both tools (identity-hashed equally even on the scaffold). Additions are additive. Verified in the green run.
- **Risk: the probe claim.** Experimentally verified 2026-08-27 (probe run recorded in the cycle log): `a == b` → true; hashCodes 518580394 vs 128524753. Unlike spec 031's scaffold (contract-legal, poor distribution), this is a genuine `==`/`hashCode` violation — the A-level test is a live red, not a regression guard.
- **Risk: hash fold collisions.** Sum folds can collide adversarially; acceptable for a registry of dozens of tools (not a security boundary); order-independence + equal-instance correctness are the contract, distribution is best-effort (031's documented M5 discipline).
- **Risk: list folding.** JSON-Schema arrays (`required: ['path', 'content']`) are ORDERED — folding them order-sensitively (hashAll-style) is correct; only MAP key order is insertion-order-noise.
- **Risk: fromJson type coercion.** Tier/mode strings validated through the same `fromString` parsers (single source of truth — an unknown tier in JSON fails exactly like an unknown tier in a declaration).

## Implementation Phases

Phase 1 — hash contract fix (test-first: AC US3-1..3 — the LIVE red).
Phase 2 — tier/mode classification parsing (test-first: AC US1-1..3).
Phase 3 — registry persistence contract (test-first: AC US2-1..3).
Phase 4 — Gates: full suite + analyze; existing provider tests untouched and passing; mutation spot-checks.

All behavioral phases run through the TDD loop with recorded red evidence.
