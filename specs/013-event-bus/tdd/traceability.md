# Traceability: 013-event-bus

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:6d90dbd5fa1ba555b4c80f80bf5f90f7d30099ce53c8e81591064af66351688d
statements: 9
automated: 9
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a subscriber to LLMChunkEvent, **When** the model streams, **Then** each chunk event is delivered. | A1 | automated |
| AC-2 | 27 | 2. **Given** multiple subscribers, **When** an event fires, **Then** all subscribers receive it. | A2 | automated |
| AC-3 | 40 | 3. **Given** a registered handler for BeforeToolCallRequest, **When** the event fires, **Then** the handler's response is used. | A3 | automated |
| AC-4 | 53 | 4. **Given** an AgentController, **When** publish is called, **Then** all listeners receive the event. | A4 | automated |
| FR-001 | 60 | - **FR-001**: An `EventBus` MUST support typed pub/sub (on<T>, emit<T>). | U1 | automated |
| FR-002 | 61 | - **FR-002**: An `EventBus` MUST support typed request/response (request<R>, registerHandler<T,R>). | U2 | automated |
| FR-003 | 62 | - **FR-003**: Events MUST be delivered synchronously in registration order. | U3 | automated |
| FR-004 | 63 | - **FR-004**: An `AgentController` MUST wrap EventBus with convenience methods. | U4 | automated |
| FR-005 | 64 | - **FR-005**: The engine MUST emit lifecycle events through the bus. | U5 | automated |

