# Traceability: 014-stop-policy-clean-arch-layers

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:c1e108acabe8ed7af576a5d3fa5dacd4c9e66b4f2a682f76422aaf3386e8efec
statements: 7
automated: 7
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 31 | 1. **Given** the feature implementation under its clean-architecture seams **When** U10: StopPolicyProvider is a StopPolicyService **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A1 | automated |
| AC-2 | 33 | 2. **Given** the feature implementation under its clean-architecture seams **When** U11: parameterless StopPolicyProvider() keeps compiling (default wiring) **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A2 | automated |
| AC-3 | 35 | 3. **Given** the feature implementation under its clean-architecture seams **When** A1: a fresh chain returns the default policy from current() **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A3 | automated |
| AC-4 | 37 | 4. **Given** the feature implementation under its clean-architecture seams **When** A2 + A5: a policy seeded into the datasource is served by current(NoParams()) **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A4 | automated |
| AC-5 | 39 | 5. **Given** the feature implementation under its clean-architecture seams **When** A4: reset() restores the documented default through the whole chain **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A5 | automated |
| AC-6 | 41 | 6. **Given** the feature implementation under its clean-architecture seams **When** U12: defaultPolicy(NoParams) returns the canonical constant **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A6 | automated |
| AC-7 | 43 | 7. **Given** the feature implementation under its clean-architecture seams **When** A5: the provider serves reads through the datasource seam **Then** the pinned regression test passes (`test/data/providers/stop_policy/stop_policy_provider_test.dart`). | A7 | automated |

