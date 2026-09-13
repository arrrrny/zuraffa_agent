# Traceability: 113-eventbus-error-observability

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:b6c9df2581f54b69c9688d11bef09ead19217405bdc452c2ffa9dcd34a4d0c29
statements: 9
automated: 9
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 58 | 1. **Given** a bus with no `onSubscriberError` hook, **When** a | A1 | automated |
| AC-2 | 64 | 2. **Given** a bus with a consumer-provided `onSubscriberError` hook, | A2 | automated |
| AC-3 | 88 | 3. **Given** a subscriber to `EngineEventSubscriberError`, **When** a | A3 | automated |
| AC-4 | 93 | 4. **Given** the failing event is itself an | A4 | automated |
| AC-5 | 98 | 5. **Given** an `onSubscriberError` hook that itself throws, **When** a | A5 | automated |
| FR-001 | 108 | - **FR-001**: With no consumer hook installed, the bus MUST route | U1 | automated |
| FR-002 | 112 | - **FR-002**: A consumer-provided `onSubscriberError` hook MUST fully | U2 | automated |
| FR-003 | 116 | - **FR-003**: After the error route runs, the bus MUST publish an | U3 | automated |
| FR-004 | 122 | - **FR-004**: A throwing hook or a throwing subscriber of the | U4 | automated |

