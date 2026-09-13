# Traceability: 29-tool_call_signature-datasource-pair

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:d67e82f24553c178d6084c9d2f6e797792dd7b537a96ae6de15391f88c1e5772
statements: 14
automated: 14
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** an empty store, **When** `capture(signature)` completes, **Then** a subsequent `lookup(signature.key)` returns the signature (round-trip). | A1 | automated |
| AC-2 | 27 | 2. **Given** an empty store, **When** `lookup` is called with any key, **Then** absence is reported (null / not-found — no throw, no phantom entry). | A2 | automated |
| AC-3 | 42 | 3. **Given** `('webview.browse', 'abc123', 1)` built twice, **Then** both signatures are equal, hash equally, and their keys are identical. | A3 | automated |
| AC-4 | 44 | 4. **Given** the same tool name and hash but version 2, **Then** the signature is unequal to the version-1 signature and its key differs. | A4 | automated |
| AC-5 | 46 | 5. **Given** `capture` of the same content twice, **Then** the store holds one entry (idempotent capture — dedup at the datasource level too). | A5 | automated |
| AC-6 | 61 | 6. **Given** 3 distinct signatures captured, **When** `count` is called, **Then** it returns 3. | A6 | automated |
| AC-7 | 63 | 7. **Given** any captured state, **When** `reset()` is called, **Then** `count` returns 0 and every `lookup` reports absence. | A7 | automated |
| FR-001 | 78 | - **FR-001**: The `ToolCallSignature` value object MUST carry `toolName`, `argumentHash`, `version` (default 1) with value equality and hashCode across all three fields. | U1 | automated |
| FR-002 | 79 | - **FR-002**: `ToolCallSignature` MUST derive `id`/`key` from content — a stable canonical string of the form `toolName@version:argumentHash` — identical for equal signatures, different for any differing component. | U2 | automated |
| FR-003 | 80 | - **FR-003**: Constructor backward compatibility MUST hold: `ToolCallSignature(id: ...)` from the anemic scaffold keeps compiling, and a content-only constructor derives the key automatically. | U3 | automated |
| FR-004 | 81 | - **FR-004**: The datasource interface MUST define the persistence contract: `capture(signature)`, `lookup(key)`, `count()`, `reset()` — all asynchronous; plus the scaffolded `current()`/`reset()` semantics folded into the refined surface. | U4 | automated |
| FR-005 | 82 | - **FR-005**: `capture` MUST be idempotent per key — duplicate captures of equal signatures do not grow the store. | U5 | automated |
| FR-006 | 83 | - **FR-006**: `lookup` MUST return the captured signature for a known key and absence (null) for an unknown key — never throw for misses. | U6 | automated |
| FR-007 | 84 | - **FR-007**: The mock datasource MUST implement the contract in memory: a key-addressed map, seeded empty, `reset` clearing all entries. | U7 | automated |

