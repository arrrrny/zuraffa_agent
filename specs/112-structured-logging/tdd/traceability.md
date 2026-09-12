# Traceability: 112-structured-logging

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:d05f49519d9f9a82db1f2fd06a014f8271ca12d10c447b97fd642b417290320b
statements: 15
automated: 15
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 67 | 1. **Given** `ZuraffaLogging.install(level: Level.INFO, onRecord: sink.add)` | A1 | automated |
| AC-2 | 73 | 2. **Given** no `install` call has been made, **When** subsystem code emits | A2 | automated |
| AC-3 | 77 | 3. **Given** `install` at `Level.WARNING`, **When** FINE and INFO records | A3 | automated |
| AC-4 | 96 | 4. **Given** the `AgentLog` level policy constants, **When** they are read, | A4 | automated |
| AC-5 | 100 | 5. **Given** an LLM client whose transport fails once and succeeds on | A5 | automated |
| AC-6 | 105 | 6. **Given** a mission run driven through `MissionRunner` with a scripted | A6 | automated |
| AC-7 | 125 | 7. **Given** ARCHITECTURE.md on master, **When** it is inspected, **Then** | A7 | automated |
| AC-8 | 130 | 8. **Given** the `lib/` tree, **When** it is searched for `print(`, | A8 | automated |
| FR-001 | 140 | - **FR-001**: `AgentLog` MUST expose the named subsystem loggers `llm`, | U1 | automated |
| FR-002 | 145 | - **FR-002**: The level policy MUST be pinned as facade constants — | U2 | automated |
| FR-003 | 150 | - **FR-003**: `ZuraffaLogging.install({level, onRecord})` MUST be the only | U3 | automated |
| FR-004 | 156 | - **FR-004**: Emission MUST be safe and cheap before install: no listener | U4 | automated |
| FR-005 | 160 | - **FR-005**: The first adoption sites MUST ship with this spec: the LLM | U5 | automated |
| FR-006 | 165 | - **FR-006**: ARCHITECTURE.md MUST document the logger hierarchy, the | U6 | automated |
| FR-003 | 199 | FR-003, FR-004). | U3 | automated |

