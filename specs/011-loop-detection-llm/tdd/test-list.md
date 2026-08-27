# Test List: Loop Detection (LLM-based)

---
feature: 011-loop-detection-llm
loop: outside-in
profile: .specify/memory/tdd-profile.md
spec_criteria: 6 # acceptance criteria AC-1..AC-6 in spec.md
planned_at: 725312f
updated_at: 725312f
suite_baseline: red # 6 pre-existing loading failures (unrelated features); green criterion = feature tests pass AND failure delta vs the spec-010 baseline (6 loading failures) is zero new
---

## Outer loop: acceptance behaviors

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| A1  | 5 identical read_file("lib/a.dart") calls in a row are detected as a loop at the 5th call | AC-1, SC-001 | example | DONE | `default_loop_detector_test.dart::A1` |
| A2  | 50 varied tool calls (different names/args) never fire a tool-loop detection | AC-2, SC-003 | example | DONE | `default_loop_detector_test.dart::A2` |
| A3  | A call→result→call→result chain of identical calls accumulates and fires at the threshold | AC-3 | example | DONE | `default_loop_detector_test.dart::A3` |
| A4  | With llmCheckAfterTurns=30 the first diagnosis fires exactly at turn 30 (one LLM call), not at 29 | AC-4, FR-003 | example | DONE | `default_loop_detector_test.dart::A4` |
| A5  | A stagnation verdict at confidence 0.9 (threshold 0.8) produces a stop-signal result carrying the LLM's confidence and reason | AC-5, SC-002 | example | DONE | `default_loop_detector_test.dart::A5` |
| A6  | A 60-turn non-stagnant mission (healthy diagnoses) yields zero detections | AC-6, SC-003 | example | DONE | `default_loop_detector_test.dart::A6` |

## Inner loop: unit behaviors

### `lib/src/llm/loop_detector.dart`

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U1  | LoopDetectorConfig defaults: toolLoopThreshold=5, llmCheckAfterTurns=30, llmCheckInterval=5, stagnationThreshold=0.8, diagnosisWindowMessages=20 | FR-005, FR-004 | example | DONE | `loop_detector_test.dart::U1` |
| U2  | LoopDetectorResult carries isLoop/reason/confidence/turnNumber with value semantics | Key Entities | example | DONE | `loop_detector_test.dart::U2` |
| U3  | toolCallSignature is key-order-insensitive (same args in any order → same signature) and call-id-insensitive | FR-001 | example | DONE | `loop_detector_test.dart::U3` |

### `lib/src/llm/default_loop_detector.dart` — tool-loop path

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U4  | The streak fires exactly at toolLoopThreshold consecutive identical signatures — not before (4 identical calls → no detection) | FR-001, AC-1 | boundary | DONE | `default_loop_detector_test.dart::U4` |
| U5  | A different tool-call signature resets the streak (5×A, 1×B, 4×A → still no loop; the 5th consecutive A fires) | FR-001, AC-2 | example | DONE | `default_loop_detector_test.dart::U5` |
| U6  | ToolResult/user messages between identical calls do not reset the streak | AC-3 | example | DONE | `default_loop_detector_test.dart::U6` |

### `lib/src/llm/default_loop_detector.dart` — stagnation path

| id  | behavior | traces | kind    | state   | test |
| --- | -------- | ------ | ------- | ------- | ---- |
| U7  | Without an LlmClient the detector runs the pure heuristic path: many turns, zero diagnosis calls, tool-loop detection still works | FR-002 | example | DONE | `default_loop_detector_test.dart::U7` |
| U8  | The first diagnosis fires at exactly llmCheckAfterTurns assistant turns and then every llmCheckInterval turns | FR-003, AC-4 | example | DONE | `default_loop_detector_test.dart::U8` |
| U9  | An isStagnant verdict with confidence >= stagnationThreshold produces a detection carrying the verdict's confidence and reason | FR-002, FR-004, AC-5 | example | DONE | `default_loop_detector_test.dart::U9` |
| U10 | A verdict with confidence below the threshold produces no detection (mission continues) | FR-004, AC-6 | boundary | DONE | `default_loop_detector_test.dart::U10` |
| U11 | A malformed (non-JSON) diagnosis response is fail-open: no detection, error surfaced on the result | Assumptions | example | DONE | `default_loop_detector_test.dart::U11` |

## Mutation targets (deliberate-mutant sampling)

| target | mutant | killed by |
| ------ | ------ | --------- |
| streak reset branch | never reset (different signature ignored) | U5 (expects reset semantics) |
| signature normalization | raw jsonEncode (key-order-sensitive) | U3 (same args reordered → equal signatures) |
| confidence comparison | `>=` → `>` | U10 + boundary verdict at exactly 0.8 |
| verdict parse | treat unparseable as stagnant | U11 (fail-open contract) |
