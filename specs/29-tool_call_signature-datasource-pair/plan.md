# Implementation Plan: ToolCallSignature datasource + mock pair

**Branch**: `feat/specs-025-027-029-031` (spec dir: `29-tool_call_signature-datasource-pair`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/29-tool_call_signature-datasource-pair/spec.md`

## Summary

Give the ToolCallSignature pair its real behavioral surface: enrich the anemic `id`-only value object into the content-addressable identity (`toolName` + `argumentHash` + `version`, derived `key`, value equality), replace the scaffolded `current()/reset()` interface with the capture/lookup/count/reset persistence contract, and implement the mock as an in-memory key-addressed store with idempotent capture. Closes the behavioral gap left by issues #29/#30 (which only fixed compilation).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (`Loggable`/`FailureHandler`), `test` ^1.25.0.

**Storage**: None — the mock is the in-memory reference store; the interface is the persistence contract (a Hive/remote backend swaps in later).

**Testing**: `dart test`; single test via `--plain-name`; gates per `.specify/memory/tdd-profile.md` (`dart analyze` 5-issue pre-existing baseline, zero new).

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: `lookup` is a single map access; `capture` is a map write; no scans.

**Constraints**: Constructor backward compatibility (FR-003); no codegen (hand-curated plain Dart); no new dependencies.

**Scale/Scope**: 3 lib files + 2 test files (entity parity, datasource pair) ≈ 20 tests.

## Constitution Check

*No `.specify/memory/constitution.md`; repo AGENTS.md rules apply. Hand-curated banner kept with issue references #29/#30. Passed.*

## Project Structure

### Documentation (this feature)

```text
specs/29-tool_call_signature-datasource-pair/
├── spec.md            # refined via /speckit.specify
├── plan.md            # this file
├── tasks.md           # /speckit.tasks output
└── tdd/
    ├── test-list.md   # /speckit.tdd.plan output
    ├── cycle-log.md
    └── verification.md
```

### Source Code (repository root)

```text
lib/src/domain/entities/tool_call_signature/tool_call_signature.dart                  # enriched value object
lib/src/data/datasources/tool_call_signature/tool_call_signature_datasource.dart       # interface: capture/lookup/count/reset
lib/src/data/datasources/tool_call_signature/tool_call_signature_mock_datasource.dart  # in-memory key-addressed impl
test/domain/entities/tool_call_signature/tool_call_signature_test.dart                 # NEW: entity parity + key derivation
test/data/datasources/tool_call_signature/tool_call_signature_mock_datasource_test.dart # rewritten: real behavior
```

## Architecture / Data Flow

```text
engine / eval harness
   │ capture(ToolCallSignature)          lookup(key)
   ▼
ToolCallSignatureDatasource (interface)
   ▲ implements
ToolCallSignatureMockDatasource          # Map<String, ToolCallSignature>, keyed by signature.key
   │ stores
ToolCallSignature (value object)
   · toolName + argumentHash + version   # content
   · key = 'toolName@version:argumentHash'  # derived, canonical
   · == / hashCode on the content triple
```

Key decisions:

1. **Derived key, content equality** — `key` is a canonical string derived in the constructor (`toolName@version:argumentHash`); equality/hashCode use the content triple, NOT the key string, so an explicitly-passed legacy `id` cannot create phantom inequality between content-equal signatures. The `id` field is kept (backward compat) and defaults to the derived key.
2. **Idempotent capture** — the mock maps `signature.key → signature`; recapturing equal content overwrites with an equal value, so `count` (map length) never grows on duplicates (FR-005).
3. **Miss = null, never throw** — `lookup` returns `Future<ToolCallSignature?>`; absence is a normal outcome for dedup probes (FR-006).
4. **Interface supersedes `current()`** — the scaffolded single-instance read is subsumed by `lookup(key)`; the drop is documented in spec.md Assumptions. No other lib code imports the interface (verified), so the surface change is safe.
5. **Composition with spec 25 stays documented, not compiled** — the repetition tracker consumes the key as an opaque String; this pair never imports that one, and vice versa.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the existing stub tests.** Intended and documented (superseded; compile-parity `isA` check kept).
- **Risk: const constructor with derived default.** `ToolCallSignature({required toolName, required argumentHash, version = 1, String? id}) : id = id ?? '$toolName@$version:$argumentHash'` — string interpolation over potentially-const values is const-evaluable; the entity stays `const`-constructible.
- **Risk: legacy explicit `id` diverging from content.** Equality ignores `id` (content triple only) — a legacy `ToolCallSignature(id: 'x')` (empty content) equals another empty-content signature regardless of ids; documented in U-tests.
- **Risk: empty toolName/hash collisions.** Empty strings are valid content; the key `'@1:'` is unique to that content. No special casing.

## Implementation Phases

Phase 1 — Entity: content fields + derived key + content equality (test-first).
Phase 2 — Interface + mock: capture/lookup/count/reset contract (test-first).
Phase 3 — Idempotency + reset semantics (test-first).
Phase 4 — Gates: full suite + analyze.

All behavioral phases run through the TDD loop with recorded red evidence.
