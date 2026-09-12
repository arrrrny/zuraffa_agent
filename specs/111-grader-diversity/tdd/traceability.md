# Traceability: 111-grader-diversity

Coverage proof for `zfa tdd plan` (bug #846): every FR/AC requirement statement maps to a behavior row or an explicit manual declaration. Verify re-checks the hash — a spec edited after plan is drift (exit 3, re-plan required).

<!-- tdd:traceability
spec-hash: sha256:bdb7075e50bf113daf92bc685ceaa9eb58a3f6f83ab4cd61fefb4d42ed4aadb9
statements: 10
automated: 10
manual: 0
open-gaps: 0
-->

| requirement | line | statement | behavior | status |
| --- | --- | --- | --- | --- |
| AC-1 | 58 | 1. **Given** the exact-match and regex graders with fixed outputs, **When** they grade, **Then** exact-match passes on equality (trim honored) and fails otherwise reporting expected/actual in the reason, and regex passes on match and fails naming the pattern in the reason. | A1 | automated |
| AC-2 | 71 | 2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing. | A2 | automated |
| AC-3 | 85 | 2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing. | A3 | automated |
| AC-4 | 97 | 2. **Given** a json-path grader and a JSON payload, **When** a documented-subset expression is evaluated, **Then** a matching path yields a passing verdict on value equality, and a missing path, mismatched value, or malformed JSON each fail with a reason naming the problem — never throwing. | A4 | automated |
| FR-001 | 100 | - **FR-001**: a common `Grader` interface — `id`, `grade(output)` — with a | U1 | automated |
| FR-002 | 103 | - **FR-002**: `ExactMatchGrader(expected)` — equality after optional | U1 | automated |
| FR-003 | 106 | - **FR-003**: `RegexGrader(pattern)` — `hasMatch` against the output; | U2 | automated |
| FR-004 | 109 | - **FR-004**: `JsonPathGrader(path, expected)` — resolves the | U4 | automated |
| FR-005 | 113 | - **FR-005**: `LlmJudgeGrader(judgePrompt, complete)` — sends a judge | U7 | automated |
| FR-006 | 118 | - **FR-006**: `GraderRegistry` — register, resolve by id (typed error | U9 | automated |

