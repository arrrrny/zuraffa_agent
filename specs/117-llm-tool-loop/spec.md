**Template Version**: `zuraffa-1.0`

# Feature Specification: `LlmToolLoop` — the lean function-calling runtime

**Branch**: `117-llm-tool-loop` (off master) | **Date**: 2026-11-19

**Status**: Draft

**Input**: GitHub issue #190 — "Two parallel agent stacks: lean typed FC seam
vs unexported engine (MissionRunner/ChatMessage) — decide and ship one
adoption path".

## Summary

The package ships two complete agent stacks. **Stack A** — the typed seam
(`LlmClient` + the sealed `AgentMessage` family) — is what production code
uses; **Stack B** — the engine (`MissionRunner` over a separate
`ChatMessage`/`ChatCompletion` family) — is built but deliberately not
exported. The issue asks for a decision and one adoption path. The evidence
favors **option (a)**: export a minimal, generic function-calling loop over
Stack A so a downstream agent (zik_zak's 1219 order-agent brain, which
hand-rolled a fourth FC loop) composes the loop instead of re-copying it.

This spec ships `LlmToolLoop`: a barrel-exported runtime that drives
`LlmClient.generate` → dispatches `LlmResponse.toolCalls` through a
caller-supplied executor → appends results as `ToolResultMessage` → repeats
until a natural stop. It carries honest-failure budget enforcement (typed
failures, never silent truncation) and a per-tool-result middleware plug-in
point (the PII scrubber is the first real consumer). Stack B stays internal
until it has a production `ToolDispatcher`.

**Out of scope**: exporting Stack B; a `ChatMessage`↔`AgentMessage` bridge;
migrating the engine; a production `ToolDispatcher` implementation; streaming
turns (the loop drives the non-streaming `generate`).

## Files

- `lib/src/llm/llm_tool_loop.dart` — NEW: `LlmToolLoop`,
  `ToolLoopConfig`, the sealed `ToolLoopFailure` family
  (`ToolLoopBudgetExceeded`, `ToolLoopTurnBudgetExceeded`,
  `ToolLoopProviderError`), `ToolLoopResult`, `ToolExecutor`,
  `ToolResultMiddleware`.
- `lib/zuraffa_agent.dart` — the barrel export.
- `test/llm/llm_tool_loop_117_test.dart` — the acceptance tests (barrel
  surface, dispatch, budgets, provider-error boundary, middleware, tool
  crash containment, cut-off turn, config/tools passthrough).

## Functional requirements

- **FR-001** A consumer builds an `LlmToolLoop` over any `LlmClient` and a
  `ToolExecutor` using barrel exports only.
- **FR-002** The loop drives `generate` until the model returns
  `finishReason == 'stop'` with no tool calls.
- **FR-003** Each turn's tool calls are dispatched through the executor and
  the results appended as `ToolResultMessage` to the next request.
- **FR-004** `maxToolCalls` / `maxTurns` budgets stop the loop with a typed
  failure — never a silent truncation of a requested call.
- **FR-005** A provider exception settles as `ToolLoopProviderError`, not a
  thrown exception.
- **FR-006** A tool executor that throws becomes an error tool result; the
  mission continues.
- **FR-007** Middleware transforms each tool result before it enters the
  transcript.
- **FR-008** `ToolLoopConfig` carries system prompt, tools, temperature,
  max tokens, tool choice, and the two budgets; advertised tools ride the
  request.

## Success criteria

- SC-001 `dart test -j 2` green, `dart analyze --fatal-infos` clean,
  `dart format .` no diff.
- SC-002 A downstream FC consumer expresses its brain loop on this surface
  without the four hand-rolled pieces (loop, budget, honest-failure,
  scrubber) — proven by this spec's middleware + budget tests, which mirror
  zik_zak's pieces.