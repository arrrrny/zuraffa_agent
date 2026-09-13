# Traceability: 057-yaml_agent_spec

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:e37c076bc3316201161282a54f9d20c6d3544bb6861b65185147700d35658f53
statements: 8
automated: 8
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpec equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpec inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider is a YamlAgentSpecService **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider.current returns the active agent spec **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** YamlAgentSpecProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A6 | automated |
| AC-7 | 41 | 7. **Given** the feature implementation under its clean-architecture seams **When** a spec referencing an unknown tool fails validation with a precise error **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A7 | automated |
| AC-8 | 43 | 8. **Given** the feature implementation under its clean-architecture seams **When** a spec with cyclic inheritance fails validation with a precise error **Then** the pinned regression test passes (`test/data/providers/yaml_agent_spec/yaml_agent_spec_provider_test.dart`). | A8 | automated |

