# Feature Specification: Sub-agent dispatch runtime

**Branch**: `feat/spec-070-sub-agent-dispatch` (stacked on `feat/spec-069-mission-runner`, PR #80) | **Date**: 2026-08-29

## Summary

Give the declarative sub-agent layer its runtime. GAP-ANALYSIS row 5:
dart_agent_core has "Full (clone + named)" sub-agent delegation; this repo
has "Entity stubs only — Runtime missing". The data model is complete —
`SubAgentSpec` (spec 036), `SubAgentInstance` (spec 056), `SubAgentContext`
(spec 055), `DispatchTool` (spec 058) — but nothing spawns or executes a
sub-agent. Spec 005 US1 (still Draft) describes the target: a parent
dispatches a sub-agent that "runs in its own context window with its own
tool allowlist and budget; their internal chatter never pollutes my
context — only their results return (Kimi LaborMarket pattern)."

This spec delivers exactly that, composed on the spec 069 `MissionRunner`:
`SubAgentDispatchService.dispatch()` runs the child as a full mission in an
ISOLATED context (system prompt + mission only), enforces the spec's tool
allowlist at the dispatch boundary via a new `AllowlistToolDispatcher`
decorator, honors the spec's budgets, performs `SubAgentInstance`
bookkeeping, and returns a result object that carries the child's summary
but NEVER its transcript.

## Files

- `lib/src/engine/sub_agent_dispatch.dart` — NEW: `AllowlistToolDispatcher`
  (decorator over `ToolDispatcher`), `SubAgentDispatchStatus` enum,
  `SubAgentDispatchResult` value object (house pattern),
  `SubAgentDispatchService`.
- `test/engine/sub_agent_dispatch_test.dart` — NEW: fakes + the spec-070
  suite.
- `specs/070-sub-agent-dispatch-runtime/{spec,plan,tasks}.md` + `tdd/{test-list,verification}.md`.

## FRs

- **FR-001** — Isolated child context: `dispatch(spec, mission, instance)`
  constructs the child transcript as EXACTLY
  `[ChatMessage(role: 'system', content: spec.systemPrompt),
  ChatMessage(role: 'user', content: mission)]` — nothing from any parent
  context is visible to the child. The returned `SubAgentDispatchResult`
  carries the child's `resultSummary` (final assistant content on natural
  completion, else null) and NEVER the child transcript (the Kimi
  LaborMarket pattern — results, not chatter).
- **FR-002** — Tool allowlist enforcement: the child's tool dispatch is
  wrapped in `AllowlistToolDispatcher(inner, allowlist: spec.tools)`. A call
  whose `toolName` is NOT in the allowlist is refused at the boundary — the
  inner dispatcher never sees it — and yields
  `ToolDispatchResult(success: false, error: 'tool not allowed: <name>')`,
  so the child's `ToolCallCompleted` reports `ok: false` and the mission
  continues. Allowlisted calls delegate to the inner dispatcher with
  passthrough results. `dispatchBatch` enforces per-call;
  `validateSchema`/`checkRiskTier` delegate unchanged.
- **FR-003** — Budgets: the child `EngineLoop`/`StopPolicy` pair is built
  from the spec — `maxTurns: spec.maxTurns ?? fallbackMaxTurns` (service
  constructor, default 10) and `wallClockTimeout: spec.wallClockTimeout ??
  Duration.zero` — and the child `MissionRunner` enforces them. Terminal
  child statuses map onto the dispatch result.
- **FR-004** — Instance bookkeeping: a completed dispatch (any run status)
  returns `result.instance` as a NEW `SubAgentInstance` with
  `totalRuns + 1` and `lastRunOutcome` set to the dispatch status name. The
  input instance is never mutated.
- **FR-005** — Risk tier gate: when `spec.riskTier == RiskTier.admin` and
  the caller did not pass `adminGranted: true`, the dispatch is refused
  BEFORE any LLM call: status `refusedRiskTier`, `resultSummary` null,
  LLM call count 0, and the instance returned UNCHANGED (a refused dispatch
  is not a run). `safe`/`confirm` tiers never refuse on this gate (confirm
  flows through the tool-level approval callback — out of scope).
- **FR-006** — Event forwarding: the child mission's `EngineEvent`s flow to
  the caller's optional `onEvent` sink; the child mission id is
  `instance.id` (so `MissionStarted`/`MissionCompleted` correlate with the
  resumable instance).
- **FR-007** — `SubAgentDispatchResult` is a house-pattern value object
  (`==`/`hashCode`/`toString` over all fields) carrying `instanceId`,
  `specName`, `status`, `resultSummary`, `instance`, and `context` — a
  `SubAgentContext` snapshot (`subAgentSpecId: spec.name`,
  `sessionId: instance.id`, `toolAllowlist: spec.tools`, `budgetTurns` =
  the effective turn cap) that documents the isolation envelope.
- **FR-008** — Gates: `dart analyze --fatal-infos` clean; `dart test` green
  (baseline 925/2 at 069-branch HEAD + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- YAML spec loading and `extends` inheritance resolution (spec 057 surface
  exists; the loader is future work).
- The `dispatch()` built-in TOOL the model calls with
  `subAgentType`/`mission` arguments (spec 058 declared the VO; wiring it
  into a real tool-call parser needs `ChatCompletion` tool-call fields).
- Sub-agent-of-sub-agent recursion and the `spec.subAgents` allowlist
  enforcement (needs the dispatch tool above).
- Resuming a persisted instance across engine restarts (spec 005 US2 —
  persistence layer concern).
- Per-sub-agent LLM client resolution (one injected client for now).
