# Test List: Agent Hooks Pipeline

---
feature: 012-agent-hooks-pipeline
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 8 # acceptance criteria AC-1..AC-8 in spec.md
planned_at: (011-loop head)
updated_at: (012 head)
suite_baseline: red # 6 pre-existing loading failures (unrelated features); green criterion = feature tests pass AND failure delta vs the spec-011-loop baseline (6 loading failures) is zero new
---

## Outer loop: acceptance behaviors

Driven through a scripted mission driver that plays the engine (drives the 9 pipeline points, calls a FakeLlmClient with the pipeline-returned request, honors deny/retry decisions).

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| A1  | A logging hook captures all 9 lifecycle events during a scripted mission, in mission order | AC-1, SC-001, FR-003 | example | DONE | `agent_hook_pipeline_test.dart::A1` |
| A2  | A modifier hook changes the model call parameters and the driver's LlmClient receives the modified request | AC-2, SC-002, FR-005 | example | DONE | `agent_hook_pipeline_test.dart::A2` |
| A3  | An abort hook stops the run with HookAbortError carrying hook name + reason; later hooks not invoked | AC-5, SC-003, FR-004 | example | DONE | `agent_hook_pipeline_test.dart::A3` |
| A4  | A logging hook and a modifying hook compose: both called in registration order, modifier's changes visible to the engine | AC-4, AC-6, US2 | example | DONE | `agent_hook_pipeline_test.dart::A4` |
| A5  | A deny hook prevents tool execution; the synthetic result is returned instead | AC-3, US3, FR-005 | example | DONE | `agent_hook_pipeline_test.dart::A5` |

## Inner loop: unit behaviors

### `lib/src/engine/agent_hooks.dart` (value layer)

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U1  | A bare AgentHook subclass (no overrides) returns continue at all 9 points — a no-op plugin | AC-8, FR-003 | example | DONE | `agent_hooks_test.dart::U1` |
| U2  | Typed result classes carry their action + payload (modify carries the new value; deny carries the synthetic result; retry flags afterModelCall) | FR-003 | example | DONE | `agent_hooks_test.dart::U2` |
| U3  | HookAbortError is a typed error carrying hookName + reason | FR-004 | example | DONE | `agent_hooks_test.dart::U3` |

### `lib/src/engine/agent_hook_pipeline.dart` (chaining)

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U4  | Hooks run in registration order at every lifecycle point | FR-002, AC-4 | example | DONE | `agent_hook_pipeline_test.dart::U4` |
| U5  | A modify result folds: the next hook observes the previous hook's modification (sequential fold) | AC-6, FR-005 | example | DONE | `agent_hook_pipeline_test.dart::U5` |
| U6  | An abort result throws HookAbortError at the offending hook; later hooks are not called | AC-5, FR-004 | example | DONE | `agent_hook_pipeline_test.dart::U6` |

### `lib/src/engine/agent_hook_pipeline.dart` (engine-visible effects)

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U7  | beforeModelCall modify returns the modified LlmRequest to the engine | AC-2, SC-002 | example | DONE | `agent_hook_pipeline_test.dart::U7` |
| U8  | beforeToolCall deny returns a ToolCallDecision whose synthetic result replaces execution | AC-3 | example | DONE | `agent_hook_pipeline_test.dart::U8` |
| U9  | beforeToolCall modify returns the tool call with modified arguments | FR-005 | example | DONE | `agent_hook_pipeline_test.dart::U9` |
| U10 | afterToolCall modify returns the modified result content/isError | FR-005 | example | DONE | `agent_hook_pipeline_test.dart::U10` |
| U11 | afterModelCall retry returns ModelCallDecision.retry = true (engine calls the LLM again) | AC-7 | example | DONE | `agent_hook_pipeline_test.dart::U11` |
| U12 | afterModelCall modify returns the modified LlmResponse | FR-005 | example | DONE | `agent_hook_pipeline_test.dart::U12` |

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| fold update | drop the context update after a modify result | U5 (B sees unmodified context) |
| abort short-circuit | treat abort as continue | U6/A3 (no throw) |
| deny branch | drop deny → always allow | U8/A5 (tool executes) |
| retry flag | invert retry | U11 |
