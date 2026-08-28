# Tasks: Sub-agent dispatch runtime

- T1 Write `specs/070-sub-agent-dispatch-runtime/{spec,plan,tasks}.md` + `tdd/test-list.md`.
- T2 Write `test/engine/sub_agent_dispatch_test.dart` FIRST (fakes + full suite per test-list); run — RED is the missing-`sub_agent_dispatch.dart` compile failure; record evidence.
- T3 Implement `lib/src/engine/sub_agent_dispatch.dart` (AllowlistToolDispatcher, SubAgentDispatchStatus, SubAgentDispatchResult, SubAgentDispatchService) until green.
- T4 Deliberate mutants M1–M5 (one at a time, cp-restored): inverted allowlist; totalRuns not incremented; system prompt dropped from child context; risk-tier gate removed; lastRunOutcome hardcoded. Record kill/survive + evidence.
- T5 Gates: `dart analyze --fatal-infos` (exit 0) + full `dart test`; record actual counts vs baseline 925/2.
- T6 Write `tdd/verification.md`; commit artifacts WITH the code; push; PR (base `feat/spec-069-mission-runner`, stacked on PR #80).
