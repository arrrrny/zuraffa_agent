# Tasks: EngineEventLog

- T1 Write `test/engine/events/engine_event_log_test.dart` FIRST and watch it fail — RED is the missing library (compile failure); record evidence.
- T2 Implement `lib/src/engine/events/engine_event_log.dart` (FR-001..FR-004); watch the suite go green.
- T3 Add the barrel export to `lib/zuraffa_agent.dart` (non-behavioral wiring); analyzer clean.
- T4 Deliberate mutants (one at a time, `cp`-restored): return internal list directly (mutability leak), `byType` ignores the type filter, `since` ignores the `inclusive` flag, `before`/`since` boundary inverted.
- T5 `dart analyze --fatal-infos` + `dart test` full suite green; record actual counts.
- T6 Write `tdd/verification.md`; commit spec-kit artifacts WITH the code; push; PR.
