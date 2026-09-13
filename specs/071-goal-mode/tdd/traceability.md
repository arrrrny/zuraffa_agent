# Traceability: 071-goal-mode

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:6fd09ab0e5349c34ba4dad8459d17b5ada0ba8f37de3f004f2c834e98c4329fa
statements: 16
automated: 16
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| FR-001 | 42 | - **FR-001**: The system MUST satisfy this requirement: `Goal` is a house-pattern value object: `id` + `description`, | U1 | automated |
| FR-002 | 44 | - **FR-002**: The system MUST satisfy this requirement: `GoalEvaluator` is the injected strategy: | U2 | automated |
| FR-003 | 48 | - **FR-003**: The system MUST satisfy this requirement: `run(goal: g, goalEvaluator: e)` (both or neither — | U3 | automated |
| FR-004 | 55 | - **FR-004**: The system MUST satisfy this requirement: Result surface: `MissionResult.goal` (the goal when goal | U4 | automated |
| FR-005 | 60 | - **FR-005**: The system MUST satisfy this requirement: Ordering guarantees, load-bearing and mutation-tested: | U5 | automated |
| FR-006 | 68 | - **FR-006**: The system MUST satisfy this requirement: No new `EngineEvent` subtypes: goal achievement surfaces | U6 | automated |
| FR-007 | 72 | - **FR-007**: The system MUST satisfy this requirement: Gates: `dart analyze --fatal-infos` clean; `dart test` green | U7 | automated |
| AC-1 | 95 | 1. **Given** the feature implementation under its clean-architecture seams **When** goal achieved on turn 1 stops the mission early **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A1 | automated |
| AC-2 | 96 | 2. **Given** the feature implementation under its clean-architecture seams **When** goal evaluation sees tool results within the same turn **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A2 | automated |
| AC-3 | 97 | 3. **Given** the feature implementation under its clean-architecture seams **When** goal met on the natural-stop turn reports goalAchieved **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A3 | automated |
| AC-4 | 98 | 4. **Given** the feature implementation under its clean-architecture seams **When** unmet goal leaves the mission to its natural stop, evaluator consulted every turn **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A4 | automated |
| AC-5 | 99 | 5. **Given** the feature implementation under its clean-architecture seams **When** budget exhaustion overrides goal mode **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A5 | automated |
| AC-6 | 100 | 6. **Given** the feature implementation under its clean-architecture seams **When** goal and goalEvaluator must be supplied together **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A6 | automated |
| AC-7 | 101 | 7. **Given** the feature implementation under its clean-architecture seams **When** provider-failed turn is never goal-evaluated **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A7 | automated |
| AC-8 | 102 | 8. **Given** the feature implementation under its clean-architecture seams **When** evaluator receives an unmodifiable transcript view **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A8 | automated |
| AC-9 | 103 | 9. **Given** the feature implementation under its clean-architecture seams **When** Goal value semantics **Then** the pinned regression test passes (`test/engine/goal_mode_test.dart`). | A9 | automated |

