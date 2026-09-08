# Traceability: 031-tool-result-value-object

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:e4da350ebe459ad77ac7aa21b4c82f77589468c4d28fa0d65388ff2e7888f69f
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a success result with content + structuredPayload, **When** serialized to JSON and parsed back, **Then** the parsed value equals the original (content, payload, isError all preserved). | A1 | automated |
| AC-2 | 27 | 2. **Given** an error result, **When** serialized and parsed back, **Then** `isError` is still true and the content (error message) is preserved. | A2 | automated |
| AC-3 | 29 | 3. **Given** an error result with no structuredPayload, **When** serialized, **Then** the payload key is absent/null — not an empty object masquerading as data. | A3 | automated |
| AC-4 | 44 | 4. **Given** a 2 MB body and the oversized path, **When** the result is built, **Then** content is a bounded summary, `artifactRef` is non-null, and `isSummarized` is true. | A4 | automated |
| AC-5 | 46 | 5. **Given** a summarized result, **When** serialized and parsed back, **Then** the artifactRef (kind, id, uri) survives the round-trip. | A5 | automated |
| AC-6 | 48 | 6. **Given** an inline (non-summarized) result, **When** `isSummarized` is checked, **Then** it is false and serialization omits the artifactRef. | A6 | automated |
| AC-7 | 63 | 7. **Given** two equal results with distinct-but-equal payload map instances, **When** hashed, **Then** the hashCodes are equal (the contract the scaffold violates). | A7 | automated |
| AC-8 | 65 | 8. **Given** results differing in content, payload, isError, or artifactRef, **Then** they are unequal. | A8 | automated |
| FR-001 | 80 | - **FR-001**: The `ToolResult` value object MUST keep the spec-003-exact field surface — `content` (String), `structuredPayload` (Map?), `artifactRef` (ArtifactRef?) — with NO `id` field, and MUST add `isError` (bool, default false) as the success/error discriminator. | U1 | automated |
| FR-002 | 81 | - **FR-002**: Named constructors `ToolResult.success` and `ToolResult.error` MUST construct results with `isError` false/true respectively; `isError` participates in equality and hashCode. | U2 | automated |
| FR-003 | 82 | - **FR-003**: `toJson()` MUST produce a JSON map with `content`, `structuredPayload` (null-safe), `artifactRef` (nested kind/id/uri, null-safe), and `isError`; `ToolResult.fromJson` MUST round-trip all four fields exactly. | U3 | automated |
| FR-004 | 83 | - **FR-004**: The oversized path (`ToolResult.oversized`) MUST require a summary and an artifactRef; such results report `isSummarized == true` (artifactRef non-null). | U4 | automated |
| FR-005 | 84 | - **FR-005**: `isSummarized` MUST remain the derived getter (artifactRef != null) — true for any result carrying a ref, false otherwise; serialization omits a null artifactRef. | U5 | automated |
| FR-006 | 85 | - **FR-006**: Equality MUST compare content, structuredPayload (deep map equality), isError, and artifactRef; `hashCode` MUST be consistent with equality (equal results — including distinct-but-equal payload instances, any insertion order — hash equally) and MUST fold the payload in an order-independent way so payload-only differences stop colliding deterministically. | U6 | automated |
| FR-007 | 86 | - **FR-007**: The clean-arch layers (`ToolResultService.current/count`, `ToolResultProvider`) MUST keep their existing signatures and compile parity; the provider stubs remain UnimplementedError (no behavioral change in this feature — the value object semantics are the deliverable). | U7 | automated |

