# Traceability: 114-jsonl-single-writer-streaming

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:3672b62c636c5c6f221a526575074c73f81a6882adc33cf169636b1f89a51fff
statements: 8
automated: 8
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 58 | 1. **Given** two stores appending to one JSONL path interleaved, | A1 | automated |
| AC-2 | 62 | 2. **Given** a store with a held `SessionLock` sidecar, **When** a second | A2 | automated |
| AC-3 | 80 | 3. **Given** a JSONL store with several entries, **When** `entries()` is | A3 | automated |
| AC-4 | 83 | 4. **Given** Hive and in-memory stores with entries, **When** `entries()` | A4 | automated |
| FR-001 | 91 | - **FR-001**: Every `JsonlSessionStorage` mutation (`appendEntry`, | U1 | automated |
| FR-002 | 95 | - **FR-002**: `JsonlSessionStorage.init` MUST acquire an advisory | U2 | automated |
| FR-003 | 100 | - **FR-003**: `SessionStorage.entries()` MUST return a lazy | U3 | automated |
| FR-004 | 105 | - **FR-004**: Hive persistence MUST document its single-writer | U4 | automated |

