# Traceability: 055-sub_agent_context

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:f69aeed498ee801d2686982ebc006db40687f5cc482dc656d2948f4c85ca1997
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContext equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContext inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContextProvider is a SubAgentContextService **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContextProvider.current returns the active context **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContextProvider.current returns a supplied active context **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** SubAgentContextProvider.count returns the tracked context count **Then** the pinned regression test passes (`test/data/providers/sub_agent_context/sub_agent_context_provider_test.dart`). | A6 | automated |

