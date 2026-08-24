# Feature Specification: EngineEvent sealed library + TurnStarted

**Feature Branch**: `024-engine-event-turn-started`

**Created**: 2026-08-24

**Status**: Draft

**Input**: Bug arrrrny/zuraffa_agent#24 — `zfa entity create --sealed --generate-subs` produced 9 event subtype files (`turn_started.zorphy.dart`, etc.) that each `implements EngineEvent`, but `EngineEvent` is `sealed` and declared in a different library. Dart forbids implementing/extending a sealed class outside its declaring library, so `dart analyze` reports `invalid_use_of_type_outside_library` for all 9 subtypes. This is the **first** of 9 sibling issues (#16–#24) and the first to land the **hand-curated** `lib/src/engine/events/engine_event.dart` sealed library; this PR closes #24 (turn_started) and sets the structural foundation for the remaining 8 follow-up PRs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - dart analyze is clean for TurnStarted (Priority: P1)

As the build CI, I see `dart analyze --fatal-infos` succeed on `lib/src/engine/events/engine_event.dart` and its `turn_started.dart` part file because `TurnStarted` is declared as a `final class TurnStarted extends EngineEvent` *inside* the same library that declares `sealed class EngineEvent` — exactly as Dart's sealed-class rules require.

**Why this priority**: This is the root structural fix that all 8 sibling issues depend on. Without a properly-structured sealed `EngineEvent` library, none of #16–#24 can be resolved.

**Independent Test**: `dart analyze --fatal-infos lib/src/engine/events/` exits 0. The new `test/engine/events/engine_event_test.dart` asserts `TurnStarted()` is an `EngineEvent` and is *not* any other subtype.

**Acceptance Scenarios**:

1. **Given** a hand-curated `lib/src/engine/events/engine_event.dart` declaring `sealed class EngineEvent`, **When** a part file declares `final class TurnStarted extends EngineEvent`, **Then** `dart analyze` reports no `invalid_use_of_type_outside_library` error.
2. **Given** `TurnStarted` is the only `EngineEvent` subtype in this PR, **When** `dart analyze` is run on the whole `lib/`, **Then** it succeeds with no `exhaustive_switch` warnings (the `switch` over `EngineEvent` in the test uses a `default` arm OR is checked with `is TurnStarted`).
3. **Given** a downstream consumer switches over `engineEvent`, **When** only `TurnStarted` is implemented, **Then** the switch is exhaustive when expanded as `switch (e) { case TurnStarted(): ... }`.

### User Story 2 - Foundation for the 8 sibling events (Priority: P2)

As the next agent fixing issue #23 (turn_completed), I clone this worktree's `engine_event.dart`, add `part 'turn_completed.dart';` plus the matching `final class TurnCompleted extends EngineEvent`, and the new file analyzes cleanly on the first try.

**Why this priority**: There are 8 sibling issues (#16–#23) that all need to add one event each to this library. A correct first event with clear comments makes each subsequent PR ~5 minutes of work.

**Independent Test**: Mechanical clone of the part-file pattern for a second event compiles without analyzer errors.

**Acceptance Scenarios**:

1. **Given** the merged `engine_event.dart` library, **When** an agent adds a second `final class` extending `EngineEvent` in its own part file, **Then** `dart analyze` succeeds with no new errors.

### Edge Cases

- What about exhaustive `switch` over `EngineEvent`? — While there is only one subtype, a `switch` over `EngineEvent` MUST either (a) handle `TurnStarted` and add a `default` arm or `_` arm, or (b) be marked as incomplete with a TODO. The test demonstrates (a).
- What about JSON serialization? — Issue #15 (`zfa entity create --sealed omits part 'engine_event.g.dart'`) is the JSON-serialization sibling; the part directive `part 'engine_event.g.dart';` is included so the generator can emit it later without re-touching the file.
- What about the existing entity directory naming convention? — The zfa generator emits `lib/src/domain/entities/<entity>/<entity>.zorphy.dart`. The hand-curated library uses `lib/src/engine/events/` because event types are runtime-emitted by the engine, not domain entities persisted to storage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `lib/src/engine/events/engine_event.dart` MUST declare `sealed class EngineEvent` with `part 'turn_started.dart';` and `part 'engine_event.g.dart';` directives.
- **FR-002**: `lib/src/engine/events/turn_started.dart` MUST be `part of 'engine_event.dart';` and declare `final class TurnStarted extends EngineEvent` with a `const TurnStarted();` constructor and any payload fields the engine will emit (start-of-turn timestamp `DateTime`, optional `turnId` `String?`).
- **FR-003**: `lib/src/engine/events/engine_event.dart` MUST export the `EngineEvent` library through `lib/zuraffa_agent.dart` (i.e., add `export 'src/engine/events/engine_event.dart';`).
- **FR-004**: `dart analyze --fatal-infos` MUST report zero issues on `lib/` and on the new files in particular.
- **FR-005**: A new test file at `test/engine/events/engine_event_test.dart` MUST assert: (a) `TurnStarted()` is `is EngineEvent`; (b) `TurnStarted()` is `is TurnStarted`; (c) a `switch` over `EngineEvent` with a single `TurnStarted` case + `default` compiles and runs.
- **FR-006**: `dart test` MUST pass all pre-existing tests (now 134 after PR #32) + new tests = ≥ 137 passing.

### Key Entities

- **EngineEvent** (sealed, in `lib/src/engine/events/engine_event.dart`): base for all engine-emitted runtime events.
- **TurnStarted** (final class, in `lib/src/engine/events/turn_started.dart` part): emitted by the engine loop at the start of every turn.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart analyze --fatal-infos` exits 0 on the worktree.
- **SC-002**: `dart test` exits 0 with ≥ 137 tests passing.
- **SC-003**: No `invalid_use_of_type_outside_library` analyzer code is reported.
- **SC-004**: PR is squash-merged to master; the merged commit, when checked out and re-tested, is green.

## Assumptions

- The 8 sibling issues (#16–#23) will follow this pattern: each gets its own worktree branched from updated master, each adds one `final class` extending `EngineEvent`, each ships its own PR.
- The runtime purity gate (`.github/workflows/pipeline.yml`) forbids `dart:io` in non-adapter files; the new files do not import `dart:io`.
- `DateTime` is a safe payload field (dart:core, no purity impact).
