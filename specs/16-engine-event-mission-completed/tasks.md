# Tasks: EngineEvent.MissionCompleted
- T1 Create `mission_completed.dart` part file with `final class MissionCompleted extends EngineEvent`.
- T2 Patch `engine_event.dart` to add `part 'mission_completed.dart';`.
- T3 Patch `engine_event_test.dart` to extend `describe` switch + add MissionCompleted tests.
- T4 `dart pub get && dart analyze --fatal-infos && dart test` all green.
- T5 Commit + push + PR + merge + pull + re-test.

## Phase N: TDD remediation

- R1 RETRACTED (2026-08-29, false positive). The prior claim that `MissionCompleted.operator ==` omits `missionId` is false at HEAD — the field *is* compared (`mission_completed.dart:19`). It was graded against an uncommitted WIP regression that has since been reverted. No source change required; the suite is green. See `tdd/verification.md` correction note.
