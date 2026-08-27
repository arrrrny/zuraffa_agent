# Feature Specification: ToolResult value object (no id) + clean-arch layers

**Feature Branch**: `031-tool-result-value-object`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "tool result value object. Existing: lib/src/data/providers/tool_result/tool_result_provider.dart, lib/src/domain/services/tool_result_service.dart, lib/src/domain/entities/tool_result/tool_result.dart. Spec + tests for the value object semantics (success/error, serialization, oversized-result handling)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Success and error results are distinct, serializable values (Priority: P1)

As the engine, I construct tool results that are either successes (content the model should act on) or errors (typed failure surfaces for MCP transport errors, tool crashes, and denied approvals per spec 003 edge cases), and I serialize them across the wire/session boundary without losing that distinction.

**Why this priority**: Success/error is the primary axis every consumer branches on; serialization is what lets the result cross process boundaries (event stream, session tree, recorded traffic).

**Independent Test**: `ToolResult.success(...)` and `ToolResult.error(...)` construct with the right flags; `toJson()`/`fromJson()` round-trips both without losing content, payload, or error-ness.

**Acceptance Scenarios**:

1. **Given** a success result with content + structuredPayload, **When** serialized to JSON and parsed back, **Then** the parsed value equals the original (content, payload, isError all preserved).
2. **Given** an error result, **When** serialized and parsed back, **Then** `isError` is still true and the content (error message) is preserved.
3. **Given** an error result with no structuredPayload, **When** serialized, **Then** the payload key is absent/null — not an empty object masquerading as data.

---

### User Story 2 - Oversized results are summarized with an artifactRef (Priority: P2)

As the engine (spec 003 US4), when a tool returns a body beyond the size threshold, I replace the model-facing content with a summary and attach the out-of-band `artifactRef`, so large bodies never enter the context window.

**Why this priority**: Context-window poisoning is a mission-killer (a 2 MB scrape must not enter context); the value object is where the summarize+ref discipline is anchored.

**Independent Test**: A result constructed via the oversized path carries the artifactRef, reports `isSummarized == true`, serializes with the ref, and round-trips.

**Acceptance Scenarios**:

1. **Given** a 2 MB body and the oversized path, **When** the result is built, **Then** content is a bounded summary, `artifactRef` is non-null, and `isSummarized` is true.
2. **Given** a summarized result, **When** serialized and parsed back, **Then** the artifactRef (kind, id, uri) survives the round-trip.
3. **Given** an inline (non-summarized) result, **When** `isSummarized` is checked, **Then** it is false and serialization omits the artifactRef.

---

### User Story 3 - Value-object discipline holds under hashing and equality (Priority: P3)

As a library consumer, I store ToolResults in sets/maps (dedup, replay diffing per spec 060), so equal results must hash equally — including when their structuredPayload maps are distinct-but-equal map instances.

**Why this priority**: The scaffolded `hashCode` hashes only `content + artifactRef`; Dart maps hash by identity, so two equal results with equal-but-distinct payload instances hash differently — a live `==`/`hashCode` contract violation that corrupts any hash-based consumer.

**Independent Test**: Two results with equal content, equal payload (distinct map instances), and equal artifactRef are `==` AND share `hashCode`.

**Acceptance Scenarios**:

1. **Given** two equal results with distinct-but-equal payload map instances, **When** hashed, **Then** the hashCodes are equal (the contract the scaffold violates).
2. **Given** results differing in content, payload, isError, or artifactRef, **Then** they are unequal.

### Edge Cases

- What happens to a null structuredPayload in equality? → null equals null only; null never equals an empty map.
- What happens to non-JSON-serializable payload values? → Out of scope for v1: the value object serializes what json-encodable maps carry; callers must pre-sanitize (documented assumption).
- What is the error content when empty? → Allowed (empty string is a valid error surface — the isError flag carries the semantics, not the content).
- Does serialization of a summarized result keep the summary? → Yes — content IS the summary; the full body lives behind the artifactRef.
- Do success and error share the artifactRef path? → Yes — an oversized error body can also be summarized out-of-band.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `ToolResult` value object MUST keep the spec-003-exact field surface — `content` (String), `structuredPayload` (Map?), `artifactRef` (ArtifactRef?) — with NO `id` field, and MUST add `isError` (bool, default false) as the success/error discriminator.
- **FR-002**: Named constructors `ToolResult.success` and `ToolResult.error` MUST construct results with `isError` false/true respectively; `isError` participates in equality and hashCode.
- **FR-003**: `toJson()` MUST produce a JSON map with `content`, `structuredPayload` (null-safe), `artifactRef` (nested kind/id/uri, null-safe), and `isError`; `ToolResult.fromJson` MUST round-trip all four fields exactly.
- **FR-004**: The oversized path (`ToolResult.oversized`) MUST require a summary and an artifactRef; such results report `isSummarized == true` (artifactRef non-null).
- **FR-005**: `isSummarized` MUST remain the derived getter (artifactRef != null) — true for any result carrying a ref, false otherwise; serialization omits a null artifactRef.
- **FR-006**: Equality MUST compare content, structuredPayload (deep map equality), isError, and artifactRef; `hashCode` MUST be consistent with equality — equal results (including distinct-but-equal payload instances) hash equally (order-independent payload hashing).
- **FR-007**: The clean-arch layers (`ToolResultService.current/count`, `ToolResultProvider`) MUST keep their existing signatures and compile parity; the provider stubs remain UnimplementedError (no behavioral change in this feature — the value object semantics are the deliverable).

### Key Entities *(include if feature involves data)*

- **ToolResult** (value object): model-facing tool dispatch result — content + structuredPayload + artifactRef + isError; success/error factories; JSON round-trip; summarized discipline.
- **ArtifactRef** (existing, spec-exact): kind + id + uri; nested serialization handled by ToolResult's toJson/fromJson.
- **ToolResultService / ToolResultProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: success/error round-trips preserve all fields including isError (AC US1-1..3).
- **SC-002**: the oversized path produces summary + artifactRef + `isSummarized` true, surviving round-trip (AC US2-1..2).
- **SC-003**: inline results serialize without artifactRef and report `isSummarized` false (AC US2-3).
- **SC-004**: equal results with distinct-but-equal payload instances share hashCode (AC US3-1) — the scaffold's live contract violation, fixed.
- **SC-005**: field-different results are unequal across all four axes (AC US3-2).
- **SC-006**: `dart analyze` zero new issues; full `dart test` green (post-spec-29 baseline: 562 passed / 5 pre-existing analyze issues).

## Assumptions

- `isError` is additive to the spec-003 field list (content/structuredPayload/artifactRef stay spec-exact); ToolInvocationRecord already carries `isError`, so the concept is native to the repo — the value object catching up is drift remediation, not spec drift.
- JSON serialization uses plain map shapes (no codegen): payload values must be JSON-encodable by the caller; `artifactRef` serializes as {kind, id, uri} matching ArtifactRef's generated shape.
- The provider/service layers stay stubs in this feature (FR-007): wiring them to a store is a separate feature; the existing compile-parity and stub tests keep passing unchanged.
- Payload key order must not affect equality or hashCode (order-independent hashing).
