# Tasks: MissionRunner

- T1 Write `specs/069-mission-runner/{spec,plan,tasks}.md` + `tdd/test-list.md` (this file's sibling).
- T2 Write `test/engine/mission_runner_test.dart` FIRST (fakes + full suite per test-list); run — RED is the missing-`mission_runner.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/mission_runner.dart` (MissionStatus, MissionResult, ToolCallPlanner, MissionRunner) until the file is green.
- T4 Deliberate mutants M1–M5 (one at a time, `cp`-restored): drop MissionStarted emission; skip tool-result transcript append; turn-cap off-by-one; steering drained once instead of per turn; ToolCallCompleted.ok hardcoded true. Record kill/survive + evidence per mutant.
- T5 Gates: `dart analyze --fatal-infos` (exit 0) + full `dart test`; record actual counts vs baseline 915/2.
- T6 Write `tdd/verification.md` (honest verdict); commit spec-kit artifacts WITH the code (Conventional Commit); push; PR with spec number in the title.
