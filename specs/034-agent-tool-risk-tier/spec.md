# Feature Specification: AgentTool entity + RiskTier enum (R3 tools & MCP) — classification, registry persistence, hash contract

**Feature Branch**: `feat/specs-032-033-034-035` (spec dir: `034-agent-tool-risk-tier`)

**Created**: 2026-08-24 | **Refined**: 2026-08-27 via /speckit.specify (drift remediation)

**Status**: Approved

**Input**: Verbatim task spec — "034-agent-tool-risk-tier — classify tool risk tiers (e.g. low/medium/high) consumed by dispatch/approval. Author from the spec; mirror the repo's agent_tool provider pattern (lib/src/data/providers/agent_tool, lib/src/domain/entities/...): add entity + datasource interface + mock + provider + service under the same conventions. Net-new — no existing lib code."

*Refinement note*: the task text describes this feature as net-new, but the repo's master already ships the entity family from PR #52 (`AgentTool` + `RiskTier` + `ExecutionMode` + `AgentToolService` + `AgentToolProvider` + 10 provider tests). Per the task's own instruction ("Read each spec's existing spec.md/plan.md/tasks.md as the source of truth"), the repo's spec.md — which matches the landed code — is the source of truth; this refinement completes the missing semantics on the landed surface rather than re-authoring it. The datasource-interface/mock-datasource layering the task names belongs to the datasource-pair spec family (cf. specs 025/027/029) and is out of scope here because the repo's spec.md for 034 pins the provider-stub contract (FR-007).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Risk tiers classify tools for dispatch and approval (Priority: P1)

As the dispatch/approval layer (R3.2: "Risk metadata first-class on AgentTool: `safe|confirm|admin`"), I parse a tool declaration's risk tier from its wire string and read its dispatch policy off the tier — so `confirm` tools pause for an approval callback and `admin` tools demand an admin grant — and an unknown tier string is a typed failure, never a silent default that would under-classify a dangerous tool.

**Why this priority**: The registry's declarations arrive as strings (YAML agent specs, remote MCP manifests); the scaffold ships the enum but no parsing, so every consumer hand-rolls string→tier mapping with silent-default risk. Under-classification is the failure mode the approval layer exists to prevent.

**Independent Test**: `RiskTier.fromString('confirm')` → `RiskTier.confirm`; `RiskTier.fromString('delete')` → `ArgumentError` naming the input; each tier's `requiresConfirmation`/`isAdmin` dispatch policy reads correctly.

**Acceptance Scenarios**:

1. **Given** the strings `'safe'`, `'confirm'`, `'admin'`, **When** parsed via `RiskTier.fromString`, **Then** each maps to its tier, and `name` round-trips the string back.
2. **Given** an unknown string (`'delete'`, `''`, `'SAFE'` — case is significant), **When** parsed, **Then** an `ArgumentError` names the input — never a silent `safe` fallback.
3. **Given** a tool of each tier, **When** the dispatcher consults `requiresConfirmation`/`isAdmin`, **Then** `safe` dispatches free, `confirm` pauses for approval, `admin` additionally requires a grant (pinned by the existing enum tests; the tier-parse is the new surface).

---

### User Story 2 - Tool declarations survive the registry boundary (Priority: P2)

As the tool registry, I serialize tool declarations to JSON and parse them back — risk tier and execution mode as their names, params schema deep-copied — so a registered tool survives store round-trips and process restarts with its dispatch policy intact.

**Why this priority**: The registry is "registry-backed" (R3.1) — declarations persist; the scaffold has no serialization. Precedent: specs 031/032/033 each landed `toJson`/`fromJson` for exactly this boundary.

**Independent Test**: `AgentTool.fromJson(tool.toJson()) == tool` for a fully-declared tool (id, description, confirm tier, parallel mode, nested schema); a schema-less tool serializes `paramsSchema` absent.

**Acceptance Scenarios**:

1. **Given** a fully-declared tool, **When** serialized and parsed back, **Then** the parsed tool equals the original on every field including the deep params schema.
2. **Given** a tool without a params schema, **When** serialized, **Then** the `paramsSchema` key is absent — never `null`, never an empty map masquerading as a schema.
3. **Given** malformed declaration JSON (missing id/description, unknown tier or mode string, non-map schema), **When** parsed, **Then** an `ArgumentError` names the offending field — never a silent default tier (which would under-classify).

---

### User Story 3 - Equal declarations hash equally (Priority: P1)

As the registry (collision rejection at registration time) and any hash-based consumer (dedup sets, key maps), I require that two equal `AgentTool` declarations — including distinct-but-equal `paramsSchema` map instances — share one `hashCode`; today they do not.

**Why this priority**: **Experimentally verified live contract violation in the scaffold** (probe, 2026-08-27): `a == b` → `true` via the deep `_mapEq`, while `a.hashCode` → 518580394 and `b.hashCode` → 128524753 — the scaffold's `Object.hash(..., paramsSchema)` hashes the Map by identity. Every equal-but-distinctly-instantiated pair violates `==`/`hashCode`; registration-time collision checks and set dedup misbehave deterministically. (Contrast spec 031, whose scaffold hash was contract-legal with poor distribution; this one is a genuine violation.)

**Independent Test**: two tools with distinct-but-equal schema instances are `==` AND share `hashCode`; insertion-order differences do not change the hash; per-axis inequality still holds.

**Acceptance Scenarios**:

