# Traceability: 075-engine-event-bus

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:9c876c70450a24337f9154b57a903b54799f218a4a4c49fdad0c079fc76e2c2d
statements: 18
automated: 18
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-002 | 31 | - **FR-002**: The system MUST satisfy this requirement: request/response (registerHandler / request)**: the draft's | U1, U5 | automated |
| FR-004 | 35 | - **FR-004**: The system MUST satisfy this requirement: `AgentController`**: with request/response deferred, the | U2, U7 | automated |
| FR-005 | 37 | - **FR-005**: "engine MUST emit through the bus"**: the runtimes (PRs | U3, U8 | automated |
| FR-001 | 53 | - **FR-001**: The system MUST satisfy this requirement: Typed subscription: `subscribe<T extends EngineEvent>( | U4 | automated |
| FR-002 | 60 | - **FR-002**: The system MUST satisfy this requirement: `publish(EngineEvent event)`: synchronous delivery, in | U1, U5 | automated |
| FR-003 | 65 | - **FR-003**: The system MUST satisfy this requirement: Subscriber error isolation: a handler that throws must | U6 | automated |
| FR-004 | 73 | - **FR-004**: The system MUST satisfy this requirement: `cancel()` stops delivery (idempotent — double cancel is | U2, U7 | automated |
| FR-005 | 77 | - **FR-005**: The system MUST satisfy this requirement: `replay(Iterable<EngineEvent> events)`: re-publishes the | U3, U8 | automated |
| FR-006 | 83 | - **FR-006**: The system MUST satisfy this requirement: `subscriberCount`: the number of live subscriptions. | U9 | automated |
| FR-007 | 85 | - **FR-007**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` | U10 | automated |
| AC-1 | 112 | 1. **Given** the feature implementation under its clean-architecture seams **When** typed subscriptions filter by exact runtime type **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A1 | automated |
| AC-2 | 113 | 2. **Given** the feature implementation under its clean-architecture seams **When** delivery follows registration order **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A2 | automated |
| AC-3 | 114 | 3. **Given** the feature implementation under its clean-architecture seams **When** one publish fans out to many subscribers **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A3 | automated |
| AC-4 | 115 | 4. **Given** the feature implementation under its clean-architecture seams **When** a throwing subscriber never breaks delivery **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A4 | automated |
| AC-5 | 116 | 5. **Given** the feature implementation under its clean-architecture seams **When** cancel stops delivery and frees the slot **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A5 | automated |
| AC-6 | 117 | 6. **Given** the feature implementation under its clean-architecture seams **When** subscriberCount tracks live subscriptions **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A6 | automated |
| AC-7 | 118 | 7. **Given** the feature implementation under its clean-architecture seams **When** replay broadcasts history to current subscribers **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A7 | automated |
| AC-8 | 119 | 8. **Given** the feature implementation under its clean-architecture seams **When** onEvent bridge: any emitter becomes a multi-subscriber source **Then** the pinned regression test passes (`test/engine/engine_event_bus_test.dart`). | A8 | automated |

