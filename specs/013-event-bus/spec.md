# Feature Specification: Event Bus

**Feature Branch**: `013-event-bus`

**Created**: 2026-08-27

**Status**: Draft

**Input**: Gap analysis vs dart_agent_core — zuraffa_agent has EngineEvent sealed hierarchy but no general pub/sub event bus; dart_agent_core has EventBus with pub/sub and request/response patterns.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pub/sub events (Priority: P1)

As a plugin developer, I can subscribe to typed events emitted by the agent (started, chunk, tool call, error, etc.) without modifying the engine.

**Why this priority**: Observability and plugin integration require a decoupled event system.

**Independent Test**: A subscriber receives all AgentStartedEvent, LLMChunkEvent, and AfterToolCallEvent during a mission.

**Acceptance Scenarios**:

1. **Given** a subscriber to LLMChunkEvent, **When** the model streams, **Then** each chunk event is delivered.
2. **Given** multiple subscribers, **When** an event fires, **Then** all subscribers receive it.

### User Story 2 - Request/response pattern (Priority: P2)

As a plugin developer, I can handle request/response events where the handler returns a typed response to the emitter.

**Why this priority**: Some events need synchronous responses (e.g., modifying a tool call).

**Independent Test**: A handler modifies a BeforeToolCallRequest and returns the modification.

**Acceptance Scenarios**:

1. **Given** a registered handler for BeforeToolCallRequest, **When** the event fires, **Then** the handler's response is used.

### User Story 3 - Controller convenience (Priority: P2)

As a developer, an `AgentController` wraps the event bus with convenience methods: publish(), listen(), request().

**Why this priority**: Simplifies event usage for common patterns.

**Independent Test**: Controller.publish() and controller.listen() work identically to EventBus.

**Acceptance Scenarios**:

1. **Given** an AgentController, **When** publish is called, **Then** all listeners receive the event.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: An `EventBus` MUST support typed pub/sub (on<T>, emit<T>).
- **FR-002**: An `EventBus` MUST support typed request/response (request<R>, registerHandler<T,R>).
- **FR-003**: Events MUST be delivered synchronously in registration order.
- **FR-004**: An `AgentController` MUST wrap EventBus with convenience methods.
- **FR-005**: The engine MUST emit lifecycle events through the bus.

### Key Entities

- **EventBus**: on<T>(), emit<T>(), request<R>(), registerHandler<T,R>()
- **AgentController**: publish(), listen<T>(), request(), on<T>()
- **Event types**: AgentStartedEvent, LLMChunkEvent, BeforeToolCallEvent, etc.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A subscriber receives all typed events during a mission.
- **SC-002**: Request/response pattern works for tool call modification.
- **SC-003**: Controller convenience methods work identically to EventBus.

## Dependencies

- After: spec 002 (engine emits events through bus)
- Feeds: spec 012 (hooks may use events), observability integrations
