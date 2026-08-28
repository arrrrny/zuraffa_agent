# Feature Specification: SubAgentSpec value object (R5 sub-agents & specs)

**Feature Branch**: `036-sub-agent-spec`

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation — validation semantics added, criteria made measurable)

**Status**: Approved

**Input**: Verbatim task spec — "036-sub-agent-spec — declarative sub-agent spec aggregate. Existing: lib/src/data/providers/sub_agent_spec/sub_agent_spec_provider.dart, lib/src/domain/services/sub_agent_spec_service.dart, lib/src/domain/entities/sub_agent_spec/sub_agent_spec.dart. Spec + tests for the sub-agent definition (model, tools, system prompt, constraints, validation)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A sub-agent spec is a validated, declarative value (Priority: P1)

As the spec loader (R5.2), I construct `SubAgentSpec` values from YAML agent specs, and the value object itself refuses ill-formed specs at construction — empty identity fields, blank tool/sub-agent ids, non-positive budgets, and self-inheritance — so a malformed YAML file fails fast at load time with a typed `ArgumentError` instead of producing a spec that misbehaves at dispatch time.

**Why this priority**: "Specs are data" only works if the data cannot be silently ill-formed. Every downstream consumer (loader merge, dispatch allowlist checks, budget enforcement) trusts these fields; validation at the aggregate boundary is the cheapest place to catch YAML drift.

**Independent Test**: Constructing specs with each invalid input throws `ArgumentError` naming the offending field; constructing a well-formed spec succeeds with all defaults intact.

**Acceptance Scenarios**:

1. **Given** a spec with an empty `name`, empty `description`, or empty `systemPrompt`, **When** constructed, **Then** `ArgumentError` is thrown naming that field.
2. **Given** a spec whose `tools` or `subAgents` allowlist contains an empty string id, **When** constructed, **Then** `ArgumentError` is thrown naming the list.
3. **Given** a spec with `maxTurns` < 1, `contextWindowTokens` < 1, or a negative `wallClockTimeout`, **When** constructed, **Then** `ArgumentError` is thrown naming the budget field.

---

### User Story 2 - Inheritance constraints are structural and checkable (Priority: P2)

As the loader resolving `extends` chains (R5.2), I need the self-inheritance ill-formedness caught at the value level (`extendsSpec == name` is a 1-cycle), and the structural getters (`isLeaf`, `isRoot`, `hasBudgets`) to answer dispatch questions without re-walking fields.

**Why this priority**: The loader builds on these getters; a wrong `isRoot`/`isLeaf` corrupts merge order and dispatchability decisions. Self-extends is the cheapest cycle to reject before a loader exists.

**Independent Test**: A spec with `extendsSpec == name` throws `ArgumentError`; `isLeaf`/`isRoot`/`hasBudgets` return the documented truth values for the four canonical shapes (root+leaf, root+branch, child+leaf, child+branch).

**Acceptance Scenarios**:

1. **Given** a spec whose `extendsSpec` equals its own `name`, **When** constructed, **Then** `ArgumentError` is thrown (1-cycles are ill-formed).
2. **Given** the four canonical shapes, **When** the getters are read, **Then** `isLeaf` == `subAgents.isEmpty`, `isRoot` == `extendsSpec == null`, and `hasBudgets` reflects the three budget fields (AC covered by existing tests — pinned, not new).

---

### User Story 3 - Value-object discipline holds across all ten fields (Priority: P3)

As a library consumer, I store specs in sets/maps (spec registries keyed by value), so two field-identical specs must be `==` and hash equally, and any single-field difference must break equality.

**Why this priority**: The registry and loader compare specs; equality drift here corrupts registry keying silently.

**Independent Test**: Two field-identical specs (independently constructed lists) are `==` and share `hashCode`; changing exactly one field breaks equality.

**Acceptance Scenarios**:

1. **Given** two specs equal in all ten fields but with independently constructed `tools`/`subAgents` lists, **When** compared, **Then** they are `==` and share `hashCode` (AC covered by existing tests — pinned, not new).
2. **Given** two specs differing in exactly one field, **Then** they are unequal.

### Edge Cases

- Empty `tools`/`subAgents` lists? → Valid (a tool-less leaf agent is legal; defaults `const []`).
- `wallClockTimeout: Duration.zero`? → Valid — documented as "no wall-clock limit" (only maxTurns applies); negative durations are invalid, zero is not.
- `extendsSpec` pointing at an unknown spec? → Out of scope here: the loader (later PR) resolves names; the value object only rejects the 1-cycle it can see locally.
- Whitespace-only strings? → Treated as non-empty (no trimming) — the YAML loader owns normalization.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SubAgentSpec` MUST reject with `ArgumentError` any construction where `name`, `description`, or `systemPrompt` is an empty string (the message MUST name the field).
- **FR-002**: `SubAgentSpec` MUST reject with `ArgumentError` any blank id (`''`) inside `tools` or `subAgents` (the message MUST name the offending list).
- **FR-003**: `SubAgentSpec` MUST reject with `ArgumentError` a non-positive budget when supplied: `maxTurns != null && maxTurns < 1`, `contextWindowTokens != null && contextWindowTokens < 1`, or `wallClockTimeout` with negative `Duration` (message MUST name the field). `Duration.zero` remains valid.
- **FR-004**: `SubAgentSpec` MUST reject with `ArgumentError` the 1-cycle `extendsSpec == name`.
- **FR-005**: The structural getters MUST keep their documented semantics: `isLeaf` == `subAgents.isEmpty`; `isRoot` == `extendsSpec == null`; `hasBudgets` == any of the three budget fields non-null.
- **FR-006**: Equality/hashCode MUST keep field-wise value semantics across all ten fields (list-aware for `tools`/`subAgents`), and MUST be constructible with non-const lists without breaking equality.
- **FR-007**: The clean-arch layers (`SubAgentSpecService.current/count`, `SubAgentSpecProvider`) MUST keep their existing signatures and stub behavior (UnimplementedError); no behavioral change to those layers in this feature.

### Key Entities *(include if feature involves data)*

- **SubAgentSpec** (value object, existing): the ten-field declarative aggregate; this feature adds construction-time validation (FR-001..004) and changes nothing else.
- **SubAgentSpecService / SubAgentSpecProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 11 tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every invalid-input class in AC US1-1..3 throws `ArgumentError` (9 cases: 3 identity fields, 2 allowlist kinds, 4 budget shapes including the zero-valid boundary).
- **SC-002**: Self-extends (AC US2-1) throws `ArgumentError`; a valid child spec with `extendsSpec != name` constructs.
- **SC-003**: All 11 pre-existing tests pass unchanged (getters, equality, clean-arch pins — FR-005/006/007).
- **SC-004**: `dart analyze` reports zero new findings vs the 5-issue baseline; full `dart test` green.

## Assumptions

- Validation is constructor-time `ArgumentError` (matches `PassAtK.compute` and `UiTreePayload` precedent in this repo); no result-type failures for value construction.
- The value object stays a plain Dart hand-curated class (header precedent); Zorphy codegen is not introduced by this feature.
- `null` budgets are always valid (inherit-from-parent semantics live in the future loader).
