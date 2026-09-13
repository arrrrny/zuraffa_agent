# Traceability: 034-agent-tool-risk-tier

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:b6912749a38dd82a8f25ca4741f1b7a7fa4a63d743a54f3e15c66bb1dc302334
statements: 16
automated: 16
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 27 | 1. **Given** the strings `'safe'`, `'confirm'`, `'admin'`, **When** parsed via `RiskTier.fromString`, **Then** each maps to its tier, and `name` round-trips the string back. | A1 | automated |
| AC-2 | 29 | 2. **Given** an unknown string (`'delete'`, `''`, `'SAFE'` — case is significant), **When** parsed, **Then** an `ArgumentError` names the input — never a silent `safe` fallback. | A2 | automated |
| AC-3 | 31 | 3. **Given** a tool of each tier, **When** the dispatcher consults `requiresConfirmation`/`isAdmin`, **Then** `safe` dispatches free, `confirm` pauses for approval, `admin` additionally requires a grant (pinned by the existing enum tests; the tier-parse is the new surface). | A3 | automated |
| AC-4 | 46 | 4. **Given** a fully-declared tool, **When** serialized and parsed back, **Then** the parsed tool equals the original on every field including the deep params schema. | A4 | automated |
| AC-5 | 48 | 5. **Given** a tool without a params schema, **When** serialized, **Then** the `paramsSchema` key is absent — never `null`, never an empty map masquerading as a schema. | A5 | automated |
| AC-6 | 50 | 6. **Given** malformed declaration JSON (missing id/description, unknown tier or mode string, non-map schema), **When** parsed, **Then** an `ArgumentError` names the offending field — never a silent default tier (which would under-classify). | A6 | automated |
| AC-7 | 65 | 7. **Given** two equal tools with distinct-but-equal `paramsSchema` map instances, **When** hashed, **Then** the hashCodes are equal (the scaffold's live violation — genuinely red today). | A7 | automated |
| AC-8 | 67 | 8. **Given** equal schemas built in different insertion orders, **When** hashed, **Then** the tools remain equal with equal hashes (order-independent fold). | A8 | automated |
| AC-9 | 69 | 9. **Given** tools differing in id, description, riskTier, executionMode, or schema contents, **Then** they are unequal (the existing per-axis test pins this; the hash side follows the fix). | A9 | automated |
| FR-001 | 85 | - **FR-001**: The system MUST satisfy this requirement: The `AgentTool` value object keeps its spec-exact five-field surface — `id`, `description`, `riskTier` (default `safe`), `executionMode` (default `sequential`), `paramsSchema?` — with value equality (deep `_mapEq` on the schema), `requiresConfirmation`, `isAdmin`, and the enum surfaces unchanged (compile parity with the 10 existing tests). | U1 | automated |
| FR-002 | 86 | - **FR-002**: `RiskTier.fromString(String value)` MUST parse `'safe'`/`'confirm'`/`'admin'` exactly (case-significant) and MUST throw `ArgumentError` naming the input for anything else — never a silent default. `RiskTier.name` (the enum's built-in) round-trips the wire string. | U2 | automated |
| FR-003 | 87 | - **FR-003**: `ExecutionMode.fromString(String value)` MUST parse `'sequential'`/`'parallel'` with the same typed-failure discipline (consumed by FR-004). | U3 | automated |
| FR-004 | 88 | - **FR-004**: `toJson()` MUST emit `id`, `description`, `riskTier` (tier name), `executionMode` (mode name) always and `paramsSchema` only when non-null (absent-never-fabricated); `AgentTool.fromJson` MUST round-trip all five fields (schema deep-copied) and MUST throw `ArgumentError` naming the field on missing required keys, unknown tier/mode strings, or a non-map schema. | U4 | automated |
| FR-005 | 89 | - **FR-005**: The system MUST satisfy this requirement: The dispatch-policy reads (`RiskTier.severity`, `requiresConfirmation`, `isAdmin`) keep their existing semantics — the classification consumed by dispatch/approval (R3.2); pinned by the existing enum tests. | U5 | automated |
| FR-006 | 90 | - **FR-006**: `hashCode` MUST be consistent with `==`: an order-independent fold over the params schema entries (commutative sum of per-entry hashes, nested maps folded recursively) combined with `Object.hash(id, description, riskTier, executionMode)` — fixing the scaffold's live violation where equal tools with distinct-but-equal schema instances hash differently. | U6 | automated |
| FR-007 | 91 | - **FR-007**: The system MUST satisfy this requirement: The clean-arch layers (`AgentToolService.current/count`, `AgentToolProvider`) keep their existing signatures and stubs (no behavioral change — the classification + persistence + hash semantics are the deliverable). | U7 | automated |

