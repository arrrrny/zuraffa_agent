# Implementation Plan: Loop Detection (LLM-based)

**Branch**: `011-loop-detection-llm` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-loop-detection-llm/spec.md`

## Summary

A `LoopDetector` with two independent detection paths: (1) tool-call loop detection — a streak counter over tool-call signatures (name + key-order-normalized arguments, call-id-insensitive), resetting only on a *different* signature, firing at `toolLoopThreshold` consecutive repeats; (2) LLM-based cognitive-stagnation diagnosis — after `llmCheckAfterTurns` assistant turns, and every `llmCheckInterval` turns thereafter, the recent window of history is sent to an LlmClient (spec 007 contract) with a JSON-verdict prompt; a parsed `isStagnant` verdict with confidence >= `stagnationThreshold` fires the detection. Malformed diagnosis output is fail-open.

## Technical Context

**Language/Version**: Dart 3.13.2 (stable), SDK constraint `^3.11.0`.

**Primary Dependencies**: `AgentMessage`/`AssistantMessage`/`ToolCallBlock` from `lib/src/types.dart`; `LlmClient`/`LlmRequest`/`LlmResponse` from `lib/src/llm/llm_client.dart` (spec 007); `dart:convert` for signature normalization and verdict parsing.

**Storage**: none — the detector is a stateful in-memory observer (streak counter, turn counter, last-check turn, detection latch).

**Testing**: `dart test` with the existing `FakeLlmClient` (outcome-scripting, spec 008) for diagnosis calls. Suite baseline at branch point: +469 passed / 6 unrelated pre-existing loading failures; 111 pre-existing analyzer issues.

**Constraints**: constitution VII (no `dart:io`), VIII (attribution headers), X (analyze pristine on new files). One-behavior-per-red discipline (spec-007 remediation T046).

**Scale/Scope**: 2 new lib files (~90 + ~160 lines), 2 new test files (~200 + ~260 lines). No changes to existing files.

## Constitution Check

- VII: new files import only `types.dart`, `llm_client.dart`, `dart:convert`. ✓
- VIII: loop-detection concept ported from dart_agent_core — attribution headers retained. ✓
- X: zero analyzer issues in new files; full-suite failure delta must stay zero. ✓

## Project Structure

```text
lib/src/llm/
├── loop_detector.dart           # NEW: LoopDetectorConfig, LoopDetectorResult,
│                                #      LoopDetector interface, toolCallSignature()
└── default_loop_detector.dart   # NEW: DefaultLoopDetector (streaks + diagnosis)

test/llm/
├── loop_detector_test.dart      # NEW: config defaults + result + signature normalization (U1-U3)
└── default_loop_detector_test.dart  # NEW: streaks, thresholds, diagnosis, false positives (U4-U11, A1-A6)

specs/011-loop-detection-llm/
├── spec.md, plan.md, tasks.md
└── tdd/{test-list.md, cycle-log.md, verification.md}
```

## Realistic Boundaries / De-scoping

- Engine-loop integration (who calls observe(), what happens on detection — stop, emit LoopDetected safety rail) is spec 002's integration point; here the detector reports, it does not stop anything.
- The `repetition_tracker` entity (issue #25) is the *datasource-layer* sibling; this runtime detector does not depend on it.
- No wall-clock: diagnosis cadence is turn-count based (injectable clock would be spec 008's LlmClock pattern, unnecessary here).

## Verification

- Per-behavior red→green cycles committed individually; mutation checks on the streak-reset branch, the signature normalization, and the confidence threshold comparison.
- Gates: analyze 111 (baseline) + feature files zero; test failure delta zero vs +469/-6.
