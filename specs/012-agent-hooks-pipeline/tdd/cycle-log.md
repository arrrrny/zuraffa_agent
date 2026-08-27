# TDD Cycle Log: Agent Hooks Pipeline

---
feature: 012-agent-hooks-pipeline
profile: .specify/memory/tdd-profile.md
started_at: (011-loop-detection-llm head)
---

## Cycle 1 — U1-U3 value layer

- **Red**: 41 compile errors — `agent_hooks.dart` does not exist (contexts,
  results, HookAbortError, ToolCallDecision all undefined).
- **Green**: 9 context classes, 9 result classes (typed actions +
  payloads), HookAbortError, ToolCallDecision/ModelCallDecision envelopes,
  AgentHook with 9 default-continue methods.
- **Commit**: c37a625.

## Cycles 2-3 — U4-U12 + A1-A5 pipeline

- **Red**: 28 compile errors — `agent_hook_pipeline.dart` does not exist.
  Fixture repairs pre-green (all test-side, no impl existed yet):
  - `_CallbackHook` field/method name collision → fields renamed
    `onBeforeRun`/`onBeforeModelCall`/…;
  - `toolCall` const scoped to the wrong group → hoisted to a top-level
    `_missionToolCall` const.
- **Green**: sequential-fold pipeline with typed abort, deny short-circuit,
  retry flag; scripted mission driver plays the engine (drives the 9
  points, calls FakeLlmClient with the pipeline-returned request, honors
  deny/retry). First run after fixture repair: **+14 all green** — the
  behaviors were asserted individually against the new module.
- **Mutations** (each restored + re-verified green):
  - M1 fold drops modify (beforeModelCall) → +11 -3 KILLED (U5, U7, A2/A4).
  - M2 abort throws with wrong hook identity → +12 -2 KILLED (U6, A3).
  - M3 deny branch dropped (falls through to proceed) → +12 -2 KILLED
    (U8, A5).
  - M4 retry flag inverted → +9 -5 KILLED (U11 + driver tests).
- **Style pass**: 10 analyzer infos after the feature commit (const
  constructor style: initializing formals, needless type annotations,
  final locals) — all fixed; analyze returned to the 111 baseline.
- **Commits**: (feature commit), 36c5123 (style).

## Final gates

- `dart analyze`: 111 issues — exactly the pre-existing baseline; zero in
  spec-012 files.
- `dart test`: +503 passed / 6 failed — 6 = pre-existing baseline loading
  failures; **+17 new passing** vs the spec-011-loop baseline (+486),
  zero new failures.
- Purity: no `dart:io` in the new files (constitution VII) — verified by
  grep before commit; attribution headers present (VIII).
