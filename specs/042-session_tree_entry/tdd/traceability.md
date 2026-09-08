# Traceability: 042-session_tree_entry

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:e061ef6a7445128c9bd87c27f268c664b87c335a5605eb4b0fa1f2d07ef9f53d
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntry equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntry inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider is a SessionTreeEntryService **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.current returns the active entry **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.current returns a supplied active entry **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** SessionTreeEntryProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/session_tree_entry/session_tree_entry_provider_test.dart`). | A6 | automated |

