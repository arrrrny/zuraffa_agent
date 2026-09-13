# Traceability: 053-fallback_chain

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:4db3a3792d2062b52a5cc59e0fdacfabbb421538dc08cd5aee7733ca2d8271dc
statements: 5
automated: 5
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** FallbackChain equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/fallback_chain/fallback_chain_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** FallbackChain inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/fallback_chain/fallback_chain_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** FallbackChainProvider is a FallbackChainService **Then** the pinned regression test passes (`test/data/providers/fallback_chain/fallback_chain_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** FallbackChainProvider.current returns the active chain snapshot **Then** the pinned regression test passes (`test/data/providers/fallback_chain/fallback_chain_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** FallbackChainProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/fallback_chain/fallback_chain_provider_test.dart`). | A5 | automated |

