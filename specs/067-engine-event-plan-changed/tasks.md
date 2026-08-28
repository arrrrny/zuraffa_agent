# Tasks: EngineEvent.PlanChanged

- T1 Write the spec-067 test group FIRST (is-A, payload, describe routing incl. the shared-switch arm, value semantics) and watch it fail — RED is the `PlanChanged isn't a type` compile failure; record evidence.
- T2 Add the import + `part 'plan_changed.dart';` to `engine_event.dart`; create `plan_changed.dart` with the final class + value semantics.
- T3 Whole file green: `dart test test/engine/events/engine_event_test.dart`.
- T4 Deliberate mutants (one at a time, `cp`-restored — never `git checkout` on uncommitted work): drop the `change` field, cross-bind fields, remove the part directive, drop the switch arm.
- T5 `dart analyze --fatal-infos` + `dart test` full suite green; record actual counts.
- T6 Write `tdd/verification.md`; commit spec-kit artifacts WITH the code; push; PR.
