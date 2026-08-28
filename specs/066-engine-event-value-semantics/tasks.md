# Tasks: EngineEvent value semantics

- T1 Write the spec-066 test group FIRST (equality, hashCode, toString per subtype) and watch it fail against identity-equality events — record RED evidence.
- T2 Add `operator ==` / `hashCode` / `toString` to `turn_started.dart` and `turn_completed.dart`; watch their blocks go green.
- T3 Repeat for `tool_call_started.dart`, `tool_call_completed.dart`, `thinking_delta.dart`, `steering_injected.dart`.
- T4 Repeat for `provider_error.dart`, `mission_started.dart`, `mission_completed.dart`; whole group green.
- T5 Deliberate mutants (one at a time, restored, re-run green): field-drop from `==`, `identityHashCode` for `hashCode`, field-drop from `toString`.
- T6 `dart analyze --fatal-infos` + `dart test` full suite green; record actual counts.
- T7 Write `tdd/verification.md`; commit spec-kit artifacts WITH the code; push; PR.
