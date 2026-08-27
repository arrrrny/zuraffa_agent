# Implementation Plan: Agent Hooks Pipeline

**Branch**: `012-agent-hooks-pipeline` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-agent-hooks-pipeline/spec.md`

## Summary

A typed 9-point lifecycle hook system: `AgentHook` (abstract, 9 default-continue methods), per-point context and result classes, `HookAbortError` (typed abort), and `AgentHookPipeline` that chains hooks in registration order, folds modifications (each hook sees the previous hook's output), throws on abort, and returns decision envelopes where the engine must branch (`ToolCallDecision.deny` → synthetic tool result without execution; `ModelCallDecision.retry` → call the LLM again). Engine-visible effects are proven through a scripted test driver playing the engine role; the real engine wiring is spec 002.

## Technical Context

**Language/Version**: Dart 3.13.2 (stable), SDK constraint `^3.11.0`.

**Primary Dependencies**: `LlmRequest`/`LlmResponse`/`LlmResponseChunk`/`LlmToolCall` from `lib/src/llm/llm_client.dart` (spec 007); `AgentMessage` from `lib/src/types.dart`. No new packages.

**Storage**: none — in-memory pipeline state (registered hooks list).

**Testing**: `dart test`; a scripted mission driver in the test file plays the engine (drives the 9 points through the pipeline, calls a FakeLlmClient with the pipeline-returned request, honors deny/retry decisions). Baseline at branch point: +486 passed / 6 unrelated pre-existing loading failures; 111 pre-existing analyzer issues.

**Constraints**: constitution VII (no `dart:io`), VIII (attribution headers — dart_agent_core pipeline lineage), X (analyze pristine on new files). One-behavior-per-red discipline.

**Scale/Scope**: 2 new lib files (~230 + ~190 lines), 2 new test files. No changes to existing files. New directory `lib/src/engine/` gains its first non-event modules.

## Constitution Check

- VII: new files import only `llm_client.dart`, `types.dart` — no `dart:io`. ✓
- VIII: hooks pipeline ported from dart_agent_core — attribution headers retained. ✓
- X: zero analyzer issues in new files; failure delta zero. ✓

## Project Structure

```text
lib/src/engine/
├── agent_hooks.dart            # NEW: 9 context classes, 9 result classes,
│                               #      HookAbortError, ToolCallDecision, AgentHook
└── agent_hook_pipeline.dart    # NEW: AgentHookPipeline — 9 chained runners

test/engine/
├── agent_hooks_test.dart       # NEW: value layer (U1-U3)
└── agent_hook_pipeline_test.dart  # NEW: chaining/abort/deny/retry + scripted
                                   #     mission driver (U4-U12, A1-A5)

specs/012-agent-hooks-pipeline/
├── spec.md, plan.md, tasks.md
└── tdd/{test-list.md, cycle-log.md, verification.md}
```

## Realistic Boundaries / De-scoping

- Engine-loop wiring (who calls the pipeline, translating HookAbortError into the engine's stop semantics) is spec 002's integration; here a test driver plays the engine.
- No hook priorities/weights — registration order only (spec FR-002).
- No conditional registration per point — every registered hook participates at every point it overrides (FR-001 reads "multiple hooks per lifecycle point" as: N registered hooks, each called at each point, in order).
- `afterRun` cannot modify the completed run (terminal observation only).

## Verification

- Per-behavior red→green cycles committed individually; mutation checks on the fold (drop the context update after a modify), the abort short-circuit (continue instead of throw), and the deny/retry decision branches.
- Gates: analyze 111 (baseline) + feature files zero; test failure delta zero vs +486/-6.
