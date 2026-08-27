# Feature Specification: Agent Hooks Pipeline

**Feature Branch**: `012-agent-hooks-pipeline`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has no lifecycle hooks; dart_agent_core has a 9-point pipeline for plugin extensibility.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lifecycle hook points (Priority: P1)

As a plugin developer, I can intercept and modify agent behavior at 9 lifecycle points: beforeRun, beforeModelCall, onModelChunk, afterModelCall, beforeToolCall, afterToolCall, onTurnCompletion, beforePersistState, afterRun.

**Why this priority**: Hooks enable plugins, middleware, and custom behavior without modifying engine internals.

**Independent Test**: A logging hook captures all 9 lifecycle events during a mission.

**Acceptance Scenarios**:

1. **Given** a registered hook, **When** the engine runs, **Then** the hook is called at each lifecycle point.
2. **Given** a hook that modifies the model call, **When** beforeModelCall fires, **Then** the modified request is used.
3. **Given** a hook that denies a tool call, **When** beforeToolCall fires, **Then** a synthetic result is returned without executing the tool.

### User Story 2 - Hook pipeline chaining (Priority: P1)

As the engine, hooks are chained sequentially; each hook can modify the context passed to the next, and any hook can abort the run.

**Why this priority**: Multiple plugins must compose without conflicts.

**Independent Test**: Two hooks — one logging, one modifying — compose correctly; the modifier's changes are visible to the engine.

**Acceptance Scenarios**:

1. **Given** two hooks, **When** the engine runs, **Then** both are called in registration order.
2. **Given** a hook that aborts, **When** it fires, **Then** the run stops with a typed error.

### User Story 3 - Hook results (Priority: P2)

As a plugin developer, each hook point has a typed result that controls engine behavior: continue, modify, deny, abort, or retry.

**Why this priority**: Typed results prevent ambiguous hook behavior.

**Independent Test**: A beforeToolCall hook returns a deny result; the tool is not executed.

**Acceptance Scenarios**:

1. **Given** a beforeToolCall hook returning deny, **When** the tool call reaches the hook, **Then** a synthetic result is returned.
2. **Given** an afterModelCall hook returning retry, **When** the hook fires, **Then** the LLM is called again.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST support registering multiple hooks per lifecycle point.
- **FR-002**: Hooks MUST be called in registration order at each lifecycle point.
- **FR-003**: Each hook point MUST have typed context and result classes.
- **FR-004**: Any hook MUST be able to abort the run with a typed error.
- **FR-005**: Hooks MUST be able to modify model calls, tool calls, and tool results.

### Key Entities

- **AgentHook** (abstract): 9 hook methods
- **AgentHookPipeline**: chains hooks, passes modified context
- **HookContext classes**: BeforeRunHookContext, ModelCallHookContext, etc.
- **HookResult classes**: BeforeRunHookResult, ModelCallHookResult, etc.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A logging hook captures all 9 lifecycle events.
- **SC-002**: A modifier hook changes model call parameters; the engine uses modified parameters.
- **SC-003**: An abort hook stops the run with a typed error.

## Dependencies

- After: spec 002 (engine loop integration points)
- Feeds: plugins, middleware, observability integrations
