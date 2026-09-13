# Traceability: 043-session_branch

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:959b732046410b539bc177014fdc5e2fe786b0a247c30ad7b7dae5761603ae24
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** SessionBranch equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** SessionBranch inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** SessionBranchProvider is a SessionBranchService **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** SessionBranchProvider.current returns the active branch **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** SessionBranchProvider.current returns a supplied active branch **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** SessionBranchProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/session_branch/session_branch_provider_test.dart`). | A6 | automated |

