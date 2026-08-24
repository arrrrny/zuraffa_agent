# Tasks: EngineEvent sealed library + TurnStarted

**Branch**: `024-engine-event-turn-started` | **Date**: 2026-08-24 | **Plan**: [plan.md](./plan.md)

## T1 — Directory layout

- [ ] T1.1 `mkdir -p lib/src/engine/events`
- [ ] T1.2 `mkdir -p test/engine/events`

## T2 — Sealed library entry

- [ ] T2.1 Write `lib/src/engine/events/engine_event.dart` declaring `library engine_event;` with `part 'turn_started.dart';` and `part 'engine_event.g.dart';` directives and `sealed class EngineEvent { const EngineEvent(); }`.
- [ ] T2.2 Header comment linking to issue #24 and explaining the 8 sibling PRs that will follow.
- [ ] T2.3 `dart analyze lib/src/engine/events/engine_event.dart` — must report 0 issues (no error about missing `engine_event.g.dart` because no `part` directive for it is referenced yet — actually wait, the `part 'engine_event.g.dart';` directive will trigger a "missing part" warning. To avoid this, only add the directive after issue #15 lands. Decision: OMIT the `part 'engine_event.g.dart';` directive for now; add it when #15 is fixed.)

## T3 — First subtype: TurnStarted

- [ ] T3.1 Write `lib/src/engine/events/turn_started.dart` as `part of 'engine_event.dart';` with `final class TurnStarted extends EngineEvent` having `final DateTime emittedAt; final String? turnId; const TurnStarted({required this.emittedAt, this.turnId});`.
- [ ] T3.2 `dart analyze lib/src/engine/events/` — must report 0 issues.

## T4 — Public export

- [ ] T4.1 Add `export 'src/engine/events/engine_event.dart';` to `lib/zuraffa_agent.dart`.
- [ ] T4.2 `dart analyze` on the whole `lib/` — must report 0 issues.

## T5 — Tests

- [ ] T5.1 Write `test/engine/events/engine_event_test.dart` with 4 tests:
  - `TurnStarted is an EngineEvent`
  - `TurnStarted is a TurnStarted`
  - `switch over EngineEvent with default arm compiles`
  - `EngineEvent is sealed — cannot be extended outside library (compile-time guard via comment)`
- [ ] T5.2 `dart test test/engine/events/engine_event_test.dart` — all 4 pass.

## T6 — Repo-wide gate

- [ ] T6.1 `dart pub get`
- [ ] T6.2 `dart analyze --fatal-infos` — 0 issues.
- [ ] T6.3 `dart test` — all 134 + 4 = 138 tests pass.

## T7 — Commit, PR, merge, pull, re-test

- [ ] T7.1 Commit with `fix(engine-events): hand-curate sealed EngineEvent library + TurnStarted (closes #24)`.
- [ ] T7.2 Push, open PR with base master, link to spec/plan/tasks.
- [ ] T7.3 Wait for CI green; squash merge.
- [ ] T7.4 Pull merged master; re-run `dart pub get && dart analyze --fatal-infos && dart test`.
- [ ] T7.5 Update worklog.
