# Traceability: 045-engine_loop

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:68e6a013d1680950ccc22f66c4334de348760aa21fac71d74212030fc141e370
statements: 5
automated: 5
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** EngineLoop equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/engine_loop/engine_loop_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** EngineLoop inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/engine_loop/engine_loop_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** EngineLoopProvider is a EngineLoopService **Then** the pinned regression test passes (`test/data/providers/engine_loop/engine_loop_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** EngineLoopProvider.current returns the active loop config **Then** the pinned regression test passes (`test/data/providers/engine_loop/engine_loop_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** EngineLoopProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/engine_loop/engine_loop_provider_test.dart`). | A5 | automated |

