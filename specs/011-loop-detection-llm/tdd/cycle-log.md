# TDD Cycle Log: Loop Detection (LLM-based)

---
feature: 011-loop-detection-llm
profile: .specify/memory/tdd-profile.md
started_at: 725312f (branch point on 010-episodic-memory)
---

## Cycle 1 — U1-U3 value layer

- **Red**: compile errors — `loop_detector.dart` does not exist (11 errors:
  LoopDetectorConfig/LoopDetectorResult/toolCallSignature undefined).
- **Green**: config defaults (5/30/5/0.8/20), result value semantics with
  diagnosisError field, key-order-insensitive + id-insensitive signature
  (sorted-key jsonEncode of arguments).
- **Commit**: d98320e.

## Cycles 2-4 — U4-U11 + A1-A6 DefaultLoopDetector

- **Red**: compile errors — `default_loop_detector.dart` does not exist.
  One fixture fix pre-green: `ToolResultMessage.result` → `.content`
  (wrong field name in the test).
- **First green run: +11 -3.** The three failures decomposed honestly:
  - **U6 — TEST BUG** (streak arithmetic: 4 calls vs threshold 5) —
    repaired the test to 5 calls.
  - **U9 + U11 — GENUINE IMPLEMENTATION BUG**: the first diagnosis
    condition required `_turns - 0 >= llmCheckInterval`, so with
    llmCheckAfterTurns=3 < interval=5 the first check never fired at turn
    3. Fixed: the FIRST check fires at exactly llmCheckAfterTurns; the
    interval only governs checks after the first. This is the TDD process
    catching a real boundary bug — the test stays as the regression pin.
- **Green**: +14 (after U6 repair); detector + value layer together +17.
- **Mutations** (all restored + re-verified green after each):
  - M1 streak never resets → +12 -2 KILLED (U5, A2).
  - M2 key-order-sensitive signature (raw jsonEncode) → +2 -1 KILLED (U3).
  - M3 threshold `>=` → `>` → +13 -1 KILLED (U10 boundary at exactly 0.8).
  - M4 non-object JSON treated as stagnant → **SURVIVED** first run:
    the mutant targeted the `is! Map` branch which U11's malformed-string
    case never reached (it hits FormatException instead). U11 strengthened
    with three malformed shapes (not-JSON / JSON-array / wrong-typed
    fields); re-applied mutant → +13 -1 KILLED.
- **Commits**: (feature commit), 913e796 (style: unused ctor param).

## Final gates

- `dart analyze`: 111 issues — exactly the pre-existing baseline; zero in
  spec-011 files (the one new warning during the cycle — an unused
  constructor parameter — was fixed before delivery).
- `dart test`: +486 passed / 6 failed — 6 = pre-existing baseline loading
  failures; **+17 new passing** vs the spec-010 baseline (+469), zero new
  failures.
- Purity: no `dart:io` in the new files (constitution VII) — verified by
  grep before commit.
