# Traceability: 069-mission-runner

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:c9aaae66799d76b39ee1719d1ab72a38b5261a2fb2df78dd5e9d9477eb48c814
statements: 18
automated: 18
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 53 | - **FR-001**: The system MUST satisfy this requirement: `MissionRunner.run({missionId, messages, planner?})` emits, in | U1 | automated |
| FR-002 | 64 | - **FR-002**: The system MUST satisfy this requirement: Natural completion: when a turn's `finishReason == 'stop'` and | U2 | automated |
| FR-003 | 68 | - **FR-003**: The system MUST satisfy this requirement: Tool dispatch: each planned `ToolCall` is dispatched | U3 | automated |
| FR-004 | 76 | - **FR-004**: The system MUST satisfy this requirement: Steering drain: when constructed with a `SteeringQueue`, all | U4 | automated |
| FR-005 | 81 | - **FR-005**: The system MUST satisfy this requirement: Budgets (from `StopPolicy`, when `enabled`): effective turn cap | U5 | automated |
| FR-006 | 89 | - **FR-006**: The system MUST satisfy this requirement: Provider failure: if `executor.runTurn` throws, the runner | U6 | automated |
| FR-007 | 94 | - **FR-007**: The system MUST satisfy this requirement: `MissionResult` carries value semantics (spec 066 house | U7 | automated |
| FR-008 | 98 | - **FR-008**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green | U8 | automated |
| AC-1 | 123 | 1. **Given** the feature implementation under its clean-architecture seams **When** natural single-turn mission emits the full ordered event sequence **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A1 | automated |
| AC-2 | 124 | 2. **Given** the feature implementation under its clean-architecture seams **When** natural completion returns completed status, summary, and grown transcript **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A2 | automated |
| AC-3 | 125 | 3. **Given** the feature implementation under its clean-architecture seams **When** tool dispatch round-trip emits correlated events and feeds results back **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A3 | automated |
| AC-4 | 126 | 4. **Given** the feature implementation under its clean-architecture seams **When** failed tool dispatch reports ok:false and the error text, mission continues **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A4 | automated |
| AC-5 | 127 | 5. **Given** the feature implementation under its clean-architecture seams **When** steering queue drains at turn start in FIFO order **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A5 | automated |
| AC-6 | 128 | 6. **Given** the feature implementation under its clean-architecture seams **When** maxTurns budget stops the mission before the executor backstop **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A6 | automated |
| AC-7 | 129 | 7. **Given** the feature implementation under its clean-architecture seams **When** wall-clock deadline stops the mission between turns **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A7 | automated |
| AC-8 | 130 | 8. **Given** the feature implementation under its clean-architecture seams **When** provider failure emits ProviderError and still closes the mission **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A8 | automated |
| AC-9 | 131 | 9. **Given** the feature implementation under its clean-architecture seams **When** MissionResult value semantics **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A9 | automated |
| AC-10 | 132 | 10. **Given** the feature implementation under its clean-architecture seams **When** planner receives an unmodifiable transcript view **Then** the pinned regression test passes (`test/engine/mission_runner_test.dart`). | A10 | automated |

