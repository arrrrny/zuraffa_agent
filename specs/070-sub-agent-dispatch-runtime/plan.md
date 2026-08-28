# Implementation Plan: Sub-agent dispatch runtime

**Branch**: `feat/spec-070-sub-agent-dispatch` | **Date**: 2026-08-29

## Summary

Compose spec 069's `MissionRunner` into the Kimi LaborMarket dispatch
pattern: isolated child mission + allowlist-enforcing tool boundary +
instance bookkeeping + result-only return.

## Phase 1 — Design

### `lib/src/engine/sub_agent_dispatch.dart` (new)

```dart
class AllowlistToolDispatcher implements ToolDispatcher {
  AllowlistToolDispatcher({required ToolDispatcher inner, required Set<String> allowlist});
  // dispatch: allowlisted -> inner.dispatch; else typed failure
  //   ToolDispatchResult(success: false, result: '', error: 'tool not allowed: $toolName')
  // dispatchBatch: per-call enforcement
  // validateSchema / checkRiskTier: pure delegation
}

enum SubAgentDispatchStatus { completed, budgetExhausted, providerFailed, refusedRiskTier }

class SubAgentDispatchResult { /* instanceId, specName, status, resultSummary,
                                 instance, context; == / hashCode / toString */ }

class SubAgentDispatchService {
  SubAgentDispatchService({
    required ToolDispatcher toolDispatcher,
    required LlmClientProvider llmClient,
    int fallbackMaxTurns = 10,
  });

  Future<SubAgentDispatchResult> dispatch({
    required SubAgentSpec spec,
    required String mission,
    required SubAgentInstance instance,
    ToolCallPlanner? planner,
    void Function(EngineEvent)? onEvent,
    DateTime Function()? clock,
    bool adminGranted = false,
  });
}
```

Dispatch flow: risk-tier gate (FR-005) → build child EngineLoop + StopPolicy
from spec budgets (FR-003) → wrap dispatcher in AllowlistToolDispatcher
(FR-002) → child MissionRunner over `[system, user]` transcript (FR-001),
missionId `instance.id`, events forwarded (FR-006) → map child
MissionResult onto SubAgentDispatchResult + updated instance (FR-004) +
SubAgentContext snapshot (FR-007).

### Test doubles (`test/engine/sub_agent_dispatch_test.dart`)

- Reuse the spec-069 fake shapes locally: `CapturingLlmClient` (records every
  `messages` list it receives, returns a FIFO script), `RecordingDispatcher`
  (records dispatches, scripted results).
- `ScriptedPlanner` (plans by completion index).

## Phase 2 — TDD

1. RED: whole test file first (missing library = compile failure).
2. GREEN: implement until green.
3. Deliberate mutants (cp-restored): M1 allowlist check inverted; M2
   totalRuns not incremented; M3 system prompt dropped from child context;
   M4 risk-tier gate removed; M5 lastRunOutcome hardcoded.
4. Gates + `tdd/verification.md`; commit artifacts WITH code; push; PR
   (base branch `feat/spec-069-mission-runner` — stacked).

## Risks / notes

- `SubAgentSpec` ctor validates identity fields (spec 036) — test fixtures
  must use non-empty name/description/systemPrompt.
- `EngineLoop.wallClockTimeoutMs` int ms; `StopPolicy.wallClockTimeout` is a
  Duration — build BOTH from `spec.wallClockTimeout` consistently.
- Instance is immutable — build the updated one; never mutate the input.
