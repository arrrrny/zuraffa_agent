# Traceability: 070-sub-agent-dispatch-runtime

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:d95763cb84859ffbbe4e5ae793cb70eb8913154f2264104d139d8fa245b7af43
statements: 21
automated: 21
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 39 | - **FR-001**: The system MUST satisfy this requirement: Isolated child context: `dispatch(spec, mission, instance)` | U1 | automated |
| FR-002 | 47 | - **FR-002**: The system MUST satisfy this requirement: Tool allowlist enforcement: the child's tool dispatch is | U2 | automated |
| FR-003 | 56 | - **FR-003**: The system MUST satisfy this requirement: Budgets: the child `EngineLoop`/`StopPolicy` pair is built | U3 | automated |
| FR-004 | 61 | - **FR-004**: The system MUST satisfy this requirement: Instance bookkeeping: a completed dispatch (any run status) | U4 | automated |
| FR-005 | 65 | - **FR-005**: The system MUST satisfy this requirement: Risk tier gate: when `spec.riskTier == RiskTier.admin` and | U5 | automated |
| FR-006 | 71 | - **FR-006**: The system MUST satisfy this requirement: Event forwarding: the child mission's `EngineEvent`s flow to | U6 | automated |
| FR-007 | 75 | - **FR-007**: The system MUST satisfy this requirement: `SubAgentDispatchResult` is a house-pattern value object | U7 | automated |
| FR-008 | 81 | - **FR-008**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green | U8 | automated |
| AC-1 | 108 | 1. **Given** the feature implementation under its clean-architecture seams **When** delegates allowlisted calls **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A1 | automated |
| AC-2 | 109 | 2. **Given** the feature implementation under its clean-architecture seams **When** refuses non-allowlisted calls without touching the inner dispatcher **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A2 | automated |
| AC-3 | 110 | 3. **Given** the feature implementation under its clean-architecture seams **When** batch enforces the allowlist per call **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A3 | automated |
| AC-4 | 111 | 4. **Given** the feature implementation under its clean-architecture seams **When** child runs in an isolated context and returns only a summary **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A4 | automated |
| AC-5 | 112 | 5. **Given** the feature implementation under its clean-architecture seams **When** tool allowlist is enforced at the dispatch boundary **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A5 | automated |
| AC-6 | 113 | 6. **Given** the feature implementation under its clean-architecture seams **When** spec maxTurns budget caps the child mission **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A6 | automated |
| AC-7 | 114 | 7. **Given** the feature implementation under its clean-architecture seams **When** completed dispatch updates the instance bookkeeping **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A7 | automated |
| AC-8 | 115 | 8. **Given** the feature implementation under its clean-architecture seams **When** admin-risk spec is refused without a grant **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A8 | automated |
| AC-9 | 116 | 9. **Given** the feature implementation under its clean-architecture seams **When** admin-risk spec runs with an explicit grant **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A9 | automated |
| AC-10 | 117 | 10. **Given** the feature implementation under its clean-architecture seams **When** child events forward with the instance id as mission id **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A10 | automated |
| AC-11 | 118 | 11. **Given** the feature implementation under its clean-architecture seams **When** spec wallClockTimeout caps the child mission **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A11 | automated |
| AC-12 | 119 | 12. **Given** the feature implementation under its clean-architecture seams **When** provider failure maps MissionStatus.providerFailed to providerFailed **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A12 | automated |
| AC-13 | 120 | 13. **Given** the feature implementation under its clean-architecture seams **When** SubAgentDispatchResult value semantics and context snapshot **Then** the pinned regression test passes (`test/engine/sub_agent_dispatch_test.dart`). | A13 | automated |

