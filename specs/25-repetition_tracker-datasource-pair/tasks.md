# Tasks: RepetitionTracker datasource + mock pair

**Input**: Design documents from `specs/25-repetition_tracker-datasource-pair/` (spec.md, plan.md)

**Prerequisites**: plan.md (required), spec.md (required)

**Tests**: Mandatory — every behavioral task is driven test-first via the TDD loop (`tdd/test-list.md`); red evidence recorded in `tdd/cycle-log.md`.

**Organization**: Tasks grouped by user story; dependency-ordered, MVP-first (US1 loop detection is the MVP slice).

## Phase 1: Entity (blocking prerequisite — all stories depend on it)

- [ ] T001 [US1] RED→GREEN: `test/domain/entities/repetition_tracker/repetition_tracker_test.dart` — entity parity: value equality across (`id`,`maxCalls`,`window`), hashCode parity, inequality on each differing field, `isRepetition` boundary (`maxCalls-1` false / `maxCalls` true), default construction (`maxCalls=5`, `window=60s`), assert `maxCalls >= 1` (FR-001, FR-002, FR-008, SC-004)
- [ ] T002 [US1] Implement: enrich `lib/src/domain/entities/repetition_tracker/repetition_tracker.dart` — add `maxCalls`/`window` fields with defaults, `isRepetition` predicate, extend equality/hashCode/toString, keep `const` + `HAND-CURATED` banner

## Phase 2: Datasource interface (persistence contract)

- [ ] T003 [US1] RED→GREEN: interface surface test — `record`/`count`/`isLooping` exist on `RepetitionTrackerDatasource` with async signatures (compile-level assertion through the mock)
- [ ] T004 [US1] Implement: extend `lib/src/data/datasources/repetition_tracker/repetition_tracker_datasource.dart` with `record(signature, {at})`, `count(signature, {now})`, `isLooping(signature, {now})` (FR-003, FR-004)

## Phase 3: Mock implementation (US1 loop detection — MVP)

- [ ] T005 [US1] RED→GREEN: `test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart` — loop detection: below threshold no signal / at threshold signal / per-signature isolation (AC US1-1..3, FR-005, FR-006, SC-001)
- [ ] T006 [US1] Implement: `lib/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart` — in-memory `Map<String, List<DateTime>>` events, injectable clock, prune-on-write-and-read, derived `isLooping`

## Phase 4: Window semantics (US2)

- [ ] T007 [US2] RED→GREEN: window expiry tests — full-window expiry zeroes count and clears signal; boundary record (exactly `window` old expired, strictly-inside alive) (AC US2-1..2, SC-002)
- [ ] T008 [US2] Implement (if red reveals gaps): pruning correctness in mock — e.g. `at` older records pruned on first evaluation

## Phase 5: Persistence contract + reset (US3)

- [ ] T009 [US3] RED→GREEN: reset tests — `reset()` zeroes all counts, clears loop signals, preserves `current()` config; `record` returns post-record in-window count (read-after-write); backward-compat `RepetitionTrackerMockDatasource()` parameterless construction (AC US3-1..2, FR-007, SC-003)
- [ ] T010 [US3] Implement (if red reveals gaps): reset semantics in mock — clear `_events`, keep `_config`

## Phase 6: Verification + docs

- [ ] T011 [P] Rewrite legacy stub assertions in the mock datasource test (superseded by refinement — keep `isA` compile-parity check, drop `UnimplementedError` expectations)
- [ ] T012 Run `dart analyze` (zero new issues vs 5-issue baseline) and full `dart test` (all green, baseline 529 passed)
- [ ] T013 [P] Commit spec-kit artifacts (spec.md, plan.md, tasks.md, tdd/test-list.md, tdd/cycle-log.md, tdd/verification.md) with the code, Conventional Commits style
- [ ] T014 `/speckit.tdd.verify` — write `tdd/verification.md` with verdict + mutation evidence (deliberate hand-mutants per stack profile)

## Dependency Graph

```text
T001 ─▶ T002 ─▶ T003 ─▶ T004 ─▶ T005 ─▶ T006 ─▶ T007 ─▶ T008 ─▶ T009 ─▶ T010
                                                                    │
                              T011 ─▶ T012 ─▶ T013 ─▶ T014 ◀────────┘
```
