# Traceability: 056-sub_agent_instance

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:db6b039f0e4875a4f2ca30afd7345c2a21f44b6add3ca028c99b080cf6c48707
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstance equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstance inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider is a SubAgentInstanceService **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.current returns the active instance **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.current returns a supplied active instance **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** SubAgentInstanceProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/sub_agent_instance/sub_agent_instance_provider_test.dart`). | A6 | automated |

