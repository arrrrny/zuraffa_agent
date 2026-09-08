# Traceability: 014-planner-todo-system

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:ea1d1043569970890fcf694067518abf96bfc2c9aa25bd26ff9507f95cea59de
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a mission, **When** the model calls `write_todos`, **Then** the plan state is updated. | A1 | automated |
| AC-2 | 27 | 2. **Given** a plan with pending/in_progress/completed steps, **When** the state is queried, **Then** accurate counts are returned. | A2 | automated |
| AC-3 | 40 | 3. **Given** planMode=auto, **When** the mission starts, **Then** planner tools are available but optional. | A3 | automated |
| AC-4 | 42 | 4. **Given** planMode=must, **When** the mission starts, **Then** planning is required before execution. | A4 | automated |
| AC-5 | 55 | 5. **Given** a plan updated at turn 3, **When** turn 5 starts, **Then** the plan state is preserved. | A5 | automated |
| FR-001 | 62 | - **FR-001**: A `write_todos` tool MUST be injectable into the agent. | U1 | automated |
| FR-002 | 63 | - **FR-002**: Plan state MUST track steps with status (pending, in_progress, completed, cancelled). | U2 | automated |
| FR-003 | 64 | - **FR-003**: Plan mode MUST be configurable (none, auto, must). | U3 | automated |
| FR-004 | 65 | - **FR-004**: Plan state MUST persist across turns. | U4 | automated |
| FR-005 | 66 | - **FR-005**: Plan changes MUST emit PlanChangedEvent. | U5 | automated |

