# Traceability: 054-health_snapshot

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:663349912e51d2063261b364ae646a3455dbe4bfd174b011a22916faa789e5ac
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshot equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshot inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshotProvider is a HealthSnapshotService **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshotProvider.current returns the active chain snapshot **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshotProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** HealthSnapshotProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/health_snapshot/health_snapshot_provider_test.dart`). | A6 | automated |

