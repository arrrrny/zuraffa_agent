# Feature Specification: Memory tools — the agent-facing surface

**Branch**: `feat/spec-074-memory-tools` (stacked on `feat/spec-073-agent-memory`, PR #84) | **Date**: 2026-08-29

## Summary

Spec 073 built the three-layer memory system as a Dart API. An agent
cannot call a Dart API — it calls TOOLS. This spec gives the memory
system its agent-facing surface:

- **`MemoryTools.declarations`** — three `AgentTool` declarations
  (`memory_remember`, `memory_recall`, `memory_link`) following the
  house tool model (R3.1/R3.2): typed params schemas, `RiskTier.safe`
  (memory writes are not destructive — the layers are append-oriented
  value stores), `ExecutionMode.sequential`.
- **`MemoryToolDispatcher`** — implements the `ToolDispatcher` contract
  (the same interface the sub-agent dispatch runtime consumes): bridges
  tool calls to the `AgentMemorySystem`. Model-shaped failures (empty
  content, unknown link type, unknown endpoints, unknown tool) come
  back as `ToolDispatchResult(success: false, error: ...)` — the LLM
  sees the reason and can correct itself — instead of exceptions, which
  are for programmer errors.
- **`MemoryPromptProjection`** — renders the system-prompt digest of
  what the agent remembers: top long-term memories by salience
  (optionally plus the current session's notes), as prompt-ready lines.

The dispatcher can serve as the inner dispatcher of an allowlist
dispatcher (spec 070's composition) — memory tools compose with the
sub-agent and swarm stacks.

## Files

- `lib/src/engine/memory_tools.dart` — NEW: `MemoryTools`,
  `MemoryToolDispatcher`, `MemoryPromptProjection`.
- `test/engine/memory_tools_test.dart` — NEW.
- `specs/074-memory-tools/{spec,plan,tasks}.md` +
  `tdd/{test-list,verification}.md`.

## FRs

- **FR-001** — Declarations: `memory_remember` (params: `content`
  required string, `tags` optional string array, `salience` optional
  number, `session_id` optional string), `memory_recall` (`query`
  required string, `limit` optional number), `memory_link` (`from_id`,
  `to_id`, `type` required; `note` optional). Each is an `AgentTool`
  with `RiskTier.safe`, `ExecutionMode.sequential`, a `paramsSchema`
  declaring `required` arrays, and a description that tells the model
  WHEN to use it. `MemoryTools.declarations` returns all three
  (unmodifiable).

- **FR-002** — `memory_remember` dispatch: builds a `MemoryRecord`
  (auto id `mem-<n>` from a per-dispatcher counter when `id` is not
  supplied — explicit `id` also accepted), `MemorySource(sessionId:
  session_id or agentName: 'memory-tool')`, salience clamped to
  0.0..1.0, default 0.5, and writes through `AgentMemorySystem.remember`
  (long-term when no `session_id`, session memory otherwise). Success
  result carries the stored id.

- **FR-003** — Model-shaped failures return `ToolDispatchResult(success:
  false, result: '', error: <reason>, artifactRefs: [])`: missing or
  non-string `content`, whitespace-only content, out-of-range salience,
  unknown tool name. NO exception escapes `dispatch` for argument-shaped
  problems — the agent gets the error text and can retry.

- **FR-004** — `memory_recall` dispatch: returns success with one line
  per hit, `"<layer> | <id> | salience <s> | <content>"`, in the
  system's ranking order, capped by `limit`. Empty/missing query is a
  failure result (not a match-all).

- **FR-005** — `memory_link` dispatch: validates `type` against
  `MemoryLinkType` names (unknown → failure result), then delegates to
  `AgentMemorySystem.link`. Endpoint validation comes from the system
  (unknown ids → failure result carrying the ArgumentError message);
  self-links likewise. Happy path returns success naming the link.

- **FR-006** — `dispatchBatch` dispatches every call sequentially and
  returns one result per call, in order.

- **FR-007** — `validateSchema` checks the required keys per tool
  (`content` for remember, `query` for recall, `from_id`/`to_id`/`type`
  for link) and returns the violation strings (empty list = valid);
  `checkRiskTier` is always true (all memory tools are safe-tier).

- **FR-008** — `MemoryPromptProjection.render({int limit = 10})`: the
  top [limit] long-term memories by salience (desc, createdAt desc) as
  prompt lines `"- [id] content"`, highest salience first.
  `renderWithSession(sessionId, {int limit = 10})` prepends the
  session's notes (insertion order, capped by limit) marked
  `"[session] "`. Empty memory renders an empty list — the caller
  omits the section entirely.

- **FR-009** — Gates: `dart analyze --fatal-infos` clean; `dart test`
  green (baseline 925/2 at `4dd76e2` + new tests).

## Verification

- `dart pub get` clean
- `dart analyze --fatal-infos` — No issues
- `dart test` — baseline + new tests pass, 0 new failures

## Out of scope

- Wiring the tools into a live tool registry / LLM turn (the
  MissionRunner stack, PRs #80-#83, owns that when it merges).
- Memory-formation policy (when the agent SHOULD remember — a distiller
  concern).
- Embedding-based recall (keyword + salience only, per 073).
- Any new `EngineEvent` subtype (the union grows only from its own
  spec).
