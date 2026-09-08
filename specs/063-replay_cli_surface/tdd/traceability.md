# Traceability: 063-replay_cli_surface

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:48d06be59cb2873cfdafcd713f26dd75edc15ff96e752dbfd8a6cd3d5a698df4
statements: 6
automated: 6
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 29 | 1. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurface equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A1 | automated |
| AC-2 | 31 | 2. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurface inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A2 | automated |
| AC-3 | 33 | 3. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurfaceProvider is a ReplayCliSurfaceService **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A3 | automated |
| AC-4 | 35 | 4. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurfaceProvider.current returns the active replay CLI surface **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A4 | automated |
| AC-5 | 37 | 5. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurfaceProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A5 | automated |
| AC-6 | 39 | 6. **Given** the feature implementation under its clean-architecture seams **When** ReplayCliSurfaceProvider honours an injected value object **Then** the pinned regression test passes (`test/data/providers/replay_cli_surface/replay_cli_surface_provider_test.dart`). | A6 | automated |

