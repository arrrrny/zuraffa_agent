# Feature Specification: ToolCallSignature datasource + mock pair

**Feature Branch**: `29-tool_call_signature-datasource-pair`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "tool call signature datasource pair. Existing: lib/src/data/datasources/tool_call_signature/* (interface + mock), lib/src/domain/entities/tool_call_signature/tool_call_signature.dart. Spec + tests for signature capture/lookup used in caching/dedup."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a signature and look it up (Priority: P1)

As the engine, I capture the content-addressable signature of every tool invocation (tool name + argument hash + version) into the datasource, and later look it up to decide whether this exact call was already made — the basis of caching and dedup.

**Why this priority**: Capture/lookup is the entire reason the pair exists; RepetitionTracker (spec 25) and the eval harness (spec 006) both sit on top of this primitive.

**Independent Test**: `capture(sig)` then `lookup(key)` returns the signature; `lookup` of a never-captured key reports absence.

**Acceptance Scenarios**:

1. **Given** an empty store, **When** `capture(signature)` completes, **Then** a subsequent `lookup(signature.key)` returns the signature (round-trip).
2. **Given** an empty store, **When** `lookup` is called with any key, **Then** absence is reported (null / not-found — no throw, no phantom entry).

---

### User Story 2 - Content addressing makes equal calls dedupe (Priority: P2)

As the engine, two invocations with the same tool name, argument hash, and version must produce the same signature identity, so re-invocations are recognized as repeats without re-hashing or string comparison beyond the key.

**Why this priority**: Dedup is the payoff of content addressing — identity must be derived from content, never from an arbitrary id.

**Independent Test**: Two signatures constructed from the same (toolName, argumentHash, version) are `==`, share `hashCode`, and produce the same `key`; differing any component makes them unequal with different keys.

**Acceptance Scenarios**:

1. **Given** `('webview.browse', 'abc123', 1)` built twice, **Then** both signatures are equal, hash equally, and their keys are identical.
2. **Given** the same tool name and hash but version 2, **Then** the signature is unequal to the version-1 signature and its key differs.
3. **Given** `capture` of the same content twice, **Then** the store holds one entry (idempotent capture — dedup at the datasource level too).

---

### User Story 3 - Eviction and reset keep the store bounded (Priority: P3)

As the engine operator, I reset the signature store between missions so cross-mission state never leaks, and the store reports its size so budget guards can monitor growth.

**Why this priority**: Unbounded signature growth is a slow leak; reset is the persistence-contract primitive that bounds it.

**Independent Test**: After capturing N distinct signatures, `count` reports N; after `reset()`, `count` reports 0 and lookups report absence.

**Acceptance Scenarios**:

1. **Given** 3 distinct signatures captured, **When** `count` is called, **Then** it returns 3.
2. **Given** any captured state, **When** `reset()` is called, **Then** `count` returns 0 and every `lookup` reports absence.

### Edge Cases

- What happens on duplicate capture? → Idempotent: the entry is overwritten with the equal value; `count` does not grow (AC US2-3).
- What happens on lookup of a key that was never captured? → Absence (null), never a throw (AC US1-2).
- What happens with an empty tool name or argument hash? → Allowed (the engine may hash empty args); the key is still well-formed and unique to that content.
- What happens to version 0? → Allowed; version is an opaque int (default 1 for backward compatibility).
- Does reset affect the RepetitionTracker? → No — separate stores; spec 25's tracker is reset through its own contract.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `ToolCallSignature` value object MUST carry `toolName`, `argumentHash`, `version` (default 1) with value equality and hashCode across all three fields.
- **FR-002**: `ToolCallSignature` MUST derive `id`/`key` from content — a stable canonical string of the form `toolName@version:argumentHash` — identical for equal signatures, different for any differing component.
- **FR-003**: Constructor backward compatibility MUST hold: `ToolCallSignature(id: ...)` from the anemic scaffold keeps compiling, and a content-only constructor derives the key automatically.
- **FR-004**: The datasource interface MUST define the persistence contract: `capture(signature)`, `lookup(key)`, `count()`, `reset()` — all asynchronous; plus the scaffolded `current()`/`reset()` semantics folded into the refined surface.
- **FR-005**: `capture` MUST be idempotent per key — duplicate captures of equal signatures do not grow the store.
- **FR-006**: `lookup` MUST return the captured signature for a known key and absence (null) for an unknown key — never throw for misses.
- **FR-007**: The mock datasource MUST implement the contract in memory: a key-addressed map, seeded empty, `reset` clearing all entries.

### Key Entities *(include if feature involves data)*

- **ToolCallSignature** (value object): content-addressable invocation identity — `toolName` + `argumentHash` + `version`; `key` derived; value equality on the content triple.
- **ToolCallSignatureDatasource** (interface): capture/lookup/count/reset persistence contract.
- **ToolCallSignatureMockDatasource** (concrete): in-memory key-addressed reference implementation.
- **RepetitionTracker** (spec 25): consumes the signature's key as its opaque `String signature` — composition documented on both sides, compiled on neither (independent testability).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: capture→lookup round-trip returns the equal signature (AC US1-1).
- **SC-002**: unknown-key lookup reports absence without throwing (AC US1-2).
- **SC-003**: equal content ⇒ equal signature, equal hashCode, identical key; any differing component breaks all three (AC US2-1..2).
- **SC-004**: duplicate capture is idempotent — count stays 1 (AC US2-3, edge-1).
- **SC-005**: `count` reflects distinct captured signatures; `reset()` zeroes it and clears lookups (AC US3-1..2).
- **SC-006**: `dart analyze` zero new issues; full `dart test` green (post-spec-27 baseline: 551 passed / 5 pre-existing analyze issues).

## Assumptions

- The canonical key format `toolName@version:argumentHash` is a pair-local convention pinned by tests; spec 25's repetition tracker treats it as opaque.
- "Caching/dedup" at this layer means signature storage and identity; actual result caching (mapping signature → result) composes this pair with spec 031's ToolResult and is out of scope.
- Existing tests asserting `UnimplementedError` stubs are superseded (drift remediation).
- The scaffolded `current()` (single-instance value object read) is subsumed by `lookup(key)` — the refined interface keeps `current()` only if it can return the last captured signature; simplest contract drops it for the richer lookup. This refinement documents that drop explicitly.
