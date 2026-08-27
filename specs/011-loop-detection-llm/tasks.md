# Tasks: Loop Detection (LLM-based)

**Branch**: `011-loop-detection-llm` | **Date**: 2026-08-27 | **Plan**: [plan.md](./plan.md)

## T1 — Spec-kit artifacts

- [x] T1.1 Refine spec.md (AC-1..AC-6, signature/streak/diagnosis contracts, fail-open rule).
- [x] T1.2 plan.md + tasks.md.
- [x] T1.3 tdd/test-list.md (17 behaviors: U1-U11, A1-A6).

## T2 — Value layer (U1-U3)

- [x] T2.1 Red+Green: LoopDetectorConfig defaults (5/30/5/0.8/20) — U1.
- [x] T2.2 Red+Green: LoopDetectorResult value semantics — U2.
- [x] T2.3 Red+Green: toolCallSignature normalization (key-order-insensitive, id-insensitive) — U3.
- [x] T2.4 Commit.

## T3 — Tool-loop streak detection (U4-U6)

- [x] T3.1 Red: 5 identical calls → detection at the 5th, not before — U4 (SC-001, AC-1).
- [x] T3.2 Green: streak counter in DefaultLoopDetector.
- [x] T3.3 Red: different signature resets the streak — U5 (AC-2).
- [x] T3.4 Green: reset branch.
- [x] T3.5 Red+Green: interleaved tool-result/user messages do not reset — U6 (AC-3).
- [x] T3.6 Mutation check: streak never resets (kill) + reset on any message (kill).
- [x] T3.7 Commits.

## T4 — Stagnation diagnosis (U7-U10)

- [x] T4.1 Red: no LlmClient → pure heuristic path, zero diagnosis calls across many turns — U7.
- [x] T4.2 Green: client-optional construction.
- [x] T4.3 Red: first diagnosis fires exactly at llmCheckAfterTurns assistant turns — U8 (AC-4).
- [x] T4.4 Green: turn counter + boundary check.
- [x] T4.5 Red: stagnation verdict above threshold → detection with LLM confidence + reason — U9 (AC-5, SC-002).
- [x] T4.6 Green: verdict parsing.
- [x] T4.7 Red: verdict below threshold → no detection, mission continues — U10 (AC-6).
- [x] T4.8 Green: threshold comparison.
- [x] T4.9 Red+Green: malformed LLM output → fail-open, no detection, error surfaced — U11.
- [x] T4.10 Mutation check: threshold `>=` → `>` (kill); verdict-parse drop (kill).
- [x] T4.11 Commits.

## T5 — Acceptance behaviors (A1-A6)

- [x] T5.1 A1: 5 identical read_file calls → loop (SC-001).
- [x] T5.2 A2: varied calls reset streaks — no false loop.
- [x] T5.3 A3: call→result→call chains accumulate (AC-3).
- [x] T5.4 A4: diagnosis triggers exactly at turn 30 (AC-4).
- [x] T5.5 A5: stagnation confidence 0.9 > 0.8 → stop signal (SC-002).
- [x] T5.6 A6: false-positive sweep — 50 varied tool calls + 60 non-stagnant turns → zero detections (SC-003).
- [x] T5.7 Commits.

## T6 — Gates + verification + delivery

- [x] T6.1 `dart analyze` — 111 baseline, zero in feature files.
- [x] T6.2 `dart test` — +469/-6 baseline preserved, all feature tests green.
- [x] T6.3 tdd/cycle-log.md + tdd/verification.md.
- [x] T6.4 Commit artifacts, push, open PR → master (stacked above #62).
