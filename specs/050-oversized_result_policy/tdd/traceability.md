# Traceability: 050-oversized_result_policy

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:2ac8c8d701e63f19b4d394ec7eb8243676f26f38e590c941df6768e125938714
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicy equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicy inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicyProvider is a OversizedResultPolicyService **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicyProvider.current returns the active policy **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicyProvider honors an injected active policy **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** OversizedResultPolicyProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/oversized_result_policy/oversized_result_policy_provider_test.dart`). | A6 | automated |

