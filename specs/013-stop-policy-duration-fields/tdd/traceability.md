# Traceability: 013-stop-policy-duration-fields

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:1003ed8e27b47cd7bbf0ab480220d755a55f9486fa31905de7430ad974244659
statements: 4
automated: 4
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 27 | 1. **Given** the feature implementation under its clean-architecture seams **When** U4: StopPolicyMockDatasource is a StopPolicyDatasource **Then** the pinned regression test passes (`test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`). | A1 | automated |
| AC-2 | 29 | 2. **Given** the feature implementation under its clean-architecture seams **When** U5: a fresh mock current() returns StopPolicy.defaultPolicy **Then** the pinned regression test passes (`test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`). | A2 | automated |
| AC-3 | 31 | 3. **Given** the feature implementation under its clean-architecture seams **When** A3 + U6: update(policy) then current() returns exactly the policy written **Then** the pinned regression test passes (`test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`). | A3 | automated |
| AC-4 | 33 | 4. **Given** the feature implementation under its clean-architecture seams **When** U7: reset() on the mock restores the default **Then** the pinned regression test passes (`test/data/datasources/stop_policy/stop_policy_mock_datasource_test.dart`). | A4 | automated |

