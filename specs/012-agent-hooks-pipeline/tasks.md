# Tasks: Agent Hooks Pipeline

**Branch**: `012-agent-hooks-pipeline` | **Date**: 2026-08-27 | **Plan**: [plan.md](./plan.md)

## T1 — Spec-kit artifacts

- [x] T1.1 Refine spec.md (AC-1..AC-8, typed surface, chaining/abort/deny/retry contracts, driver-scope assumption).
- [x] T1.2 plan.md + tasks.md + tdd/test-list.md (17 behaviors: U1-U12, A1-A5).

## T2 — Value layer (U1-U3)

- [x] T2.1 Red+Green: default AgentHook methods all continue (bare hook = no-op) — U1 (AC-8).
- [x] T2.2 Red+Green: typed result classes carry actions + payloads — U2 (FR-003).
- [x] T2.3 Red+Green: HookAbortError is a typed error carrying hookName + reason — U3 (FR-004).
- [x] T2.4 Commit.

## T3 — Pipeline chaining (U4-U6)

- [x] T3.1 Red+Green: hooks called in registration order at every point — U4 (FR-002, AC-4).
- [x] T3.2 Red+Green: modify folds — hook B sees hook A's modification — U5 (AC-6).
- [x] T3.3 Red+Green: abort throws HookAbortError immediately, later hooks skipped — U6 (AC-5, SC-003).
- [x] T3.4 Mutation check: fold drops the modify (kill); abort continues instead of throwing (kill).
- [x] T3.5 Commits.

## T4 — Engine-visible modifications (U7-U12)

- [x] T4.1 Red+Green: beforeModelCall modification returns the modified request — U7 (AC-2, SC-002).
- [x] T4.2 Red+Green: beforeToolCall deny → ToolCallDecision with synthetic result — U8 (AC-3).
- [x] T4.3 Red+Green: beforeToolCall modify arguments → modified LlmToolCall — U9 (FR-005).
- [x] T4.4 Red+Green: afterToolCall modify result → modified content — U10 (FR-005).
- [x] T4.5 Red+Green: afterModelCall retry → ModelCallDecision.retry — U11 (AC-7).
- [x] T4.6 Red+Green: afterModelCall modify response — U12 (FR-005).
- [x] T4.7 Mutation check: deny branch dropped (kill); retry flag inverted (kill).
- [x] T4.8 Commits.

## T5 — Acceptance via scripted mission driver (A1-A5)

- [x] T5.1 A1: logging hook captures all 9 lifecycle events in order — SC-001, AC-1.
- [x] T5.2 A2: modifier hook changes model call params; the driver's LlmClient receives them — SC-002.
- [x] T5.3 A3: abort hook stops the run with the typed error — SC-003.
- [x] T5.4 A4: logging + modifying hooks compose in registration order — US2 independent test.
- [x] T5.5 A5: deny hook → tool not executed, synthetic result returned — US3 independent test.
- [x] T5.6 Commits.

## T6 — Gates + verification + delivery

- [x] T6.1 `dart analyze` — 111 baseline, zero in feature files.
- [x] T6.2 `dart test` — +486/-6 baseline preserved, all feature tests green.
- [x] T6.3 tdd/cycle-log.md + tdd/verification.md.
- [x] T6.4 Commit artifacts, push, open PR → master (stacked above #64).
