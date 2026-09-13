# Traceability: 046-loop_safety_rails

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:b3c234d17c4a01bce45e96802a3164aa7c034b99f525fe31bec0ce22aa92386f
statements: 20
automated: 20
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 14 | 1. **Given** the implemented feature **When** its acceptance criterion applies — \| LoopSafetyRails is a plain Dart value object with 4 required fields (outcomeType, turnNumber, reason, emittedAt) and a const constructor \| yes \| — **Then** the pinned regression suite confirms it. | A1 | automated |
| AC-2 | 15 | 2. **Given** the implemented feature **When** its acceptance criterion applies — \| Value equality holds when all 4 fields are identical; inequality is detected when any field differs \| yes \| — **Then** the pinned regression suite confirms it. | A2 | automated |
| AC-3 | 16 | 3. **Given** the implemented feature **When** its acceptance criterion applies — \| hashCode is consistent with == (equal instances share hashCode) \| yes \| — **Then** the pinned regression suite confirms it. | A3 | automated |
| AC-4 | 17 | 4. **Given** the implemented feature **When** its acceptance criterion applies — \| LoopSafetyRailsService is abstract, mixes in Loggable and FailureHandler, declares current(NoParams) and count(NoParams) \| yes \| — **Then** the pinned regression suite confirms it. | A4 | automated |
| AC-5 | 18 | 5. **Given** the implemented feature **When** its acceptance criterion applies — \| LoopSafetyRailsProvider implements LoopSafetyRailsService and throws UnimplementedError for both methods \| yes \| — **Then** the pinned regression suite confirms it. | A5 | automated |
| AC-6 | 19 | 6. **Given** the implemented feature **When** its acceptance criterion applies — \| toString includes outcomeType and turnNumber \| yes \| — **Then** the pinned regression suite confirms it. | A6 | automated |
| AC-7 | 41 | 7. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails equality is value-based across all fields **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A7 | automated |
| AC-8 | 42 | 8. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality differs when a field changes **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A8 | automated |
| AC-9 | 43 | 9. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: outcomeType **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A9 | automated |
| AC-10 | 44 | 10. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: turnNumber **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A10 | automated |
| AC-11 | 45 | 11. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: reason **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A11 | automated |
| AC-12 | 46 | 12. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRails inequality detected per-field: emittedAt **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A12 | automated |
| AC-13 | 47 | 13. **Given** the feature implementation under its clean-architecture seams **When** identical instances are equal via identical() shortcut **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A13 | automated |
| AC-14 | 48 | 14. **Given** the feature implementation under its clean-architecture seams **When** toString includes outcomeType and turnNumber **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A14 | automated |
| AC-15 | 49 | 15. **Given** the feature implementation under its clean-architecture seams **When** toString includes reason **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A15 | automated |
| AC-16 | 50 | 16. **Given** the feature implementation under its clean-architecture seams **When** toString omits emittedAt for readability **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A16 | automated |
| AC-17 | 51 | 17. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider is a LoopSafetyRailsService **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A17 | automated |
| AC-18 | 52 | 18. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider.current returns the active rails snapshot **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A18 | automated |
| AC-19 | 53 | 19. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider.count returns 1 **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A19 | automated |
| AC-20 | 54 | 20. **Given** the feature implementation under its clean-architecture seams **When** LoopSafetyRailsProvider constructor takes no arguments **Then** the pinned regression test passes (`test/data/providers/loop_safety_rails/loop_safety_rails_provider_test.dart`). | A20 | automated |

