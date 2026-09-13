# Traceability: 110-session-schema-versioning

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:fba2e58ec43b1fc1cbf88e93b6898d80d58c414a2273a77e80655c0837369e22
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 70 | 1. **Given** a v1 fixture file (no header, entry maps without version stamps), **When** it opens, **Then** every entry is readable in memory, the open reports `schemaVersion: 3` / `migratedFromVersion: 1`, and the file on disk now carries the v3 header. | A1 | automated |
| AC-2 | 82 | 2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged. | A2 | automated |
| AC-3 | 90 | 2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged. | A3 | automated |
| AC-4 | 104 | 2. **Given** a v3 file, **When** it opens, **Then** the result reports `schemaVersion: 3` with no `migratedFromVersion` and the entries load unchanged. | A4 | automated |
| FR-001 | 107 | - **FR-001**: legacy JSONL files (no header) are treated as v1, | U5 | automated |
| FR-002 | 111 | - **FR-002**: current-version JSONL files open without migration; | U6 | automated |
| FR-003 | 114 | - **FR-003**: new JSONL stores write the header on first init; new | U9 | automated |
| FR-004 | 117 | - **FR-004**: `SessionMigrator` exposes the ordered registry | U7 | automated |
| FR-005 | 121 | - **FR-005**: `StoreOpenResult` carries `schemaVersion` and, when a | U5 | automated |
| FR-006 | 124 | - **FR-006**: the migration policy (version constant, header shape, | U6 | automated |

