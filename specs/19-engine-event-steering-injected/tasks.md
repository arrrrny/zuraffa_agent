# Tasks: EngineEvent.SteeringInjected

> TEST-AFTER: the class and its tests already ship on master and the suite is green.
> Behavior ids below trace to `tdd/test-list.md`. Tests DONE; see the discrepancy note there
> (no dedicated `describe` routing-assertion test for #19, unlike #16/#17/#18).

- [ ] [U1] Test: `SteeringInjected` is `is EngineEvent` AND `is SteeringInjected`; `final class` part file with `emittedAt`, `content`, `injectedAt`.
- T1 Create `steering_injected.dart` part file with `final class SteeringInjected extends EngineEvent`.
- [ ] [U2] Test: `emittedAt`/`content`/`injectedAt` constructor params bind to same-named fields (distinct values, no cross-binding).
- [ ] [U3] Test: `engine_event.dart` includes `part 'steering_injected.dart';` (sealed library picks it up — CI analyze proves it).
- T2 Patch `engine_event.dart` to add `part 'steering_injected.dart';`.
- [ ] [U4] Test: `describe(EngineEvent)` switch handles `SteeringInjected` (exhaustive, no default arm) and routes to `steering_injected(content)`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add SteeringInjected tests.
- [ ] [A3] Test gate: `dart analyze --fatal-infos` exits 0.
- [ ] [A4] Test gate: `dart test` passes (full suite green baseline).
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.
