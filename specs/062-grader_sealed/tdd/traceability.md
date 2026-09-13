# Traceability: 062-grader_sealed

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:c95c515e5966377ef1edc0cce8930b9339ce8662f2734b71c8edaba0997efeff
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** GraderSealed equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** GraderSealed inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider is a GraderSealedService **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.current returns the active grader snapshot **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.current honors an injected snapshot **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** GraderSealedProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/grader_sealed/grader_sealed_provider_test.dart`). | A6 | automated |

