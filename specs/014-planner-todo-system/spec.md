# Feature Specification: Planner/TODO System

**Feature Branch**: `014-planner-todo-system`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has no task decomposition; dart_agent_core has a write_todos tool with PlanState.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Write todos tool (Priority: P1)

As the model, I can create and update a structured to-do list via a `write_todos` tool, tracking my progress through complex tasks.

**Why this priority**: Task decomposition improves completion rates for multi-step missions.

**Independent Test**: A model writes 3 todos, completes 2, and the plan state reflects accurate progress.

**Acceptance Scenarios**:

1. **Given** a mission, **When** the model calls `write_todos`, **Then** the plan state is updated.
2. **Given** a plan with pending/in_progress/completed steps, **When** the state is queried, **Then** accurate counts are returned.

### User Story 2 - Plan mode (Priority: P1)

As an operator, I configure plan mode: `none` (no planner), `auto` (optional), or `must` (forced planning before execution).

**Why this priority**: Some missions require structured planning; others don't need the overhead.

**Independent Test**: With planMode=must, the engine injects planner tools and the model must plan before executing.

**Acceptance Scenarios**:

1. **Given** planMode=auto, **When** the mission starts, **Then** planner tools are available but optional.
2. **Given** planMode=must, **When** the mission starts, **Then** planning is required before execution.

### User Story 3 - Plan persistence (Priority: P2)

As the engine, the plan state persists across turns and is visible in the agent state.

**Why this priority**: Long missions need plan tracking across turns.

**Independent Test**: After 5 turns, the plan state accurately reflects completed and pending steps.

**Acceptance Scenarios**:

1. **Given** a plan updated at turn 3, **When** turn 5 starts, **Then** the plan state is preserved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `write_todos` tool MUST be injectable into the agent.
- **FR-002**: Plan state MUST track steps with status (pending, in_progress, completed, cancelled).
- **FR-003**: Plan mode MUST be configurable (none, auto, must).
- **FR-004**: Plan state MUST persist across turns.
- **FR-005**: Plan changes MUST emit PlanChangedEvent.

### Key Entities

- **Planner**: creates write_todos tool
- **PlanState**: steps, currentStep
- **PlanStep**: description, status
- **StepStatus**: pending, in_progress, completed, cancelled
- **PlanMode**: none, auto, must

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Model writes 3 todos; plan state reflects accurate progress.
- **SC-002**: Plan mode=must forces planning before execution.
- **SC-003**: Plan persists across 5+ turns.

## Dependencies

- After: spec 002 (engine integrates planner)
- Feeds: improves mission completion rates
