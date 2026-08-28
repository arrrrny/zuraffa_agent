# Tasks: Goal mode

- T1 Write `specs/071-goal-mode/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/goal_mode_test.dart` FIRST; run — RED is the missing `goal_mode.dart` + missing `MissionStatus.goalAchieved`/result fields compile failure; record evidence.
- T3 Implement `goal_mode.dart` + the mission_runner.dart edits; green the file; re-run the spec-069 suite explicitly (surface-extension regression check).
- T4 Deliberate mutants M1–M5 (cp-restored): evaluation before tools; status not set; goalAchieved flag never true; evaluator only on turn 1; validation removed. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` + full `dart test`; record actual counts vs baseline 925/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base `feat/spec-069-mission-runner`).
