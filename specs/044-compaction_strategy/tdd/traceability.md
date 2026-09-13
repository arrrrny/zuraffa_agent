# Traceability: 044-compaction_strategy

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:68833fbf162088204ccda76d914b8c33a0af6283a32255a56fd3ff19700a6830
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategy equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategy inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider is a CompactionStrategyService **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider.current returns the active strategy **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider honors an injected active strategy **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** CompactionStrategyProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/compaction_strategy/compaction_strategy_provider_test.dart`). | A6 | automated |

