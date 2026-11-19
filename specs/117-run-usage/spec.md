**Template Version**: `zuraffa-1.0`

# Feature Specification: RunUsage — seam-level token accounting

**Branch**: `feat/issue-191` | **Date**: 2026-11-19

**Status**: Draft

**Input**: GitHub issue #191 — "Lean FC seam is usage-blind: map
LlmResponse.usage into UsageEntry/UsageLedger with a RunUsage accumulator".
Severity: high (area:observability, area:llm).

## Summary

The lean typed seam (`LlmClient` → `LlmResponse.usage`) returns token usage
on every response, then drops it: no function-call loop consumer can report
tokens or cost per run, because nothing maps `LlmUsage` into the ledger's
records. This spec adds `RunUsage` (`lib/src/run_usage.dart`): a fold that
accumulates `LlmResponse.usage` per turn and emits `UsageEntry` rows the
already-exported `UsageLedger` projects — so any loop can answer "what did
this run cost?" with zero per-consumer accounting code.

**Out of scope**: new session plumbing, engine-path (ChatCompletion)
accounting, budget enforcement — the issue asks for the accumulator only.

## Files

- `lib/src/run_usage.dart` — NEW: `RunUsage` (fold + totals +
  `toUsageEntries`).
- `lib/zuraffa_agent.dart` — export `src/run_usage.dart`.
- `test/run_usage_test.dart` — NEW: unit + acceptance tests.

## Functional Requirements

- **FR-001** `RunUsage.add(LlmResponse)` folds `usage.inputTokens` →
  prompt, `outputTokens` → completion, `cachedTokens` and
  `thoughtTokens` alongside; a default (all-zero) usage still counts as a
  turn.
- **FR-002** Totals are derived (`totalPromptTokens`,
  `totalCompletionTokens`, `totalCachedTokens`, `totalThoughtTokens`,
  `totalTokens` = prompt + completion, `length` = turns folded).
- **FR-003** `toUsageEntries({required String model, DateTime? at,
  String? provider})` emits one `UsageEntry` per turn (turn N → entry N),
  `UsageLedger`-loadable and JSON round-trippable via
  `UsageEntry.toJson`/`fromJson`; `at` defaults to now (UTC).
- **FR-004** The acceptance criterion: a scripted fake-brain loop (scripted
  `LlmResponse`s from `FakeLlmClient`) reports exact totals for a known
  script, with the fold doing the accounting.

## Success Criteria

- SC-001 Unit: N scripted usages fold to the expected totals.
- SC-002 Entries load into `UsageLedger` with matching aggregates and
  round-trip via JSON.
- SC-003 Acceptance: a scripted FC loop reports exact totals with no
  per-consumer fold code.