1. **Given** two equal tools with distinct-but-equal `paramsSchema` map instances, **When** hashed, **Then** the hashCodes are equal (the scaffold's live violation — genuinely red today).
2. **Given** equal schemas built in different insertion orders, **When** hashed, **Then** the tools remain equal with equal hashes (order-independent fold).
3. **Given** tools differing in id, description, riskTier, executionMode, or schema contents, **Then** they are unequal (the existing per-axis test pins this; the hash side follows the fix).

### Edge Cases

- Unknown tier string → `ArgumentError` (AC US1-2) — including case mismatches: `'SAFE'` is NOT accepted (declaration strings are exact; upcasing is a policy decision that belongs to the reader, not the value object).
- Unknown execution-mode string in `fromJson` → `ArgumentError` (AC US2-3).
- Missing `paramsSchema` in JSON → stays null, never an empty map (AC US2-2).
- Non-map `paramsSchema` in JSON → `ArgumentError` naming the field.
- Deep schema equality must NOT be added to `==` beyond what exists — the scaffold's `_mapEq` deep compare is correct; only the HASH is broken (FR-006 fixes the fold, not the equality).
- The datasource-interface + mock-datasource pair the task text names: out of scope (belongs to the datasource-pair spec family; FR-007 pins the provider-stub contract the repo's spec.md defines).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `AgentTool` value object keeps its spec-exact five-field surface — `id`, `description`, `riskTier` (default `safe`), `executionMode` (default `sequential`), `paramsSchema?` — with value equality (deep `_mapEq` on the schema), `requiresConfirmation`, `isAdmin`, and the enum surfaces unchanged (compile parity with the 10 existing tests).
- **FR-002**: `RiskTier.fromString(String value)` MUST parse `'safe'`/`'confirm'`/`'admin'` exactly (case-significant) and MUST throw `ArgumentError` naming the input for anything else — never a silent default. `RiskTier.name` (the enum's built-in) round-trips the wire string.
- **FR-003**: `ExecutionMode.fromString(String value)` MUST parse `'sequential'`/`'parallel'` with the same typed-failure discipline (consumed by FR-004).
- **FR-004**: `toJson()` MUST emit `id`, `description`, `riskTier` (tier name), `executionMode` (mode name) always and `paramsSchema` only when non-null (absent-never-fabricated); `AgentTool.fromJson` MUST round-trip all five fields (schema deep-copied) and MUST throw `ArgumentError` naming the field on missing required keys, unknown tier/mode strings, or a non-map schema.
- **FR-005**: The dispatch-policy reads (`RiskTier.severity`, `requiresConfirmation`, `isAdmin`) keep their existing semantics — the classification consumed by dispatch/approval (R3.2); pinned by the existing enum tests.
- **FR-006**: `hashCode` MUST be consistent with `==`: an order-independent fold over the params schema entries (commutative sum of per-entry hashes, nested maps folded recursively) combined with `Object.hash(id, description, riskTier, executionMode)` — fixing the scaffold's live violation where equal tools with distinct-but-equal schema instances hash differently.
- **FR-007**: The clean-arch layers (`AgentToolService.current/count`, `AgentToolProvider`) keep their existing signatures and stubs (no behavioral change — the classification + persistence + hash semantics are the deliverable).

### Key Entities *(include if feature involves data)*

- **AgentTool** (value object, existing scaffold): five-field surface + NEW `toJson`/`fromJson` + FIXED `hashCode`.
- **RiskTier** (enum, existing scaffold): safe/confirm/admin + severity + policy getters + NEW `fromString`.
- **ExecutionMode** (enum, existing scaffold): sequential/parallel + NEW `fromString`.
- **AgentToolService / AgentToolProvider** (existing interfaces): unchanged surfaces; compile parity pinned by the existing 10 tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: tier strings parse exactly and round-trip; unknown strings fail typed (AC US1-1..2).
- **SC-002**: declarations round-trip JSON with tier, mode, and deep schema intact (AC US2-1).
- **SC-003**: schema-less declarations serialize `paramsSchema` absent (AC US2-2).
- **SC-004**: malformed declarations fail typed, naming the field — including unknown tier/mode strings (AC US2-3).
- **SC-005**: equal tools with distinct-but-equal schema instances share `hashCode` (AC US3-1 — the scaffold's live violation, genuinely red today); order-independence holds (AC US3-2).
- **SC-006**: per-axis inequality still holds across all five fields (AC US3-3, FR-001).
- **SC-007**: `dart analyze --fatal-infos` zero new issues; full `dart test` green (post-033 baseline 626 passed); the 10 pre-existing provider tests pass unchanged (FR-001, FR-005, FR-007).

## Assumptions

- `fromString` parse discipline is exact-match, case-significant: declaration strings are machine-written (enum `name`s); a lenient upcasing reader is a policy layer decision, not a value-object behavior (documented edge).
- The hash fold mirrors spec 031's refined approach (commutative sum of per-entry hashes) extended recursively over nested maps (schemas are nested JSON-Schema objects; a single-level fold would re-create the same violation one level down).
- The scaffold's equality is correct and untouched — only the hash is broken; the fix keeps `==` byte-identical (edge discipline).
- The task text's "net-new, author entity + datasource + provider + service" description is stale relative to the repo (PR #52 landed the family); the repo's spec.md governs, and this refinement completes semantics on the landed surface. The datasource-pair layering stays with its own spec family (025/027/029 precedent).
- The provider/service layers stay stubs in this feature (FR-007).
