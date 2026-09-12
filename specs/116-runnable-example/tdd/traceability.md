# Traceability: 116-runnable-example

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:10db0a6ae663063274267d5bf759bf3d234e378f38d35fef36a4020c7930f2b8
statements: 5
automated: 5
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 46 | 1. **Given** the repo checked out, **When** `dart run | A1 | automated |
| AC-2 | 50 | 2. **Given** the example source, **When** it is read, **Then** it | A2 | automated |
| FR-001 | 58 | - **FR-001**: The example MUST run a full mission through `MissionRunner` | U1 | automated |
| FR-002 | 62 | - **FR-002**: The example MUST print the mission lifecycle (start, | U2 | automated |
| FR-003 | 66 | - **FR-003**: A test MUST execute the example as a subprocess and assert | U3 | automated |

