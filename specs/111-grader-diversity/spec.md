**Template Version**: `zuraffa-1.0`

# Feature Specification: Grader diversity — exact-match, regex, json-path, llm-judge

**Branch**: `111-grader-diversity` | **Date**: 2026-09-09

**Status**: Draft

**Input**: GitHub issue #125 — "Add grader diversity: exact-match, regex,
json-path, llm-judge graders". Severity: high (eval). Epic: R6 (issue #7).

## Summary

The only eval graders historically referenced in this repo were UI-tree
graders that no longer exist on master — golden missions with
`graderBindings` have nothing to bind to for non-UI missions. This spec
ships a common `Grader` interface and four concrete graders — exact-match,
regex, json-path, and llm-judge — plus a registry that resolves graders by
id (the binding point golden missions use). Each grader returns the same
typed verdict (passed, score, reason); each has positive and negative
fixture tests; the registry's bind-by-id contract is documented.

**Out of scope**: the golden-mission corpus itself (issue-tracked
separately), CI eval gating, schema/snapshot UI graders (a future grader
family can register alongside these), new dependencies (the json-path
grader implements a documented subset: root `$`, dot property access, and
integer array indices — e.g. `$.steps[2].status`).

## Files

- `lib/src/eval/graders/grader.dart` — NEW: `Grader` interface +
  `GraderResult` value object (passed, score, reason).
- `lib/src/eval/graders/exact_match_grader.dart` — NEW.
- `lib/src/eval/graders/regex_grader.dart` — NEW.
- `lib/src/eval/graders/json_path_grader.dart` — NEW (documented JSONPath
  subset; pure `dart:convert`).
- `lib/src/eval/graders/llm_judge_grader.dart` — NEW: judge prompt + output
  through an injected completion seam; parses a strict
  `PASS|FAIL — reason` response.
- `lib/src/eval/graders/grader_registry.dart` — NEW: bind-by-id registry.
- `test/eval/graders/graders_test.dart` — NEW: positive + negative fixtures
  per grader, registry binding, composed multi-grader acceptance.
- `specs/111-grader-diversity/` — this artifact set.

## User scenarios

### US1 — Deterministic graders pin exact behavior (P1)

As an eval author, I pin a mission's expected output exactly (string
equality), or by pattern (regex), and the verdict is deterministic.

**Acceptance**: exact-match passes on equality and fails on difference,
reporting expected/actual in the reason; regex passes when the pattern
matches the output and fails when it does not, naming the pattern in the
reason.
**Acceptance Scenarios**:

1. **Given** the exact-match and regex graders with fixed outputs, **When** they grade, **Then** exact-match passes on equality (trim honored) and fails otherwise reporting expected/actual in the reason, and regex passes on match and fails naming the pattern in the reason.
### US2 — Structured outputs are graded by path (P1)

As an eval author, I assert on a specific field deep inside a JSON payload
without string-matching the whole blob.

**Acceptance**: a json-path grader evaluates a documented-subset expression
against the decoded payload and compares the resolved value to an expected
value; a missing path or mismatched value fails with a reason naming the
path; a malformed payload fails without throwing.

**Acceptance Scenarios**:

2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing.

As an eval author, for outputs where no deterministic rule exists, an
LLM judge grades correctness: the judge prompt and the mission output go to
the injected completion seam, and the verdict is parsed from a strict
`PASS`/`FAIL` response with a reason; an unparsable judge response fails
with the response preserved in the reason.

**Acceptance**: a `PASS`-prefixed completion yields a passing verdict; a
`FAIL`-prefixed one a failing verdict with its reason; a garbage completion
yields a failing verdict whose reason quotes the response.

**Acceptance Scenarios**:

2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing.

As the harness, grader bindings are ids; the registry resolves each id to
its grader instance, and a mission's bindings can be evaluated in bulk.

**Acceptance**: the registry registers and resolves graders by id; an
unknown id fails with a typed error naming the id; evaluating a set of
bindings returns one verdict per binding.
## Requirements

**Acceptance Scenarios**:

2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing.
### Functional requirements

- **FR-001**: a common `Grader` interface — `id`, `grade(output)` — with a
  single typed `GraderResult` (passed, score?, reason) across all graders.
  traces: Grade.fr1
- **FR-002**: `ExactMatchGrader(expected)` — equality after optional
  trim; reason carries expected and actual on failure.
  traces: Grade.fr2
- **FR-003**: `RegexGrader(pattern)` — `hasMatch` against the output;
  reason names the pattern on failure.
  traces: Grade.fr3
- **FR-004**: `JsonPathGrader(path, expected)` — resolves the
  documented subset against a JSON string payload; missing path / type
  mismatch / malformed JSON all fail with reasons, never throw.
  traces: Grade.fr4
- **FR-005**: `LlmJudgeGrader(judgePrompt, complete)` — sends a judge
  message containing the prompt and the output; parses a strict verdict
  (`PASS`/`FAIL` prefix + reason); unparsable responses fail with the raw
  response preserved.
  traces: Grade.fr5
- **FR-006**: `GraderRegistry` — register, resolve by id (typed error
  for unknown ids), and evaluate a map of id → output in bulk.
  traces: Grade.fr6

## Success criteria

- **SC-001** (US1 / FR-002): exact-match positive + negative fixtures.
- **SC-002** (US1 / FR-003): regex positive + negative fixtures.
- **SC-003** (US2 / FR-004): json-path positive, missing-path, and
  malformed-payload fixtures.
- **SC-004** (US3 / FR-005): llm-judge PASS, FAIL, and unparsable fixtures
  (scripted completion seam — no network).
- **SC-005** (US4 / FR-006): registry binding positive + unknown-id
  negative; the composed multi-grader acceptance evaluates all four grader
  families through the registry.
- **SC-006**: `dart analyze` pristine; suite green; purity gate unchanged.

## Assumptions

- The mission "output" a grader sees is the final response string; the
  json-path grader's payload is that string when it is valid JSON.
- Judge determinism comes from the injected completion seam (scripted in
  tests; real providers in evals).
- The deprecated `GraderSealed` value object stays untouched (it is
  recorded contract data, not logic).

## Dependencies

- Builds on: master (post-#146) — `ChatCompletion`/`ChatMessage` value
  objects, `ToolCall` planner seam precedents.
- Pairs with (out of scope): golden-mission corpus + release gating
  (separate issue).

## Layer Contracts

**Domain**:

- `Grade`: `fr1(...) -> Result`, `fr2(...) -> Result`, `fr3(...) -> Result`, `fr4(...) -> Result`, `fr5(...) -> Result`, `fr6(...) -> Result`

