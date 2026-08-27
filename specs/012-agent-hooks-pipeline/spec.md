# Feature Specification: Agent Hooks Pipeline

**Feature Branch**: `012-agent-hooks-pipeline`

**Created**: 2026-08-27

**Status**: Approved *(refined by /speckit.specify — added acceptance-criterion ids AC-1..AC-8; pinned the typed context/result surface for all 9 hook points; pinned chaining semantics (sequential fold in registration order, each hook sees the previous hook's modifications); pinned the abort contract (HookAbortError thrown at the offending hook, later hooks skipped); pinned the deny contract (ToolCallDecision carries a synthetic result, tool not executed) and the retry contract (ModelCallDecision.retry → engine calls the LLM again); scoped engine-loop wiring to spec 002 — this spec ships the pipeline and proves engine-visible effects through a scripted test driver)*

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has no lifecycle hooks; dart_agent_core has a 9-point pipeline for plugin extensibility.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lifecycle hook points (Priority: P1)

As a plugin developer, I can intercept and modify agent behavior at 9 lifecycle points: beforeRun, beforeModelCall, onModelChunk, afterModelCall, beforeToolCall, afterToolCall, onTurnCompletion, beforePersistState, afterRun.

**Why this priority**: Hooks enable plugins, middleware, and custom behavior without modifying engine internals.

**Independent Test**: A logging hook captures all 9 lifecycle events during a mission.

**Acceptance Scenarios**:

1. **Given** a registered hook, **When** the pipeline runs the 9 lifecycle points, **Then** the hook is called at each point with the point's typed context. **[AC-1]**
2. **Given** a hook that modifies the model call, **When** beforeModelCall fires, **Then** the modified request is what the pipeline hands back to the engine (and the engine's LlmClient receives it). **[AC-2]**
3. **Given** a hook that denies a tool call, **When** beforeToolCall fires, **Then** a synthetic result is returned without executing the tool. **[AC-3]**

### User Story 2 - Hook pipeline chaining (Priority: P1)

As the engine, hooks are chained sequentially; each hook can modify the context passed to the next, and any hook can abort the run.

**Why this priority**: Multiple plugins must compose without conflicts.

**Independent Test**: Two hooks — one logging, one modifying — compose correctly; the modifier's changes are visible to the engine.

**Acceptance Scenarios**:

1. **Given** two hooks, **When** the pipeline runs, **Then** both are called in registration order at every point. **[AC-4]**
2. **Given** a hook that aborts, **When** it fires, **Then** the run stops with a typed error (HookAbortError carrying the hook name and reason) and later hooks are not called. **[AC-5]**
3. **Given** hook A modifies the context, **When** hook B runs after it, **Then** B observes A's modification (sequential fold). **[AC-6]**

### User Story 3 - Hook results (Priority: P2)

As a plugin developer, each hook point has a typed result that controls engine behavior: continue, modify, deny, abort, or retry.

**Why this priority**: Typed results prevent ambiguous hook behavior.

**Independent Test**: A beforeToolCall hook returns a deny result; the tool is not executed.

**Acceptance Scenarios**:

1. **Given** a beforeToolCall hook returning deny, **When** the tool call reaches the hook, **Then** a synthetic result is returned and the tool is not executed. **[AC-3 — same scenario pinned from the result side]**
2. **Given** an afterModelCall hook returning retry, **When** the hook fires, **Then** the engine calls the LLM again. **[AC-7]**
3. **Given** default (un-overridden) hook methods, **When** the pipeline runs, **Then** every point continues with the context unmodified (a bare hook is a no-op). **[AC-8]**

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The engine MUST support registering multiple hooks per lifecycle point.
- **FR-002**: Hooks MUST be called in registration order at each lifecycle point.
- **FR-003**: Each hook point MUST have typed context and result classes.
- **FR-004**: Any hook MUST be able to abort the run with a typed error.
- **FR-005**: Hooks MUST be able to modify model calls, tool calls, and tool results.

### Key Entities

- **AgentHook** (abstract): 9 hook methods — beforeRun, beforeModelCall, onModelChunk, afterModelCall, beforeToolCall, afterToolCall, onTurnCompletion, beforePersistState, afterRun — each with a default implementation returning the continue result (plugins override only what they need).
- **AgentHookPipeline**: chains hooks sequentially (registration order), folds modifications (each hook sees the previous hook's output), throws `HookAbortError` on abort, and returns point-specific decisions where the engine must branch (deny → synthetic tool result; retry → call the LLM again).
- **HookContext classes**: BeforeRunHookContext (runId, messages), ModelCallHookContext (request), ModelChunkHookContext (chunk), AfterModelCallHookContext (request, response), ToolCallHookContext (toolCall), AfterToolCallHookContext (toolCall, result, isError), TurnCompletionHookContext (turnNumber, messages), PersistStateHookContext (messages), AfterRunHookContext (finalMessages, outcome).
- **HookResult classes**: one per point — BeforeRunHookResult (continue/modify/abort), ModelCallHookResult (continue/modify/abort), ModelChunkHookResult (continue/abort), AfterModelCallHookResult (continue/modify/retry/abort), ToolCallHookResult (continue/modify/deny/abort + synthetic deny result), AfterToolCallHookResult (continue/modify/abort), TurnCompletionHookResult (continue/abort), PersistStateHookResult (continue/modify/abort), AfterRunHookResult (continue).
- **HookAbortError**: the typed abort error — hookName + reason (FR-004).
- **ToolCallDecision / ModelCallDecision**: pipeline decision envelopes — deny carries the synthetic tool result without executing; retry tells the engine to call the LLM again.
- Model/tool value types are the existing engine contracts: `LlmRequest`/`LlmResponse`/`LlmResponseChunk`/`LlmToolCall` (spec 007) and `AgentMessage` (types.dart).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A logging hook captures all 9 lifecycle events during a scripted mission driven through the pipeline.
- **SC-002**: A modifier hook changes model call parameters; the driver engine's LlmClient receives the modified parameters.
- **SC-003**: An abort hook stops the run with HookAbortError (typed, carries hook name + reason); later hooks are not invoked.
- **SC-004**: `dart analyze` reports zero issues in files added by this feature; the full suite adds no new failures vs. the spec-011-loop baseline (+486 passed / 6 unrelated pre-existing loading failures).

## Dependencies

- After: spec 002 (engine loop integration points — THIS spec ships the pipeline; the engine wiring lands with spec 002)
- Feeds: plugins, middleware, observability integrations

## Assumptions

- The engine (spec 002) will call the pipeline at each lifecycle point; here, engine-visible effects (modified request used for the LLM call, retry loop, deny short-circuit) are proven through a scripted test driver that plays the engine role.
- `onModelChunk` is the streaming hook: it observes each `LlmResponseChunk`; its result supports continue/abort (a mid-stream abort surfaces as HookAbortError, which the engine translates into its stream-error handling).
- `afterRun` is terminal observation: its only action is continue — a completed run cannot be modified, only observed (logging/telemetry).
- All pipeline methods are async (hooks may perform I/O — e.g. an audit-logging plugin); the engine awaits them.
- Registration is dynamic (hooks can be registered while running; later lifecycle points see them — insertion order governs call order at each point).
