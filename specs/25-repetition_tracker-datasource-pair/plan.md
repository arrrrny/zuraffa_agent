# Implementation Plan: RepetitionTracker datasource + mock pair

**Branch**: `feat/specs-025-027-029-031` (spec dir: `25-repetition_tracker-datasource-pair`) | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/25-repetition_tracker-datasource-pair/spec.md`

## Summary

Ship the real behavioral surface for the RepetitionTracker datasource pair: enrich the anemic `id`-only value object into the loop-detection policy (`id`, `maxCalls`, `window`, pure `isRepetition` predicate), extend the datasource interface from the 2-method stub (`current`/`reset`) to the full persistence contract (`record`, `count`, `isLooping` with injectable time), and turn the `UnimplementedError` mock into the reference in-memory sliding-window implementation. Closes the behavioral gap left by issues #25/#26 (which only fixed compilation: `uri_does_not_exist` + `implements_non_class`).

## Technical Context

**Language/Version**: Dart 3.13.2 (sdk `^3.8.0`) — pure Dart package, no Flutter SDK.

**Primary Dependencies**: `zuraffa` 6.0.0 (git, provides `Loggable`/`FailureHandler` mixins), `test` ^1.25.0, `mocktail` ^1.0.5 (present; this pair uses hand-written in-memory fakes per repo convention).

**Storage**: None required — the mock IS the in-memory reference store; the interface is the persistence contract a Hive/remote backend will later implement.

**Testing**: `dart test` (package:test). Single test: `dart test <file> --plain-name "<name>"`. Full suite: `dart test`. Gate: `dart analyze` (5 pre-existing issues are the accepted baseline; zero new issues allowed). See `.specify/memory/tdd-profile.md`.

**Target Platform**: Any Dart VM target (agent engine library).

**Project Type**: library (agent engine package `zuraffa_agent`).

**Performance Goals**: Sliding-window prune is O(k) per signature (k = in-window records, expected small); no allocation on read path beyond pruning.

**Constraints**: Backward-compatible constructors (FR-008); no `build_runner` codegen (hand-curated files, plain Dart value objects per repo convention); no new dependencies.

**Scale/Scope**: 3 lib files + 1 test file; ~30 tests across entity/mock/contract layers.

## Constitution Check

*No `.specify/memory/constitution.md` exists (spec-kit initialized fresh this branch); repo AGENTS.md rules apply: hand-curated files carry the `HAND-CURATED — DO NOT REGENERATE VIA zfa` banner. All files in this feature keep that banner. Passed.*

## Project Structure

### Documentation (this feature)

```text
specs/25-repetition_tracker-datasource-pair/
├── spec.md              # refined via /speckit.specify (this cycle)
├── plan.md              # this file
├── tasks.md             # /speckit.tasks output
└── tdd/
    ├── test-list.md     # /speckit.tdd.plan output
    ├── cycle-log.md     # red/green evidence, append-only
    └── verification.md  # /speckit.tdd.verify output
```

### Source Code (repository root)

```text
lib/src/domain/entities/repetition_tracker/repetition_tracker.dart   # enriched value object
lib/src/data/datasources/repetition_tracker/repetition_tracker_datasource.dart        # interface: full persistence contract
lib/src/data/datasources/repetition_tracker/repetition_tracker_mock_datasource.dart   # in-memory sliding-window impl
test/data/datasources/repetition_tracker/repetition_tracker_mock_datasource_test.dart  # rewritten: real behavior
test/domain/entities/repetition_tracker/repetition_tracker_test.dart                   # new: entity parity
```

## Architecture / Data Flow

Follows the repo's datasource-pair clean-architecture pattern (see `turn_record`, `tool_invocation_record`):

```text
engine loop ──record(signature)──▶ RepetitionTrackerDatasource (interface, data layer)
                                        │
                                        ▼
                          RepetitionTrackerMockDatasource (in-memory)
                          · Map<String, List<DateTime>> _events
                          · prune(now - window) on write AND read
                          · isLooping = config.isRepetition(count)
                                        │
                          RepetitionTracker (domain value object)
                          · id, maxCalls, window (const, value equality)
                          · isRepetition(observedCalls) pure predicate
```

Key decisions:

1. **Signature is an opaque `String`** on this pair — the canonical key a spec-29 `ToolCallSignature` produces. Keeps the two specs independently testable; composition is documented, not compiled.
2. **Clock injection** via optional `DateTime Function()? clock` constructor param on the mock, plus optional `at`/`now` params on record/count/isLooping (FR-004) — deterministic window tests without async fake timers.
3. **Derived signal** — `isLooping` is always computed from the live window count (never sticky), so window expiry auto-clears the signal (FR-006, edge case 4).
4. **Backward-compatible defaults** — `maxCalls=5`, `window=60s` (FR-008), matching the StopPolicy default `repetitionThreshold=5`.

## Meticulous Analysis / Risk Assessment

- **Risk: breaking the 3 existing stub-assertion tests.** Accepted and intended — spec refinement supersedes them (drift documented in spec.md Assumptions). The rewrite keeps the `isA<RepetitionTrackerDatasource>()` compile-parity test, replaces the `UnimplementedError` assertions with behavior tests.
- **Risk: inclusive vs exclusive threshold.** Pinned inclusive by AC US1-2 and spec-002 US4; boundary tests at `maxCalls-1` and `maxCalls` prove both sides.
- **Risk: `const` constructor with default `Duration`.** `Duration(seconds: 60)` is a const expression — entity stays fully `const`-constructible.
- **Risk: window boundary off-by-one.** A record exactly `window` old is expired; strictly younger is alive. Two dedicated boundary tests (US2 AC2).

## Implementation Phases

Phase 1 — Entity: enrich `RepetitionTracker` (fields, predicate, equality, hashCode, toString, defaults).
Phase 2 — Interface: extend `RepetitionTrackerDatasource` with `record`/`count`/`isLooping` + injectable time params.
Phase 3 — Mock: in-memory implementation with pruning + injectable clock.
Phase 4 — Tests: rewrite mock datasource test, add entity parity test; green suite + clean analyze.

All behavioral phases go through the TDD red-green-refactor loop (`tdd/test-list.md`, `tdd/cycle-log.md`).
