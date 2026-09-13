# Traceability: 060-replay_diff

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:15ae27cf31d98df82b5ce649e560d50093a6cb2eb9bd535dc03c1ea933881b06
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiff equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiff inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider is a ReplayDiffService **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider.current returns the active replay diff **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** ReplayDiffProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/replay_diff/replay_diff_provider_test.dart`). | A6 | automated |

