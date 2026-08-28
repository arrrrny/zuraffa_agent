# Test List: Sub-agent dispatch runtime

---
feature: 070-sub-agent-dispatch-runtime
loop: outside-in
profile: .specify/memory/tdd-profile.md # referenced by sibling 023; file absent at HEAD — 023 artifact as de-facto rubric + constitution.md Principles II/V/X
spec_criteria: 8 # FR-001..FR-008 in spec.md
planned_at: 8a5bd83 # feat/spec-069-mission-runner HEAD (stack base)
updated_at: HEAD
suite_baseline: green # 925 passed / 2 skipped at 8a5bd83
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| A1  | Isolation: the child LLM receives EXACTLY `[system: spec.systemPrompt, user: mission]` — no parent context; the result carries the child's final content as `resultSummary` and exposes NO transcript | FR-001 | example | DONE | `test/engine/sub_agent_dispatch_test.dart::spec 070 — SubAgentDispatchService::child runs in an isolated context and returns only a summary` |
| A2  | Allowlist: an out-of-allowlist tool call is refused at the boundary (inner dispatcher NEVER sees it) with `ok: false` + `error` naming the tool; an allowlisted call delegates and succeeds; mission continues | FR-002 | example | DONE | `…::tool allowlist is enforced at the dispatch boundary` |
| A3  | Budgets: `spec.maxTurns: 1` with a tool-looping child stops after 1 turn — dispatch status `budgetExhausted` | FR-003 | example | DONE | `…::spec maxTurns budget caps the child mission` |
| A4  | Instance bookkeeping: `totalRuns` 2 → 3 and `lastRunOutcome` = status name on a completed dispatch; input instance untouched | FR-004 | example | DONE | `…::completed dispatch updates the instance bookkeeping` |
| A5  | Risk tier gate: admin-tier spec without `adminGranted` → `refusedRiskTier`, zero LLM calls, instance returned unchanged | FR-005 | example | DONE | `…::admin-risk spec is refused without a grant` |
| A6  | Risk tier gate (positive): the same admin spec WITH `adminGranted: true` runs normally | FR-005 | example | DONE | `…::admin-risk spec runs with an explicit grant` |
| A7  | Event forwarding: child `MissionStarted.missionId == instance.id` reaches the caller's `onEvent` | FR-006 | example | DONE | `…::child events forward with the instance id as mission id` |
| A8  | `SubAgentDispatchResult` value semantics + `context` snapshot (`subAgentSpecId`, `sessionId`, `toolAllowlist`, `budgetTurns`) | FR-007 | example | DONE | `…::SubAgentDispatchResult value semantics and context snapshot` |
| A9  | Gates: `dart analyze --fatal-infos` exit 0; full `dart test` green (baseline 925/2 + new) | FR-008 | gate | DONE | gates at branch HEAD (counts in verification.md) |

## Inner loop: unit behaviors

### `lib/src/engine/sub_agent_dispatch.dart` (new)

| id  | behavior | traces | kind | state | test |
| --- | -------- | ------ | ---- | ----- | ---- |
| U1  | `AllowlistToolDispatcher.dispatch` delegates allowlisted calls with passthrough result and `isInternalMission` preserved | FR-002 | example | DONE | `…::AllowlistToolDispatcher standalone::delegates allowlisted calls` |
| U2  | `AllowlistToolDispatcher.dispatch` refuses non-allowlisted calls: inner untouched, `success: false`, error `tool not allowed: <name>` | FR-002 | example | DONE | `…::AllowlistToolDispatcher standalone::refuses non-allowlisted calls without touching the inner dispatcher` |
| U3  | `dispatchBatch` enforces per call (mixed allow/forbidden batch → 1 delegated, 1 refused) | FR-002 | example | DONE | `…::AllowlistToolDispatcher standalone::batch enforces the allowlist per call` |
| U4  | Wall-clock budget: `spec.wallClockTimeout` + injected clock stops the child `budgetExhausted` | FR-003 | example | DONE | `…::spec wallClockTimeout caps the child mission` |
| U5  | `maxTurns` null → `fallbackMaxTurns` used (context.budgetTurns reflects it) | FR-003, FR-007 | example | DONE | A8 budgetTurns assert with default-cap spec |

## Invariants and edge cases

- Isolation invariant: NOTHING except `[system, user]` reaches the child; NOTHING except the summary leaves it (A1 is the compile-shape + runtime witness).
- Refusal invariant: a refused dispatch makes zero LLM calls and zero tool dispatches (A5).
- Bookkeeping invariant: the input `SubAgentInstance` is never mutated — the updated one is a new object (A4 asserts input unchanged).
- Terminal mapping: child `completed`/`budgetExhausted`/`providerFailed` map 1:1 onto dispatch statuses (A1/A3 + provider-failure test if budgeted — A3 suffices for the budget arm; provider arm covered by mapping code review + mutants).

## Mutation plan (deliberate, one at a time, cp-restored)

| id  | mutant | killed by |
| --- | ------ | --------- |
| M1  | Allowlist check inverted (`allowlist.contains` → `!contains`) | A2/U2 (forbidden delegates, allowed refused) |
| M2  | `totalRuns` not incremented (return input instance) | A4 |
| M3  | System-prompt message dropped from the child context | A1 (captured child messages) |
| M4  | Risk-tier gate removed (admin always runs) | A5 (LLM called / status wrong) |
| M5  | `lastRunOutcome` hardcoded `'done'` | A3/A4 (status-name assertion) |
