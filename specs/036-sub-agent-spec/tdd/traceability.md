# Traceability: 036-sub-agent-spec

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:197fe9c83818534b106b9ff5a2402687792f1cabafb2d9a532eb6cac38f3433c
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a spec with an empty `name`, empty `description`, or empty `systemPrompt`, **When** constructed, **Then** `ArgumentError` is thrown naming that field. | A1 | automated |
| AC-2 | 27 | 2. **Given** a spec whose `tools` or `subAgents` allowlist contains an empty string id, **When** constructed, **Then** `ArgumentError` is thrown naming the list. | A2 | automated |
| AC-3 | 29 | 3. **Given** a spec with `maxTurns` < 1, `contextWindowTokens` < 1, or a negative `wallClockTimeout`, **When** constructed, **Then** `ArgumentError` is thrown naming the budget field. | A3 | automated |
| AC-4 | 44 | 4. **Given** a spec whose `extendsSpec` equals its own `name`, **When** constructed, **Then** `ArgumentError` is thrown (1-cycles are ill-formed). | A4 | automated |
| AC-5 | 46 | 5. **Given** the four canonical shapes, **When** the getters are read, **Then** `isLeaf` == `subAgents.isEmpty`, `isRoot` == `extendsSpec == null`, and `hasBudgets` reflects the three budget fields (AC covered by existing tests — pinned, not new). | A5 | automated |
| AC-6 | 61 | 6. **Given** two specs equal in all ten fields but with independently constructed `tools`/`subAgents` lists, **When** compared, **Then** they are `==` and share `hashCode` (AC covered by existing tests — pinned, not new). | A6 | automated |
| AC-7 | 63 | 7. **Given** two specs differing in exactly one field, **Then** they are unequal. | A7 | automated |
| FR-001 | 77 | - **FR-001**: `SubAgentSpec` MUST reject with `ArgumentError` any construction where `name`, `description`, or `systemPrompt` is an empty string (the message MUST name the field). | U1 | automated |
| FR-002 | 78 | - **FR-002**: `SubAgentSpec` MUST reject with `ArgumentError` any blank id (`''`) inside `tools` or `subAgents` (the message MUST name the offending list). | U2 | automated |
| FR-003 | 79 | - **FR-003**: `SubAgentSpec` MUST reject with `ArgumentError` a non-positive budget when supplied: `maxTurns != null && maxTurns < 1`, `contextWindowTokens != null && contextWindowTokens < 1`, or `wallClockTimeout` with negative `Duration` (message MUST name the field). `Duration.zero` remains valid. | U3 | automated |
| FR-004 | 80 | - **FR-004**: `SubAgentSpec` MUST reject with `ArgumentError` the 1-cycle `extendsSpec == name`. | U4 | automated |
| FR-005 | 81 | - **FR-005**: The structural getters MUST keep their documented semantics: `isLeaf` == `subAgents.isEmpty`; `isRoot` == `extendsSpec == null`; `hasBudgets` == any of the three budget fields non-null. | U5 | automated |
| FR-006 | 82 | - **FR-006**: Equality/hashCode MUST keep field-wise value semantics across all ten fields (list-aware for `tools`/`subAgents`), and MUST be constructible with non-const lists without breaking equality. | U6 | automated |
| FR-007 | 83 | - **FR-007**: The clean-arch layers (`SubAgentSpecService.current/count`, `SubAgentSpecProvider`) MUST keep their existing signatures and stub behavior (UnimplementedError); no behavioral change to those layers in this feature. | U7 | automated |

