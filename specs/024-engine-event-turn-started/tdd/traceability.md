# Traceability: 024-engine-event-turn-started

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:0c424e5d809f3774228fb19dd91c93ea0d352fd3efc2c4abda8a4d4c879a03bc
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 25 | 1. **Given** a hand-curated `lib/src/engine/events/engine_event.dart` declaring `sealed class EngineEvent`, **When** a part file declares `final class TurnStarted extends EngineEvent`, **Then** `dart analyze` reports no `invalid_use_of_type_outside_library` error. | A1 | automated |
| AC-2 | 27 | 2. **Given** `TurnStarted` is the only `EngineEvent` subtype in this PR, **When** `dart analyze` is run on the whole `lib/`, **Then** it succeeds with no `exhaustive_switch` warnings (the `switch` over `EngineEvent` in the test uses a `default` arm OR is checked with `is TurnStarted`). | A2 | automated |
| AC-3 | 29 | 3. **Given** a downstream consumer switches over `engineEvent`, **When** only `TurnStarted` is implemented, **Then** the switch is exhaustive when expanded as `switch (e) { case TurnStarted(): ... }`. | A3 | automated |
| AC-4 | 42 | 4. **Given** the merged `engine_event.dart` library, **When** an agent adds a second `final class` extending `EngineEvent` in its own part file, **Then** `dart analyze` succeeds with no new errors. | A4 | automated |
| FR-001 | 55 | - **FR-001**: `lib/src/engine/events/engine_event.dart` MUST declare `sealed class EngineEvent` with `part 'turn_started.dart';` and `part 'engine_event.g.dart';` directives. | U1 | automated |
| FR-002 | 56 | - **FR-002**: `lib/src/engine/events/turn_started.dart` MUST be `part of 'engine_event.dart';` and declare `final class TurnStarted extends EngineEvent` with a `const TurnStarted();` constructor and any payload fields the engine will emit (start-of-turn timestamp `DateTime`, optional `turnId` `String?`). | U2 | automated |
| FR-003 | 57 | - **FR-003**: `lib/src/engine/events/engine_event.dart` MUST export the `EngineEvent` library through `lib/zuraffa_agent.dart` (i.e., add `export 'src/engine/events/engine_event.dart';`). | U3 | automated |
| FR-004 | 58 | - **FR-004**: `dart analyze --fatal-infos` MUST report zero issues on `lib/` and on the new files in particular. | U4 | automated |
| FR-005 | 59 | - **FR-005**: A new test file at `test/engine/events/engine_event_test.dart` MUST assert: (a) `TurnStarted()` is `is EngineEvent`; (b) `TurnStarted()` is `is TurnStarted`; (c) a `switch` over `EngineEvent` with a single `TurnStarted` case + `default` compiles and runs. | U5 | automated |
| FR-006 | 60 | - **FR-006**: `dart test` MUST pass all pre-existing tests (now 134 after PR #32) + new tests = ≥ 137 passing. | U6 | automated |

