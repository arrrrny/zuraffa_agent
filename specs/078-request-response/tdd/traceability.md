# Traceability: 078-request-response

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:bbf6c5e4401cc1b73888c6ce7207066fd9a81e9ed880e03192f94f36d5400a5f
statements: 17
automated: 17
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 86 | - **FR-001**: `AgentController.request<R>(event)` MUST delegate to the | U1 | automated |
| FR-002 | 89 | - **FR-002**: `AgentController.on<T>(listener)` MUST subscribe exactly | U2 | automated |
| FR-003 | 91 | - **FR-003**: `AgentController` MUST expose its wrapped `EventBus` | U3 | automated |
| FR-004 | 94 | - **FR-004**: The system MUST satisfy this requirement: (bus semantics, pinned): when multiple handlers are | U4 | automated |
| FR-005 | 97 | - **FR-005**: (bus semantics, pinned): a handler exception MUST propagate | U5 | automated |
| FR-006 | 99 | - **FR-006**: The system MUST satisfy this requirement: (bus semantics, pinned): `request` with no registered | U6 | automated |
| FR-007 | 101 | - **FR-007**: (bus semantics, pinned): the response cast MUST be honest — | U7 | automated |
| FR-008 | 104 | - **FR-008**: The system MUST satisfy this requirement: (bus semantics, pinned): handlers registered after earlier | U8 | automated |
| FR-009 | 107 | - **FR-009**: The system MUST satisfy this requirement: Gates — `dart analyze --fatal-infos` exit 0; full `dart | U9 | automated |
| AC-1 | 137 | 1. **Given** the feature implementation under its clean-architecture seams **When** controller.request round-trips a typed handler response **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A1 | automated |
| AC-2 | 138 | 2. **Given** the feature implementation under its clean-architecture seams **When** controller.on is an alias for listen **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A2 | automated |
| AC-3 | 139 | 3. **Given** the feature implementation under its clean-architecture seams **When** controller.request behaves identically to bus.request **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A3 | automated |
| AC-4 | 140 | 4. **Given** the feature implementation under its clean-architecture seams **When** the last registered handler responds **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A4 | automated |
| AC-5 | 141 | 5. **Given** the feature implementation under its clean-architecture seams **When** handler exceptions propagate to the requester **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A5 | automated |
| AC-6 | 142 | 6. **Given** the feature implementation under its clean-architecture seams **When** request with no handler throws StateError **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A6 | automated |
| AC-7 | 143 | 7. **Given** the feature implementation under its clean-architecture seams **When** a wrong response type surfaces as a TypeError **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A7 | automated |
| AC-8 | 144 | 8. **Given** the feature implementation under its clean-architecture seams **When** registration is live and types dispatch independently **Then** the pinned regression test passes (`test/events/request_response_test.dart`). | A8 | automated |

